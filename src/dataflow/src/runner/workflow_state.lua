local sql = require("sql")
local json = require("json")
local uuid = require("uuid")
local time = require("time")
local commit = require("commit")
local dataflow_repo = require("dataflow_repo")
local data_reader = require("data_reader")
local consts = require("consts")

---@class NodeData
---@field status string Node status
---@field type string Node type identifier
---@field parent_node_id string|nil Parent node ID
---@field metadata table|nil Additional node metadata
---@field config table|nil Node configuration

---@class YieldInfo
---@field yield_id string Unique yield identifier
---@field reply_to string Topic to reply to when yield is satisfied
---@field pending_children table<string, string> Map of child_id -> status
---@field results table<string, any> Map of child_id -> result data
---@field child_path table List of ancestor node IDs for child nodes

---@class InputRequirements
---@field required table List of required input keys
---@field optional table List of optional input keys

---@class InputTracker
---@field requirements table<string, InputRequirements> Map of node_id -> input requirements
---@field available table<string, table<string, boolean>> Map of node_id -> available inputs by key

---@class WorkflowState
---@field dataflow_id string The ID of the dataflow
---@field options table Optional parameters
---@field nodes table<string, NodeData> Map of node_id -> node data
---@field dataflow_metadata table Dataflow metadata
---@field loaded boolean Whether state has been loaded from database
---@field active_processes table<string, string> Map of node_id -> pid
---@field active_yields table<string, YieldInfo> Map of parent_id -> yield info
---@field input_tracker InputTracker Input requirements and availability tracking
---@field has_workflow_output boolean Whether workflow output has been generated
---@field queued_commands table Command queuing for batch operations

local workflow_state = {}
local methods = {}
local workflow_state_mt = { __index = methods }

---Helper function to get database connection
---@return table|nil db Database connection
---@return string|nil error Error message if failed
local function get_db()
    local db, err = sql.get(consts.APP_DB)
    if err then
        return nil, "Failed to connect to database: " .. err
    end
    return db
end

---Create a new workflow state instance
---@param dataflow_id string The ID of the dataflow
---@param options table|nil Optional parameters
---@return WorkflowState|nil instance Workflow state instance
---@return string|nil error Error message if failed
function workflow_state.new(dataflow_id, options)
    if not dataflow_id or dataflow_id == "" then
        return nil, "Dataflow ID is required"
    end

    local instance = {
        dataflow_id = dataflow_id,
        options = options or {},

        -- Persistent state
        nodes = {},
        dataflow_metadata = {},
        loaded = false,

        -- Runtime state
        active_processes = {}, -- node_id -> pid
        active_yields = {},    -- parent_id -> yield_info

        -- Input tracking
        input_tracker = {
            requirements = {}, -- node_id -> { required = {}, optional = {} }
            available = {}     -- node_id -> { key -> true }
        },

        -- State flags
        has_workflow_output = false,

        -- Command queuing
        queued_commands = {}
    }

    return setmetatable(instance, workflow_state_mt), nil
end

---Parse node config and set input requirements if defined
---@param node_id string Node ID
---@param config table|nil Node configuration
---@private
function methods:_set_input_requirements_from_config(node_id, config)
    if not config or type(config) ~= "table" then
        return
    end

    local inputs = config.inputs
    if inputs and type(inputs) == "table" then
        self:set_input_requirements(node_id, {
            required = inputs.required or {},
            optional = inputs.optional or {}
        })
    end
end

---Load the current state from the database
---@return WorkflowState|nil self For method chaining
---@return string|nil error Error message if failed
function methods:load_state()
    if self.loaded then
        return self, nil
    end

    -- Load dataflow metadata
    local dataflow, err_df = dataflow_repo.get(self.dataflow_id)
    if err_df then
        return nil, "Failed to load dataflow: " .. err_df
    end

    if not dataflow then
        return nil, "Dataflow not found: " .. self.dataflow_id
    end

    self.dataflow_metadata = dataflow.metadata or {}

    -- Load nodes
    local nodes, err_nodes = dataflow_repo.get_nodes_for_dataflow(self.dataflow_id)
    if err_nodes then
        return nil, "Failed to load nodes: " .. err_nodes
    end

    self.nodes = {}
    for _, node in ipairs(nodes or {}) do
        -- Config is already parsed by dataflow_repo.get_nodes_for_dataflow()
        local config = node.config

        self.nodes[node.node_id] = {
            status = node.status,
            type = node.type,
            parent_node_id = node.parent_node_id,
            metadata = node.metadata or {},
            config = config
        }

        -- Set input requirements from node config
        self:_set_input_requirements_from_config(node.node_id, config)
    end

    -- Load existing data to check for workflow output and node inputs
    self:_load_existing_data()

    -- Reset running nodes to pending on recovery
    local reset_err = self:_reset_running_nodes()
    if reset_err then
        return nil, reset_err
    end

    -- Reconstruct active yields from persistent data
    self:_reconstruct_active_yields()

    self.loaded = true
    return self, nil
end

---Load existing data to track workflow output and node inputs
---@private
function methods:_load_existing_data()
    -- Check for existing workflow output
    local workflow_outputs = data_reader.with_dataflow(self.dataflow_id)
        :with_data_types(consts.DATA_TYPE.WORKFLOW_OUTPUT)
        :all()

    if #workflow_outputs > 0 then
        self.has_workflow_output = true
    end

    -- Load node inputs and update availability
    self:_update_input_availability()
end

---Reset any RUNNING nodes to PENDING on recovery
---@return string|nil error Error message if failed
---@private
function methods:_reset_running_nodes()
    local reset_commands = {}

    for node_id, node_data in pairs(self.nodes) do
        if node_data.status == consts.STATUS.RUNNING then
            table.insert(reset_commands, {
                type = consts.COMMAND_TYPES.UPDATE_NODE,
                payload = {
                    node_id = node_id,
                    status = consts.STATUS.PENDING,
                    metadata = {
                        orchestrator_restarted_at = time.now():format(time.RFC3339NANO),
                        previous_status_on_restart = consts.STATUS.RUNNING
                    }
                }
            })
            -- Update local state immediately
            node_data.status = consts.STATUS.PENDING
        end
    end

    -- Persist resets if needed
    if #reset_commands > 0 then
        local result, err = commit.execute(self.dataflow_id, uuid.v7(), reset_commands, { publish = false })
        if err then
            return "Failed to reset RUNNING nodes: " .. err
        end
    end

    return nil
end

---Reconstruct active yields from persistent NODE_YIELD records
---This is the key recovery mechanism that allows workflows to continue after restart
---@private
function methods:_reconstruct_active_yields()
    -- Find all NODE_YIELD records in this dataflow
    local yield_records = data_reader.with_dataflow(self.dataflow_id)
        :with_data_types(consts.DATA_TYPE.NODE_YIELD)
        :all()

    for _, yield_record in ipairs(yield_records) do
        local parent_node_id = yield_record.node_id
        local parent_node = self.nodes[parent_node_id]

        -- Only reconstruct yields for nodes that are now PENDING (were RUNNING when crashed)
        if parent_node and parent_node.status == consts.STATUS.PENDING then
            -- Parse yield content safely
            local yield_content
            if type(yield_record.content) == "string" then
                local success, parsed = pcall(json.decode, yield_record.content)
                if success then
                    yield_content = parsed
                else
                    goto continue -- Skip malformed yield records
                end
            else
                yield_content = yield_record.content
            end

            if not yield_content then
                goto continue
            end

            -- Extract yield information
            local yield_id = yield_content.yield_id
            local reply_to = yield_content.reply_to
            local yield_context = yield_content.yield_context or {}
            local run_nodes = yield_context.run_nodes or {}
            local child_path = yield_content.child_path or {}

            -- Rebuild pending children state and results
            local pending_children = {}
            local results = {}

            for _, child_id in ipairs(run_nodes) do
                local child_node = self.nodes[child_id]
                if child_node then
                    -- Set current status
                    pending_children[child_id] = child_node.status

                    -- If child is complete, find its result data
                    if child_node.status == consts.STATUS.COMPLETED_SUCCESS or
                       child_node.status == consts.STATUS.COMPLETED_FAILURE then
                        local result_data = data_reader.with_dataflow(self.dataflow_id)
                            :with_nodes(child_id)
                            :with_data_types(consts.DATA_TYPE.NODE_RESULT)
                            :one()
                        if result_data then
                            results[child_id] = result_data.data_id
                        end
                    end
                end
                -- Note: Missing children are simply not included in pending_children
            end

            -- Reconstruct yield info
            local yield_info = {
                yield_id = yield_id,
                reply_to = reply_to,
                pending_children = pending_children,
                results = results,
                child_path = child_path
            }

            -- Add to active yields
            self.active_yields[parent_node_id] = yield_info
        end

        ::continue::
    end
end

---Update input availability by scanning existing NODE_INPUT data
---@private
function methods:_update_input_availability()
    -- Reset availability
    for node_id, _ in pairs(self.input_tracker.requirements) do
        self.input_tracker.available[node_id] = {}
    end

    -- Load all node inputs
    local node_inputs = data_reader.with_dataflow(self.dataflow_id)
        :with_data_types(consts.DATA_TYPE.NODE_INPUT)
        :all()

    for _, input in ipairs(node_inputs) do
        if input.node_id then
            if not self.input_tracker.available[input.node_id] then
                self.input_tracker.available[input.node_id] = {}
            end

            local key = input.key or "default"
            self.input_tracker.available[input.node_id][key] = true
        end
    end
end

---Process a list of commit IDs and update state
---@param commit_ids table List of commit IDs to process
---@return table|nil result Result of processing
---@return string|nil error Error message if failed
function methods:process_commits(commit_ids)
    if not commit_ids or #commit_ids == 0 then
        return { changes_made = false, message = "No commits to process" }, nil
    end

    -- Queue APPLY_COMMIT commands for each commit
    for _, commit_id in ipairs(commit_ids) do
        table.insert(self.queued_commands, {
            type = consts.COMMAND.APPLY_COMMIT,
            payload = {
                commit_id = commit_id
            }
        })
    end

    -- Persist all commit applications
    local result, err = self:persist()
    if err then
        return nil, err
    end

    -- Update state from results
    self:_update_state_from_results(result)

    return result, nil
end

---Update internal state based on commit execution results
---@param results table Results from commit execution
---@private
function methods:_update_state_from_results(results)
    if not results or not results.results then
        return
    end

    for _, result in ipairs(results.results) do
        if not result or not result.input then
            goto continue
        end

        local command = result.input
        local command_type = command.type
        local payload = command.payload or {}

        -- Handle node operations
        if command_type == consts.COMMAND_TYPES.CREATE_NODE and result.node_id then
            -- Parse config if provided
            local config = payload.config

            local node = {
                status = payload.status or consts.STATUS.PENDING,
                type = payload.node_type,
                parent_node_id = payload.parent_node_id,
                metadata = payload.metadata or {},
                config = config
            }
            self.nodes[result.node_id] = node

            -- Set input requirements from config
            self:_set_input_requirements_from_config(result.node_id, config)

        elseif command_type == consts.COMMAND_TYPES.UPDATE_NODE and payload.node_id then
            local node_id = payload.node_id
            local node = self.nodes[node_id]

            if node then
                if payload.node_type then
                    node.type = payload.node_type
                end
                if payload.status then
                    node.status = payload.status
                end
                if payload.metadata then
                    node.metadata = payload.metadata
                end
                if payload.config then
                    node.config = payload.config
                    -- Update input requirements from new config
                    self:_set_input_requirements_from_config(node_id, payload.config)
                end
            end
        elseif command_type == consts.COMMAND_TYPES.DELETE_NODE and payload.node_id then
            self.nodes[payload.node_id] = nil

            -- Handle workflow operations
        elseif command_type == consts.COMMAND_TYPES.UPDATE_WORKFLOW then
            if payload.metadata then
                for k, v in pairs(payload.metadata) do
                    self.dataflow_metadata[k] = v
                end
            end

            -- Handle data operations
        elseif command_type == consts.COMMAND_TYPES.CREATE_DATA then
            if payload.data_type == consts.DATA_TYPE.WORKFLOW_OUTPUT then
                self.has_workflow_output = true
            elseif payload.data_type == consts.DATA_TYPE.NODE_INPUT and payload.node_id then
                -- Update input availability
                if not self.input_tracker.available[payload.node_id] then
                    self.input_tracker.available[payload.node_id] = {}
                end
                local key = payload.key or "default"
                self.input_tracker.available[payload.node_id][key] = true
            end
        end

        ::continue::
    end
end

---Get a snapshot of current state for the scheduler
---@return table SchedulerState Current state snapshot
function methods:get_scheduler_snapshot()
    -- Build active_processes map (node_id -> true for running processes)
    local active_proc_map = {}
    for node_id, pid in pairs(self.active_processes) do
        active_proc_map[node_id] = true
    end

    return {
        nodes = self.nodes,
        active_yields = self.active_yields,
        active_processes = active_proc_map,
        input_tracker = self.input_tracker,
        has_workflow_output = self.has_workflow_output
    }
end

---Query error details for failed nodes
---@return string|nil error_summary Formatted error summary, nil if no failures
function methods:get_failed_node_errors()
    -- Find failed nodes
    local failed_nodes = {}
    for node_id, node_data in pairs(self.nodes) do
        if node_data.status == consts.STATUS.COMPLETED_FAILURE then
            table.insert(failed_nodes, node_id)
        end
    end

    if #failed_nodes == 0 then
        return nil -- No failures
    end

    -- Query NODE_RESULT data for failed nodes
    local error_details = {}
    for _, node_id in ipairs(failed_nodes) do
        local result_data = data_reader.with_dataflow(self.dataflow_id)
            :with_nodes(node_id)
            :with_data_types(consts.DATA_TYPE.NODE_RESULT)
            :all()

        local error_message = "Unknown error"
        for _, result in ipairs(result_data) do
            if result.discriminator == "result.error" then
                local content = result.content or "Unknown error"

                -- Try to parse JSON content and extract meaningful error message
                if result.content_type == "application/json" or result.content_type == consts.CONTENT_TYPE.JSON then
                    local success, parsed = pcall(json.decode, content)
                    if success and type(parsed) == "table" then
                        -- Look for error.message first (most specific)
                        if parsed.error and type(parsed.error) == "table" and parsed.error.message then
                            error_message = tostring(parsed.error.message)
                        -- Fall back to top-level message
                        elseif parsed.message then
                            error_message = tostring(parsed.message)
                        -- Fall back to raw content if neither exists
                        else
                            error_message = tostring(content)
                        end
                    else
                        error_message = tostring(content)
                    end
                else
                    error_message = tostring(content)
                end
                break
            end
        end

        table.insert(error_details, "Node [" .. node_id .. "] failed: " .. error_message)
    end

    return table.concat(error_details, "; ")
end

---Track a running process
---@param node_id string Node ID
---@param pid string Process ID
---@return WorkflowState self For method chaining
function methods:track_process(node_id, pid)
    self.active_processes[node_id] = pid
    return self
end

---Handle a process exit
---@param pid string Process ID that exited
---@param success boolean Whether process succeeded
---@param result any Process result data
---@return table|nil exit_info Information about the exit
function methods:handle_process_exit(pid, success, result)
    -- Find the node ID for this PID
    local exited_node_id = nil
    for node_id, tracked_pid in pairs(self.active_processes) do
        if tracked_pid == pid then
            exited_node_id = node_id
            break
        end
    end

    if not exited_node_id then
        return nil -- Unknown PID
    end

    -- Remove from active processes
    self.active_processes[exited_node_id] = nil

    -- Update node status
    local new_status = success and consts.STATUS.COMPLETED_SUCCESS or consts.STATUS.COMPLETED_FAILURE
    if self.nodes[exited_node_id] then
        self.nodes[exited_node_id].status = new_status
    end

    -- Create node result data
    local result_data_id = uuid.v7()
    local discriminator = success and "result.success" or "result.error"

    table.insert(self.queued_commands, {
        type = consts.COMMAND_TYPES.UPDATE_NODE,
        payload = {
            node_id = exited_node_id,
            status = new_status
        }
    })

    table.insert(self.queued_commands, {
        type = consts.COMMAND_TYPES.CREATE_DATA,
        payload = {
            data_id = result_data_id,
            data_type = consts.DATA_TYPE.NODE_RESULT,
            content = result or (success and "Completed" or "Failed"),
            node_id = exited_node_id,
            discriminator = discriminator
        }
    })

    -- Check if this was a child in a yield
    local exit_info = {
        node_id = exited_node_id,
        success = success,
        result = result,
        result_data_id = result_data_id
    }

    -- Handle yield child completion
    local node_data = self.nodes[exited_node_id]
    if node_data and node_data.parent_node_id then
        local parent_id = node_data.parent_node_id
        local yield_info = self.active_yields[parent_id]

        if yield_info and yield_info.pending_children and yield_info.pending_children[exited_node_id] then
            -- Update child status in yield
            yield_info.pending_children[exited_node_id] = success and consts.STATUS.COMPLETED_SUCCESS or
            consts.STATUS.COMPLETED_FAILURE
            yield_info.results[exited_node_id] = result_data_id

            -- Check if all children are complete
            local all_complete = true
            for child_id, status in pairs(yield_info.pending_children) do
                if status == consts.STATUS.PENDING then
                    all_complete = false
                    break
                end
            end

            if all_complete then
                exit_info.yield_complete = {
                    parent_id = parent_id,
                    yield_info = yield_info
                }
            end
        end
    end

    return exit_info
end

---Track a yield request
---@param node_id string Node ID that is yielding
---@param yield_info YieldInfo Yield information
---@return WorkflowState self For method chaining
function methods:track_yield(node_id, yield_info)
    self.active_yields[node_id] = yield_info
    return self
end

---Satisfy a yield and remove it from tracking
---@param node_id string Node ID that was yielding
---@param results table Yield results
---@return WorkflowState self For method chaining
function methods:satisfy_yield(node_id, results)
    -- Create yield result data
    local yield_info = self.active_yields[node_id]
    if yield_info then
        table.insert(self.queued_commands, {
            type = consts.COMMAND_TYPES.CREATE_DATA,
            payload = {
                data_id = uuid.v7(),
                data_type = consts.DATA_TYPE.NODE_YIELD_RESULT,
                content = results,
                key = yield_info.yield_id,
                node_id = node_id
            }
        })

        -- Remove the yield
        self.active_yields[node_id] = nil
    end

    return self
end

---Set input requirements for a node
---@param node_id string Node ID
---@param requirements InputRequirements Input requirements { required = {}, optional = {} }
---@return WorkflowState self For method chaining
function methods:set_input_requirements(node_id, requirements)
    self.input_tracker.requirements[node_id] = requirements

    -- Initialize availability if not exists
    if not self.input_tracker.available[node_id] then
        self.input_tracker.available[node_id] = {}
    end

    return self
end

---Queue commands for the next persist operation
---@param commands table|table[] Single command or array of commands to queue
---@return WorkflowState self For method chaining
function methods:queue_commands(commands)
    if type(commands) == "table" and commands.type then
        -- Single command
        table.insert(self.queued_commands, commands)
    elseif type(commands) == "table" then
        -- Array of commands
        for _, cmd in ipairs(commands) do
            table.insert(self.queued_commands, cmd)
        end
    end
    return self
end

---Persist all queued commands to the database
---@return table|nil result Result of the persist operation
---@return string|nil error Error message if failed
function methods:persist()
    if #self.queued_commands == 0 then
        return { changes_made = false, message = "No commands to persist" }, nil
    end

    local op_id = uuid.v7()
    local result, err = commit.execute(self.dataflow_id, op_id, self.queued_commands, { publish = true })

    if err then
        return nil, "Failed to persist commands: " .. err
    end

    -- Update state from results
    self:_update_state_from_results(result)

    -- Clear queued commands
    self.queued_commands = {}

    return result, nil
end

---Get all nodes
---@return table<string, NodeData> Map of node_id -> node_data
function methods:get_nodes()
    return self.nodes
end

---Get a specific node
---@param node_id string Node ID
---@return NodeData|nil Node data or nil if not found
function methods:get_node(node_id)
    return self.nodes[node_id]
end

---Get dataflow metadata
---@return table Dataflow metadata
function methods:get_dataflow_metadata()
    return self.dataflow_metadata
end

---Check if a node is currently tracked as active (running or yielding)
---@param node_id string Node ID
---@return boolean True if node is active
function methods:is_node_active(node_id)
    -- Check if running
    if self.active_processes[node_id] then
        return true
    end

    -- Check if yielding
    if self.active_yields[node_id] then
        return true
    end

    -- Check if child of active yield
    for _, yield_info in pairs(self.active_yields) do
        if yield_info.pending_children and yield_info.pending_children[node_id] == consts.STATUS.PENDING then
            return true
        end
    end

    return false
end

return workflow_state