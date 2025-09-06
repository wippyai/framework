local json = require("json")
local uuid = require("uuid")
local time = require("time")
local consts = require("consts")

-- Default dependencies - can be overridden for testing
local default_deps = {
    commit = require("commit"),
    data_reader = require("data_reader"),
    process = process
}

-- Module table
local node = {}
local methods = {}
local mt = { __index = methods }

-- Utility: merge metadata tables
local function merge_metadata(existing, new_fields)
    local result = {}
    if type(existing) == "table" then
        for k, v in pairs(existing) do result[k] = v end
    end
    if type(new_fields) == "table" then
        for k, v in pairs(new_fields) do result[k] = v end
    end
    return result
end

-- Constructor with optional dependency injection
function node.new(args, deps)
    if not args then
        return nil, "Node args required"
    end
    if not args.node_id or not args.dataflow_id then
        return nil, "Node args must contain node_id and dataflow_id"
    end

    -- Use provided dependencies or defaults
    deps = deps or default_deps

    -- Unique topic for yield replies
    local yield_reply_topic = consts.MESSAGE_TOPIC.YIELD_REPLY_PREFIX .. args.node_id
    local yield_channel = deps.process.listen(yield_reply_topic)

    local instance = {
        -- Core identifiers
        node_id = args.node_id,
        dataflow_id = args.dataflow_id,
        node = args.node or {},
        path = args.path or { args.node_id },

        -- Configuration (loaded from config, not root)
        _config = (args.node and args.node.config) or {},
        data_targets = (args.node and args.node.config and args.node.config.data_targets) or {},
        error_targets = (args.node and args.node.config and args.node.config.error_targets) or {},

        -- State management
        _metadata = (args.node and args.node.metadata) or {},
        _queued_commands = {},
        _created_data_ids = {},
        _cached_inputs = nil,

        -- Yield communication
        _yield_channel = yield_channel,
        _yield_reply_topic = yield_reply_topic,
        _last_yield_id = nil,

        -- Dependencies
        _deps = deps
    }

    return setmetatable(instance, mt), nil
end

-- =============================================================================
-- CONFIG ACCESSOR
-- =============================================================================

-- Get node configuration
function methods:config()
    return self._config
end

-- =============================================================================
-- INPUT METHODS
-- =============================================================================

-- Get all inputs as a map by key (cached)
function methods:inputs()
    if self._cached_inputs then
        return self._cached_inputs
    end

    local input_data = self._deps.data_reader.with_dataflow(self.dataflow_id)
        :with_nodes(self.node_id)
        :with_data_types(consts.DATA_TYPE.NODE_INPUT)
        :fetch_options({ replace_references = true })
        :all()

    local inputs_map = {}

    for _, input in ipairs(input_data) do
        local parsed_content = input.content

        -- Parse JSON content if needed
        if input.content_type == consts.CONTENT_TYPE.JSON and type(input.content) == "string" then
            local parsed, err = json.decode(input.content)
            if not err then
                parsed_content = parsed
            end
        end

        -- Use key as map key, or "" if no key
        local map_key = input.key or ""
        inputs_map[map_key] = {
            content = parsed_content,
            metadata = input.metadata or {},
            key = input.key,
            discriminator = input.discriminator
        }
    end

    self._cached_inputs = inputs_map
    return inputs_map
end

-- Get specific input by key
function methods:input(key)
    if not key then
        error("Input key is required")
    end

    local inputs_map = self:inputs()
    return inputs_map[key]
end

-- =============================================================================
-- DATA METHODS (Chainable)
-- =============================================================================

-- Create any data type
function methods:data(data_type, content, options)
    if not data_type or data_type == "" then
        error("Data type is required")
    end
    if content == nil then
        error("Content is required")
    end

    options = options or {}

    -- Determine content type
    local content_type = options.content_type
    if not content_type then
        if type(content) == "table" then
            content_type = consts.CONTENT_TYPE.JSON
        else
            content_type = consts.CONTENT_TYPE.TEXT
        end
    end

    -- Generate data_id
    local data_id = options.data_id or uuid.v7()
    table.insert(self._created_data_ids, data_id)

    -- Queue the command
    local command = {
        type = consts.COMMAND_TYPES.CREATE_DATA,
        payload = {
            data_id = data_id,
            data_type = data_type,
            key = options.key,
            content = content,
            content_type = content_type,
            discriminator = options.discriminator,
            node_id = options.node_id,
            metadata = options.metadata
        }
    }

    table.insert(self._queued_commands, command)
    return self
end

-- Update node metadata
function methods:metadata(updates)
    if not updates or type(updates) ~= "table" then
        return self
    end

    self._metadata = merge_metadata(self._metadata, updates)

    local command = {
        type = consts.COMMAND_TYPES.UPDATE_NODE,
        payload = {
            node_id = self.node_id,
            metadata = self._metadata
        }
    }

    table.insert(self._queued_commands, command)
    return self
end

-- =============================================================================
-- CHILD NODES
-- =============================================================================

-- Create child nodes
function methods:with_child_nodes(definitions)
    if not definitions or type(definitions) ~= "table" or #definitions == 0 then
        return nil, "Child definitions required"
    end

    local child_ids = {}

    for _, def in ipairs(definitions) do
        if not def.node_type then
            return nil, "Child definition must include 'node_type'"
        end

        local child_id = def.node_id or uuid.v7()
        table.insert(child_ids, child_id)

        local command = {
            type = consts.COMMAND_TYPES.CREATE_NODE,
            payload = {
                node_id = child_id,
                node_type = def.node_type,
                parent_node_id = def.parent_node_id or self.node_id,
                status = def.status or consts.STATUS.PENDING,
                config = def.config or {},
                metadata = def.metadata or {}
            }
        }

        table.insert(self._queued_commands, command)
    end

    return child_ids, nil
end

-- =============================================================================
-- YIELD AND CONTROL FLOW
-- =============================================================================

-- Submit queued commands immediately without yielding
function methods:submit()
    if #self._queued_commands == 0 then
        return true, nil
    end

    local op_id = uuid.v7()
    local success, err = self._deps.commit.submit(self.dataflow_id, op_id, self._queued_commands)

    if success then
        self._queued_commands = {}
        return true, nil
    else
        return false, err
    end
end

-- Yield execution
function methods:yield(options)
    options = options or {}

    local yield_id = uuid.v7()
    local op_id = uuid.v7()

    -- Add yield record for persistence
    local yield_command = {
        type = consts.COMMAND_TYPES.CREATE_DATA,
        payload = {
            data_id = uuid.v7(),
            data_type = consts.DATA_TYPE.NODE_YIELD,
            content = {
                node_id = self.node_id,
                yield_id = yield_id,
                reply_to = self._yield_reply_topic,
                yield_context = {
                    run_nodes = options.run_nodes or {}
                }
            },
            content_type = consts.CONTENT_TYPE.JSON,
            key = yield_id,
            node_id = self.node_id
        }
    }
    table.insert(self._queued_commands, yield_command)

    -- Submit all queued commands
    local submitted, err = self._deps.commit.submit(self.dataflow_id, op_id, self._queued_commands)
    if not submitted then
        return nil, "Failed to submit yield: " .. (err or "unknown error")
    end
    self._queued_commands = {}

    -- Send yield signal to orchestrator
    local yield_signal = {
        request_context = {
            yield_id = yield_id,
            node_id = self.node_id,
            reply_to = self._yield_reply_topic
        },
        yield_context = {
            run_nodes = options.run_nodes or {}
        }
    }

    local success = self._deps.process.send(
        "dataflow." .. self.dataflow_id,
        consts.MESSAGE_TOPIC.YIELD_REQUEST,
        yield_signal
    )

    if not success then
        return nil, "Failed to send yield signal"
    end

    -- Wait for reply
    local received, ok = self._yield_channel:receive()
    if not ok then
        return nil, "Yield channel closed or error"
    end

    self._last_yield_id = yield_id

    -- Return the response data (map of child_id -> result_struct)
    if received and received.response_data then
        return received.response_data.run_node_results or {}, nil
    end

    return {}, nil
end

-- =============================================================================
-- QUERY
-- =============================================================================

-- Create a query builder
function methods:query()
    return self._deps.data_reader.with_dataflow(self.dataflow_id)
end

-- =============================================================================
-- OUTPUT ROUTING
-- =============================================================================

-- Route output content according to data_targets configuration
function methods:_route_outputs(content)
    local routed_data_ids = {}

    for _, target in ipairs(self.data_targets) do
        local data_id = uuid.v7()
        table.insert(routed_data_ids, data_id)

        self:data(target.data_type, content, {
            data_id = data_id,
            key = target.key,
            discriminator = target.discriminator,
            node_id = target.node_id or self.node_id,
            content_type = target.content_type,
            metadata = target.metadata
        })
    end

    return routed_data_ids
end

-- Route error content according to error_targets configuration
function methods:_route_errors(error_content)
    local routed_data_ids = {}

    for _, target in ipairs(self.error_targets) do
        local data_id = uuid.v7()
        table.insert(routed_data_ids, data_id)

        self:data(target.data_type, error_content, {
            data_id = data_id,
            key = target.key,
            discriminator = target.discriminator,
            node_id = target.node_id,
            content_type = target.content_type,
            metadata = target.metadata
        })
    end

    return routed_data_ids
end

-- Internal: Submit remaining commands
function methods:_submit_final()
    if #self._queued_commands == 0 then
        return true, nil
    end

    local result, err = self._deps.commit.submit(
        self.dataflow_id,
        uuid.v7(),
        self._queued_commands
    )

    self._queued_commands = {}
    return result ~= nil, err
end

-- =============================================================================
-- COMPLETION
-- =============================================================================

-- Complete successfully
function methods:complete(output_content, message, extra_metadata)
    -- Update final metadata
    if extra_metadata then
        self:metadata(extra_metadata)
    end

    if message then
        self:metadata({ status_message = message })
    end

    -- Route output content via data_targets
    local data_ids = {}
    if output_content ~= nil then
        data_ids = self:_route_outputs(output_content)
    end

    -- Submit any remaining commands
    local success, err = self:_submit_final()
    if not success then
        return {
            success = false,
            message = "Failed to submit final commands: " .. (err or "unknown error"),
            error = err,
            data_ids = {}
        }
    end

    return {
        success = true,
        message = message or "Node execution completed successfully",
        data_ids = data_ids
    }
end

-- Complete with failure
function methods:fail(error_details, message, extra_metadata)
    local error_msg = error_details or "Unknown error"
    local status_msg = message or error_msg

    -- Store error in metadata
    local error_metadata = {
        status_message = status_msg,
        error = error_msg
    }

    if extra_metadata then
        error_metadata = merge_metadata(error_metadata, extra_metadata)
    end

    self:metadata(error_metadata)

    -- Route error content via error_targets
    local data_ids = {}
    if error_details ~= nil then
        data_ids = self:_route_errors(error_details)
    end

    -- Submit any remaining commands
    local success, err = self:_submit_final()
    if not success then
        return {
            success = false,
            message = "Failed to submit final commands: " .. (err or "unknown error"),
            error = err,
            data_ids = {}
        }
    end

    return {
        success = false,
        message = status_msg,
        error = error_msg,
        data_ids = data_ids
    }
end

-- =============================================================================
-- ADVANCED
-- =============================================================================

-- Queue raw command
function methods:command(cmd)
    if not cmd or not cmd.type then
        error("Command must have a type")
    end

    table.insert(self._queued_commands, cmd)
    return self
end

-- Get created data IDs
function methods:created_data_ids()
    return self._created_data_ids
end

return node