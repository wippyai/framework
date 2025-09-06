local uuid = require("uuid")
local json = require("json")
local agent_consts = require("agent_consts")
local data_reader = require("data_reader")

local delegation_handler = {}

delegation_handler._agent_registry = nil

local function get_agent_registry()
    return delegation_handler._agent_registry or require("agent_registry")
end

local function get_agent_info(agent_id)
    local registry = get_agent_registry()
    local agent_spec, err = registry.get_by_id(agent_id)
    if not agent_spec then
        agent_spec, err = registry.get_by_name(agent_id)
    end

    if agent_spec then
        return {
            title = agent_spec.title or agent_spec.name,
            name = agent_spec.name
        }
    end

    return {
        title = agent_id,
        name = agent_id
    }
end

local function merge_session_with_delegate_context(session_context, delegate_context)
    local merged = {}

    -- Start with session context (parent arena context)
    if session_context then
        for k, v in pairs(session_context) do
            merged[k] = v
        end
    end

    -- Override with delegate context (delegate takes precedence)
    if delegate_context then
        for k, v in pairs(delegate_context) do
            merged[k] = v
        end
    end

    return merged
end

local function get_yield_results(parent_node_sdk)
    local reader, reader_err = data_reader.with_dataflow(parent_node_sdk.dataflow_id)
    if reader_err then
        return nil, "Failed to create data reader: " .. reader_err
    end

    local yield_result_data, yield_query_err = reader
        :with_nodes(parent_node_sdk.node_id)
        :with_data_types("node.yield.result")
        :all()

    if yield_query_err then
        return nil, "Failed to query yield results: " .. yield_query_err
    end

    if not yield_result_data or #yield_result_data == 0 then
        return nil, "No yield result data found"
    end

    local latest_yield_result = yield_result_data[#yield_result_data]

    local yield_content = latest_yield_result.content
    if type(yield_content) == "string" then
        local decoded, decode_err = json.decode(yield_content)
        if decode_err then
            return nil, "Failed to parse yield result content: " .. decode_err
        end
        yield_content = decoded
    end

    if not yield_content or type(yield_content) ~= "table" then
        return nil, "Invalid yield result content format"
    end

    return yield_content, nil
end

local function get_node_result_by_id(parent_node_sdk, result_data_id)
    local reader, reader_err = data_reader.with_dataflow(parent_node_sdk.dataflow_id)
    if reader_err then
        return nil, "Failed to create data reader: " .. reader_err
    end

    local actual_result_data, result_query_err = reader
        :with_data({result_data_id})
        :one()

    if result_query_err then
        return nil, "Failed to query actual result data: " .. result_query_err
    end

    if not actual_result_data then
        return nil, "No actual result data found for data_id: " .. result_data_id
    end

    return actual_result_data, nil
end

local function extract_error_message(result_content, discriminator)
    if discriminator ~= "result.error" or type(result_content) ~= "table" then
        return nil
    end

    if result_content.error and type(result_content.error) == "table" then
        return result_content.error.message or result_content.error.code or "Unknown error"
    elseif result_content.message then
        return result_content.message
    elseif result_content.error then
        return tostring(result_content.error)
    end

    return "Delegation failed"
end

function delegation_handler.create_child_node(parent_node_sdk, delegation, delegation_index, session_context)
    local child_id = uuid.v7()
    local result_key = "delegation_result_" .. delegation_index

    local agent_info = get_agent_info(delegation.agent_id)

    local child_arena_context = merge_session_with_delegate_context(session_context, delegation.context)

    local child_config = {
        agent = delegation.agent_id,
        arena = {
            prompt = delegation.task_query or "Complete the delegated task",
            max_iterations = delegation.max_iterations or agent_consts.DEFAULTS.MAX_ITERATIONS,
            min_iterations = 1,
            tool_calling = delegation.tool_calling or agent_consts.DEFAULTS.TOOL_CALLING,
            traits = delegation.traits or {},
            tools = delegation.tools or {},
            exit_schema = delegation.exit_schema,
            context = child_arena_context
        },
        data_targets = {
            {
                data_type = agent_consts.DATA_TYPE.AGENT_DELEGATION,
                key = result_key,
                node_id = child_id
            }
        }
    }

    local metadata = {
        title = agent_info.title,
        tool_call_id = delegation.tool_call_id
    }

    parent_node_sdk:command({
        type = "CREATE_NODE",
        payload = {
            node_id = child_id,
            node_type = "wippy.dataflow.node.agent:node",
            parent_node_id = parent_node_sdk.node_id,
            status = "pending",
            config = child_config,
            metadata = metadata
        }
    })

    if delegation.input_data then
        parent_node_sdk:data("node.input", delegation.input_data, {
            node_id = child_id,
            key = ""
        })
    end

    return {
        child_id = child_id,
        result_key = result_key,
        delegation_index = delegation_index,
        agent_id = delegation.agent_id,
        agent_info = agent_info,
        delegation = delegation,
        context = child_arena_context,
        delegate_tool_name = delegation.delegate_tool_name,
        tool_call_id = delegation.tool_call_id
    }
end

function delegation_handler.process_delegate_calls(agent_result, parent_node_sdk, delegation_index, session_context)
    if not agent_result.delegate_calls or #agent_result.delegate_calls == 0 then
        return {}
    end

    local delegation_infos = {}
    local current_index = delegation_index

    for _, delegate_call in ipairs(agent_result.delegate_calls) do
        local delegation = {
            agent_id = delegate_call.agent_id,
            task_query = "Complete the delegated task",
            input_data = delegate_call.arguments,
            tool_calling = "auto",
            max_iterations = agent_consts.DEFAULTS.MAX_ITERATIONS,
            context = delegate_call.context,
            delegate_tool_name = delegate_call.name,
            tool_call_id = delegate_call.id
        }

        local delegation_info = delegation_handler.create_child_node(parent_node_sdk, delegation, current_index, session_context)
        table.insert(delegation_infos, delegation_info)
        current_index = current_index + 1
    end

    return delegation_infos
end

function delegation_handler.create_delegation_batch(agent_result, parent_node_sdk, session_context)
    local delegation_infos = {}
    local delegation_index = 1

    if agent_result and agent_result.delegate_calls then
        local delegate_infos = delegation_handler.process_delegate_calls(agent_result, parent_node_sdk, delegation_index, session_context)
        for _, info in ipairs(delegate_infos) do
            table.insert(delegation_infos, info)
            delegation_index = delegation_index + 1
        end
    end

    return delegation_infos
end

function delegation_handler.execute_delegation_batch(delegation_infos, parent_node_sdk)
    if not delegation_infos or #delegation_infos == 0 then
        return {}, nil
    end

    local child_node_ids = {}
    for _, info in ipairs(delegation_infos) do
        table.insert(child_node_ids, info.child_id)
    end

    local delegation_context = {}
    for _, info in ipairs(delegation_infos) do
        delegation_context[info.child_id] = {
            delegation_index = info.delegation_index,
            result_key = info.result_key,
            agent_title = info.agent_info.title,
            delegate_tool_name = info.delegate_tool_name,
            tool_call_id = info.tool_call_id
        }
    end

    parent_node_sdk:metadata({
        active_delegations = delegation_context
    })

    local yield_result, yield_err = parent_node_sdk:yield({ run_nodes = child_node_ids })
    if yield_err then
        return nil, string.format(agent_consts.ERROR_MSG.DELEGATION_FAILED, yield_err)
    end

    local delegation_results = {}
    for _, info in ipairs(delegation_infos) do
        local result, err = delegation_handler.collect_delegation_result(info, parent_node_sdk)
        if result then
            table.insert(delegation_results, {
                delegation_info = info,
                result = result,
                success = true
            })
        else
            table.insert(delegation_results, {
                delegation_info = info,
                error = err or "No result from delegated agent",
                success = false
            })
        end
    end

    parent_node_sdk:metadata({
        active_delegations = nil
    })

    return delegation_results, nil
end

function delegation_handler.collect_delegation_result(delegation_info, parent_node_sdk)
    local yield_content, yield_err = get_yield_results(parent_node_sdk)
    if yield_err then
        return nil, yield_err
    end

    local child_id = delegation_info.child_id
    local result_data_id = yield_content[child_id]

    if not result_data_id then
        return nil, "No result data_id found for child: " .. child_id
    end

    local actual_result_data, result_err = get_node_result_by_id(parent_node_sdk, result_data_id)
    if result_err then
        return nil, result_err
    end

    local result_content = actual_result_data.content
    if actual_result_data.content_type == "application/json" and type(result_content) == "string" then
        local decoded, decode_err = json.decode(result_content)
        if decode_err then
            return result_content, nil
        end
        result_content = decoded
    end

    local error_message = extract_error_message(result_content, actual_result_data.discriminator)
    if error_message then
        return nil, error_message
    end

    return result_content, nil
end

function delegation_handler.map_delegation_results_to_conversation(delegation_results, parent_node_sdk, iteration)
    for _, delegation_result in ipairs(delegation_results) do
        local info = delegation_result.delegation_info

        if delegation_result.success then
            local delegation_data_id = nil
            local reader = parent_node_sdk:query()
                :with_nodes(info.child_id)
                :with_data_types(agent_consts.DATA_TYPE.AGENT_DELEGATION)

            local delegation_data = reader:all()
            if delegation_data and #delegation_data > 0 then
                delegation_data_id = delegation_data[#delegation_data].data_id
            end

            if delegation_data_id then
                parent_node_sdk:data(agent_consts.DATA_TYPE.AGENT_OBSERVATION, "", {
                    key = delegation_data_id,
                    node_id = parent_node_sdk.node_id,
                    content_type = "dataflow/reference",
                    metadata = {
                        iteration = iteration,
                        tool_call_id = info.tool_call_id,
                        tool_name = info.delegate_tool_name
                    }
                })
            else
                local tool_key = info.delegate_tool_name and
                    (iteration .. "_" .. info.delegate_tool_name) or
                    (iteration .. "_delegation_" .. info.delegation_index)

                parent_node_sdk:data(agent_consts.DATA_TYPE.AGENT_OBSERVATION, delegation_result.result, {
                    key = tool_key,
                    node_id = parent_node_sdk.node_id,
                    metadata = {
                        iteration = iteration,
                        tool_call_id = info.tool_call_id,
                        tool_name = info.delegate_tool_name
                    }
                })
            end
        else
            local error_content = delegation_result.error or "Unknown delegation failure"
            local tool_key = info.delegate_tool_name and
                (iteration .. "_" .. info.delegate_tool_name) or
                (iteration .. "_delegation_error_" .. info.delegation_index)

            parent_node_sdk:data(agent_consts.DATA_TYPE.AGENT_OBSERVATION, error_content, {
                key = tool_key,
                node_id = parent_node_sdk.node_id,
                metadata = {
                    iteration = iteration,
                    tool_call_id = info.tool_call_id,
                    tool_name = info.delegate_tool_name,
                    is_error = true
                }
            })
        end
    end
end

return delegation_handler