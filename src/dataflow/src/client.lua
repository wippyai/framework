local uuid = require("uuid")
local time = require("time")
local security = require("security")
local funcs = require("funcs")
local consts = require("consts")

-- Get default dependencies (lazy loaded)
local function get_default_deps()
    return {
        dataflow_repo = require("dataflow_repo"),
        commit = require("commit"),
        data_reader = require("data_reader"),
        process = process,
        funcs = require("funcs"),
        security = require("security")
    }
end

local client = {}
local methods = {}
local mt = { __index = methods }

-- Constructor
function client.new(deps)
    deps = deps or get_default_deps()

    -- Get current security actor
    local actor = deps.security.actor()

    -- Validate security actor exists
    if not actor then
        return nil, "No current security actor available"
    end

    -- Validate security actor has id method
    if type(actor.id) ~= "function" then
        return nil, "Security actor does not have id() method"
    end

    -- Get actor ID
    local actor_id = actor:id()

    -- Validate actor ID is not empty
    if not actor_id or actor_id == "" then
        return nil, "Actor ID cannot be empty"
    end

    local instance = {
        _actor_id = actor_id,
        _deps = deps
    }

    return setmetatable(instance, mt), nil
end

-- Create workflow with optional commands and options
function methods:create_workflow(commands, options)
    commands = commands or {}
    options = options or {}

    local dataflow_id = options.dataflow_id or uuid.v7()
    local workflow_type = options.type or "workflow"
    local metadata = options.metadata or {}

    -- Create workflow command
    local workflow_command = {
        type = consts.COMMAND_TYPES.CREATE_WORKFLOW,
        payload = {
            dataflow_id = dataflow_id,
            type = workflow_type,
            actor_id = self._actor_id,
            metadata = metadata
        }
    }

    -- Combine workflow command with additional commands
    local all_commands = { workflow_command }
    for _, cmd in ipairs(commands) do
        table.insert(all_commands, cmd)
    end

    -- Execute commands
    local result, err = self._deps.commit.execute(dataflow_id, uuid.v7(), all_commands)
    if err then
        return nil, err
    end

    return dataflow_id, nil
end

-- Execute workflow synchronously
function methods:execute(dataflow_id, options)
    options = options or {}
    local fetch_output = options.fetch_output
    if fetch_output == nil then
        fetch_output = true
    end

    if not dataflow_id or dataflow_id == "" then
        return nil, "Dataflow ID is required"
    end

    -- Prepare orchestrator arguments
    local orchestrator_args = {
        dataflow_id = dataflow_id
    }

    if options.init_func_id then
        orchestrator_args.init_func_id = options.init_func_id
    end

    -- Execute via funcs
    local executor = self._deps.funcs.new()
    local orch_result, err = executor:call(consts.ORCHESTRATOR, orchestrator_args)

    if err then
        return nil, "Failed to execute workflow: " .. err
    end

    if not orch_result then
        return nil, "No result returned from orchestrator"
    end

    -- Build consistent result format
    local result = {
        success = orch_result.success,
        dataflow_id = orch_result.dataflow_id or dataflow_id,
        data = nil
    }

    -- Handle workflow failure
    if not orch_result.success then
        result.error = orch_result.error or "Workflow failed"
        return result, nil
    end

    -- Handle successful workflow - fetch outputs if requested
    if fetch_output then
        local outputs, output_err = self:output(dataflow_id)
        if output_err then
            return nil, "Failed to fetch workflow outputs: " .. output_err
        end
        result.data = outputs
    end

    return result, nil
end

-- Get workflow output data as key=>value pairs
function methods:output(dataflow_id)
    if not dataflow_id or dataflow_id == "" then
        return nil, "Dataflow ID is required"
    end

    if not self._deps.data_reader then
        return nil, "Data reader dependency not available"
    end

    -- Fetch all workflow outputs with error handling
    local output_data, output_err = self._deps.data_reader.with_dataflow(dataflow_id)
        :with_data_types(consts.DATA_TYPE.WORKFLOW_OUTPUT)
        :fetch_options({ replace_references = true })
        :all()

    if output_err then
        return nil, "Failed to fetch workflow outputs: " .. tostring(output_err)
    end

    if not output_data or #output_data == 0 then
        return {}, nil -- Return empty table if no outputs
    end

    local outputs = {}
    local root_output = nil

    for _, data in ipairs(output_data) do
        local key = data.key or ""
        local content = data.content

        -- Parse JSON content if it's a string
        if type(content) == "string" and data.content_type == consts.CONTENT_TYPE.JSON then
            local json = require("json")
            local decoded, decode_err = json.decode(content)
            if not decode_err then
                content = decoded
            end
        end

        if key == "" then
            -- Root output - store separately
            root_output = content
        else
            -- Named output
            outputs[key] = content
        end
    end

    -- If we have a root output and no named outputs, return the root content directly
    if root_output and next(outputs) == nil then
        return root_output, nil
    end

    -- If we have a root output and named outputs, include root as special key
    if root_output then
        outputs[""] = root_output
    end

    return outputs, nil
end

-- Start workflow asynchronously
function methods:start(dataflow_id, options)
    options = options or {}

    if not dataflow_id or dataflow_id == "" then
        return nil, "Dataflow ID is required"
    end

    -- Prepare orchestrator arguments
    local orchestrator_args = {
        dataflow_id = dataflow_id
    }

    if options.init_func_id then
        orchestrator_args.init_func_id = options.init_func_id
    end

    -- Spawn orchestrator process
    local pid = self._deps.process.spawn(consts.ORCHESTRATOR, consts.HOST_ID, orchestrator_args)
    if not pid then
        return nil, "Failed to spawn workflow process"
    end

    return dataflow_id, nil
end

-- Cancel workflow
function methods:cancel(dataflow_id, timeout)
    if not dataflow_id or dataflow_id == "" then
        return false, "Workflow ID is required"
    end

    timeout = timeout or "30s"

    -- Verify workflow exists and user has access
    local workflow, err = self._deps.dataflow_repo.get_by_user(dataflow_id, self._actor_id)
    if err then
        return false, err
    end

    if not workflow then
        return false, "Workflow not found"
    end

    -- Check if workflow can be cancelled
    local cancellable_states = {
        [consts.STATUS.PENDING] = true,
        [consts.STATUS.RUNNING] = true
    }

    if not cancellable_states[workflow.status] then
        return false, "Workflow cannot be cancelled in current state: " .. workflow.status
    end

    -- Find workflow process
    local process_name = "dataflow." .. dataflow_id
    local pid = self._deps.process.registry.lookup(process_name)
    if not pid then
        return false, "Workflow process not found in registry"
    end

    -- Send cancel signal
    local success, cancel_err = self._deps.process.cancel(pid, timeout)
    if not success then
        return false, "Failed to send cancel signal: " .. (cancel_err or "unknown error")
    end

    return true, nil, {
        dataflow_id = dataflow_id,
        timeout = timeout,
        message = "Cancel signal sent to workflow process"
    }
end

-- Terminate workflow
function methods:terminate(dataflow_id)
    if not dataflow_id or dataflow_id == "" then
        return false, "Workflow ID is required"
    end

    -- Verify workflow exists and user has access
    local workflow, err = self._deps.dataflow_repo.get_by_user(dataflow_id, self._actor_id)
    if err then
        return false, err
    end

    if not workflow then
        return false, "Workflow not found"
    end

    -- Check if workflow is already finished
    local finished_states = {
        [consts.STATUS.COMPLETED_SUCCESS] = true,
        [consts.STATUS.COMPLETED_FAILURE] = true,
        [consts.STATUS.CANCELLED] = true,
        [consts.STATUS.TERMINATED] = true
    }

    if finished_states[workflow.status] then
        return false, "Workflow already finished with status: " .. workflow.status
    end

    local info = {
        dataflow_id = dataflow_id,
        process_terminated = false,
        status_updated = false
    }

    -- Find and terminate workflow process
    local process_name = "dataflow." .. dataflow_id
    local pid = self._deps.process.registry.lookup(process_name)
    if pid then
        local terminate_success, terminate_err = self._deps.process.terminate(pid)
        if terminate_success then
            info.process_terminated = true
        else
            info.terminate_error = terminate_err
        end
    end

    -- Update workflow status
    local update_commands = {
        {
            type = consts.COMMAND_TYPES.UPDATE_WORKFLOW,
            payload = {
                status = consts.STATUS.TERMINATED,
                metadata = {
                    terminated_at = time.now():format(time.RFC3339),
                    terminated_by = self._actor_id
                }
            }
        }
    }

    local result, update_err = self._deps.commit.execute(dataflow_id, uuid.v7(), update_commands)
    if update_err then
        return false, "Failed to update workflow status: " .. update_err, info
    end

    info.status_updated = true
    return true, nil, info
end

-- Get workflow status
function methods:get_status(dataflow_id)
    if not dataflow_id or dataflow_id == "" then
        return nil, "Workflow ID is required"
    end

    -- Get workflow with actor verification
    local workflow, err = self._deps.dataflow_repo.get_by_user(dataflow_id, self._actor_id)
    if err then
        return nil, err
    end

    if not workflow then
        return nil, "Workflow not found"
    end

    return workflow.status, nil
end

return client
