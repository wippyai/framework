local json = require("json")
local uuid = require("uuid")
local node_sdk = require("node_sdk")
local agent_context = require("agent_context")
local tool_caller = require("tool_caller")
local prompt_builder = require("prompt_builder")
local control_handler = require("control_handler")
local delegation_handler = require("delegation_handler")
local agent_consts = require("agent_consts")
local tools = require("tools")

local function merge_contexts(base_context, input_context)
    local merged = {}
    if base_context then
        for k, v in pairs(base_context) do
            merged[k] = v
        end
    end
    if input_context then
        for k, v in pairs(input_context) do
            merged[k] = v
        end
    end
    return merged
end

local function format_token_count(count)
    if count >= 1000 then
        return string.format("%.1fK", count / 1000)
    else
        return tostring(count)
    end
end

local function build_status_message(iteration, max_iterations, total_tokens, tool_calls_count, is_final, task_complete)
    local status_parts = {}

    if is_final then
        if task_complete then
            table.insert(status_parts, string.format("Completed %d/%d", iteration, max_iterations))
        else
            table.insert(status_parts, string.format("Max iterations %d/%d", iteration, max_iterations))
        end
    else
        if iteration == 0 then
            table.insert(status_parts, "Starting agent")
        else
            table.insert(status_parts, string.format("Iteration %d/%d", iteration, max_iterations))
        end
    end

    local details = {}

    if total_tokens.prompt_tokens and total_tokens.prompt_tokens > 0 then
        table.insert(details, "in: " .. format_token_count(total_tokens.prompt_tokens))
    end

    local completion_total = (total_tokens.completion_tokens or 0) + (total_tokens.thinking_tokens or 0)
    if completion_total > 0 then
        table.insert(details, "out: " .. format_token_count(completion_total))
    end

    if tool_calls_count > 0 then
        table.insert(details, "T: " .. tool_calls_count)
    end

    if #details > 0 then
        table.insert(status_parts, table.concat(details, ", "))
    end

    return table.concat(status_parts, " - ")
end

local function process_multiple_inputs(inputs, input_config)
    local config = input_config or {}
    local context_key = config.context_key
    local agent_id_key = config.agent_id_key
    local prompt_key = config.prompt_key or agent_consts.INPUT_DEFAULTS.PROMPT_KEY
    local required = config.required or agent_consts.INPUT_DEFAULTS.REQUIRED

    for _, req_key in ipairs(required) do
        if not inputs[req_key] then
            return nil, nil, nil, string.format(agent_consts.ERROR_MSG.INPUT_MISSING, req_key)
        end
    end

    local input_context = nil
    if context_key and inputs[context_key] then
        local context_content = inputs[context_key].content
        if type(context_content) ~= "table" then
            return nil, nil, nil, string.format(agent_consts.ERROR_MSG.INPUT_VALIDATION_FAILED, "context must be a table/object")
        end
        input_context = context_content
    end

    local agent_id_override = nil
    if agent_id_key and inputs[agent_id_key] then
        local agent_id_content = inputs[agent_id_key].content
        if type(agent_id_content) ~= "string" or agent_id_content == "" then
            return nil, nil, nil, string.format(agent_consts.ERROR_MSG.INPUT_VALIDATION_FAILED, "agent_id must be a non-empty string")
        end
        agent_id_override = agent_id_content
    end

    local input_data = ""
    if prompt_key and prompt_key ~= "" then
        if inputs[prompt_key] then
            input_data = inputs[prompt_key].content
        end
    else
        if inputs[""] then
            input_data = inputs[""].content
        elseif inputs.default then
            input_data = inputs.default.content
        else
            for key, input in pairs(inputs) do
                input_data = input.content
                break
            end
        end
    end

    if input_data == nil then
        input_data = ""
    end

    return input_context, agent_id_override, input_data, nil
end

local function validate_and_resolve_config(config)
    if not config then
        return nil, agent_consts.ERROR_MSG.INVALID_CONFIG
    end

    if not config.agent then
        return nil, "Agent configuration is required"
    end

    if not config.arena then
        return nil, "Arena configuration is required"
    end

    if not config.arena.prompt then
        return nil, "Arena prompt is required"
    end

    if config.inputs then
        local inputs_config = config.inputs

        if inputs_config.context_key and type(inputs_config.context_key) ~= "string" then
            return nil, "inputs.context_key must be a string"
        end

        if inputs_config.agent_id_key and type(inputs_config.agent_id_key) ~= "string" then
            return nil, "inputs.agent_id_key must be a string"
        end

        if inputs_config.prompt_key and type(inputs_config.prompt_key) ~= "string" then
            return nil, "inputs.prompt_key must be a string"
        end

        if inputs_config.required and type(inputs_config.required) ~= "table" then
            return nil, "inputs.required must be an array"
        end

        if inputs_config.required then
            for i, req_key in ipairs(inputs_config.required) do
                if type(req_key) ~= "string" then
                    return nil, string.format("inputs.required[%d] must be a string", i)
                end
            end
        end
    end

    local tool_calling = config.arena.tool_calling or agent_consts.DEFAULTS.TOOL_CALLING
    local has_exit_schema = config.arena.exit_schema ~= nil

    if tool_calling == agent_consts.TOOL_CALLING.AUTO and has_exit_schema then
        config.arena.tool_calling = tool_calling
    end

    if tool_calling == agent_consts.TOOL_CALLING.ANY and not has_exit_schema then
        return nil, "any mode requires exit_schema to be defined"
    end

    if tool_calling == agent_consts.TOOL_CALLING.NONE and has_exit_schema then
        return nil, "none mode cannot have exit_schema"
    end

    return config, nil
end

local function setup_exit_tool(agent_ctx, arena_config)
    local exit_tool_name = nil
    local should_add_exit_tool = (arena_config.tool_calling == agent_consts.TOOL_CALLING.ANY) or
        (arena_config.tool_calling == agent_consts.TOOL_CALLING.AUTO and arena_config.exit_schema)

    if should_add_exit_tool then
        exit_tool_name = "finish"

        local exit_schema = arena_config.exit_schema or {
            type = "object",
            properties = {
                answer = {
                    type = "string",
                    description = "Your final answer to complete the task"
                }
            },
            required = { "answer" }
        }

        agent_ctx:add_tools({
            {
                id = exit_tool_name,
                name = exit_tool_name,
                description = "Call this tool when you have completed the task and want to provide your final answer",
                schema = exit_schema
            }
        })
    end

    if arena_config.tools and #arena_config.tools > 0 then
        agent_ctx:add_tools(arena_config.tools)
    end

    return exit_tool_name
end

local function accumulate_tokens(total_tokens, new_tokens)
    if not new_tokens then
        return total_tokens
    end

    total_tokens.total_tokens = (total_tokens.total_tokens or 0) + (new_tokens.total_tokens or 0)
    total_tokens.prompt_tokens = (total_tokens.prompt_tokens or 0) + (new_tokens.prompt_tokens or 0)
    total_tokens.completion_tokens = (total_tokens.completion_tokens or 0) + (new_tokens.completion_tokens or 0)
    total_tokens.cache_read_tokens = (total_tokens.cache_read_tokens or 0) + (new_tokens.cache_read_tokens or 0)
    total_tokens.cache_write_tokens = (total_tokens.cache_write_tokens or 0) + (new_tokens.cache_write_tokens or 0)
    total_tokens.thinking_tokens = (total_tokens.thinking_tokens or 0) + (new_tokens.thinking_tokens or 0)

    return total_tokens
end

local function update_node_progress(n, iteration, max_iterations, total_tokens, tool_calls_count, status_message,
                                    agent_id, model_name)
    local state_info = {
        current_iteration = iteration,
        max_iterations = max_iterations,
        agent_id = agent_id,
        model = model_name,
        total_tokens = total_tokens,
        tool_calls = tool_calls_count
    }

    n:metadata({
        status_message = status_message,
        state = state_info
    })
end

local function store_agent_action(n, agent_result, iteration, agent_id, model_name, exit_tool_name)
    -- Store EXACTLY what agent returned - no merging/unmerging
    local action_content = {
        result = agent_result.result,
        tool_calls = agent_result.tool_calls,  -- Regular tools only (agent already separated)
        delegate_calls = agent_result.delegate_calls  -- Delegations only (agent already separated)
    }

    local is_exit_action = false
    if exit_tool_name and agent_result.tool_calls then
        for _, tool_call in ipairs(agent_result.tool_calls) do
            if tool_call.name == exit_tool_name then
                is_exit_action = true
                break
            end
        end
    end

    local action_key = is_exit_action and (iteration .. "_final") or (iteration .. "_action")

    n:data(agent_consts.DATA_TYPE.AGENT_ACTION, action_content, {
        key = action_key,
        content_type = "application/json",
        node_id = n.node_id,
        metadata = {
            iteration = iteration,
            agent_id = agent_id,
            model = model_name,
            tokens = agent_result.tokens,
            finish_reason = agent_result.finish_reason,
            llm_meta = agent_result.metadata or {},
        }
    })
end

local function store_memory_recall(n, agent_result, iteration)
    if not agent_result.memory_prompt then
        return
    end

    n:data(agent_consts.DATA_TYPE.AGENT_MEMORY, agent_result.memory_prompt.content, {
        key = iteration .. "_memory",
        content_type = "text/plain",
        node_id = n.node_id,
        metadata = {
            iteration = iteration,
            memory_ids = agent_result.memory_prompt.metadata and agent_result.memory_prompt.metadata.memory_ids,
            llm_meta = agent_result.memory_prompt.metadata or {}
        }
    })
end

local function get_tool_title_by_registry_id(registry_id, tool_name)
    if not registry_id then
        return tool_name
    end

    local tool_schema = tools.get_tool_schema(registry_id)
    if tool_schema and tool_schema.title then
        return tool_schema.title
    end

    return tool_name
end

local function create_tool_viz_nodes(n, tool_calls, iteration, show_tool_calls, exit_tool_name)
    local tool_call_to_node_id = {}

    if show_tool_calls == false or not tool_calls or #tool_calls == 0 then
        return tool_call_to_node_id
    end

    for _, tool_call in ipairs(tool_calls) do
        if exit_tool_name and tool_call.name == exit_tool_name then
            goto continue
        end

        local viz_node_id = uuid.v7()
        tool_call_to_node_id[tool_call.id] = viz_node_id

        local input_size = 0
        if tool_call.arguments then
            local args_json = json.encode(tool_call.arguments)
            input_size = string.len(args_json)
        end

        local tool_title = get_tool_title_by_registry_id(tool_call.registry_id, tool_call.name)

        local metadata = {
            tool_name = tool_call.name,
            tool_call_id = tool_call.id,
            iteration = iteration,
            title = tool_title,
            input_size_bytes = input_size
        }

        if tool_call.registry_id then
            metadata.registry_id = tool_call.registry_id
        end

        n:command({
            type = "CREATE_NODE",
            payload = {
                node_id = viz_node_id,
                node_type = "tool.call",
                parent_node_id = n.node_id,
                status = "running",
                config = {},
                metadata = metadata
            }
        })

        ::continue::
    end

    return tool_call_to_node_id
end

local function update_tool_viz_nodes(n, tool_results, tool_call_to_node_id)
    if not tool_results or not tool_call_to_node_id then
        return
    end

    for call_id, result_data in pairs(tool_results) do
        local viz_node_id = tool_call_to_node_id[call_id]
        if viz_node_id then
            local tool_result = result_data.result
            local tool_error = result_data.error

            local output_size = 0
            local output_content = tool_result or tool_error
            if output_content then
                local output_json = type(output_content) == "table" and json.encode(output_content) or
                tostring(output_content)
                output_size = string.len(output_json)
            end

            local final_status = tool_error and "failed" or "completed"

            n:command({
                type = "UPDATE_NODE",
                payload = {
                    node_id = viz_node_id,
                    status = final_status,
                    metadata = {
                        has_error = tool_error ~= nil,
                        error_message = tool_error,
                        output_size_bytes = output_size
                    }
                }
            })
        end
    end
end

local function execute_tools(agent_result, caller, session_context)
    if not agent_result.tool_calls or #agent_result.tool_calls == 0 then
        return {}
    end

    local validated_tools, validate_err = caller:validate(agent_result.tool_calls)
    if validate_err then
        return {}
    end

    local tool_results = caller:execute(session_context or {}, validated_tools)
    return tool_results or {}
end

local function process_tool_results(n, tool_results, iteration, exit_tool_name, agent_result)
    local control_responses = {}
    local task_complete = false
    local final_result = nil

    if exit_tool_name and agent_result.tool_calls then
        for _, original_tool_call in ipairs(agent_result.tool_calls) do
            if original_tool_call.name == exit_tool_name then
                task_complete = true
                if original_tool_call.arguments and next(original_tool_call.arguments) then
                    final_result = original_tool_call.arguments
                else
                    final_result = { success = false, error = "Exit tool called without arguments" }
                end
                break
            end
        end
    end

    if task_complete then
        return control_responses, task_complete, final_result
    end

    if agent_result.tool_calls then
        for _, tool_call in ipairs(agent_result.tool_calls) do
            local call_id = tool_call.id
            local result_data = tool_results[call_id]

            if result_data then
                local tool_result = result_data.result
                local tool_error = result_data.error

                local cleaned_result, control_response = control_handler.process_control_directive(
                    tool_result, n, iteration
                )
                if control_response then
                    table.insert(control_responses, control_response)
                end

                local obs_content = cleaned_result or tool_error
                if obs_content == nil then
                    obs_content = "nil"
                end

                local tool_key = iteration .. "_" .. tool_call.name

                n:data(agent_consts.DATA_TYPE.AGENT_OBSERVATION, obs_content, {
                    key = tool_key,
                    content_type = type(obs_content) == "table" and "application/json" or "text/plain",
                    node_id = n.node_id,
                    metadata = {
                        iteration = iteration,
                        tool_call_id = call_id,
                        tool_name = tool_call.name,
                        is_error = tool_error ~= nil
                    }
                })
            end
        end
    end

    return control_responses, task_complete, final_result
end

local function tools_were_attempted(agent_result)
    if agent_result.tool_calls and #agent_result.tool_calls > 0 then
        return true
    end

    if agent_result.delegate_calls and #agent_result.delegate_calls > 0 then
        return true
    end

    return false
end

local function check_completion(tool_calling, agent_result, iteration, min_iterations, exit_tool_name, n)
    local task_complete = false
    local final_result = nil

    if iteration < min_iterations then
        return task_complete, final_result
    end

    if tool_calling == agent_consts.TOOL_CALLING.NONE then
        if agent_result.result and agent_result.result ~= "" then
            task_complete = true
            final_result = agent_result.result
        end
    elseif tool_calling == agent_consts.TOOL_CALLING.AUTO then
        if not tools_were_attempted(agent_result) then
            if agent_result.result and agent_result.result ~= nil then
                task_complete = true
                final_result = agent_result.result
            else
                local feedback = agent_consts.FEEDBACK.NO_TOOLS_CALLED
                n:data(agent_consts.DATA_TYPE.AGENT_OBSERVATION, feedback, {
                    key = iteration .. "_no_tools_called",
                    content_type = "text/plain",
                    node_id = n.node_id,
                    metadata = {
                        iteration = iteration
                    }
                })
            end
        end
    elseif tool_calling == agent_consts.TOOL_CALLING.ANY then
        if not tools_were_attempted(agent_result) then
            local feedback = agent_consts.FEEDBACK.NO_TOOLS_CALLED
            if exit_tool_name then
                feedback = feedback .. " " .. string.format(agent_consts.FEEDBACK.EXIT_AVAILABLE, exit_tool_name)
            end
            n:data(agent_consts.DATA_TYPE.AGENT_OBSERVATION, feedback, {
                key = iteration .. "_no_tools_called",
                content_type = "text/plain",
                node_id = n.node_id,
                metadata = {
                    iteration = iteration
                }
            })
        end
    end

    return task_complete, final_result
end

local function get_delegation_data_id(n)
    local reader = n:query()
        :with_nodes(n.node_id)
        :with_data_types(agent_consts.DATA_TYPE.AGENT_DELEGATION)

    local delegation_data = reader:all()
    if delegation_data and #delegation_data > 0 then
        return delegation_data[#delegation_data].data_id
    end

    return nil
end

local function run(args)
    local n, err = node_sdk.new(args)
    if err then
        error(err)
    end

    local config = n:config()
    local validated_config, config_err = validate_and_resolve_config(config)
    if config_err then
        return n:fail({
            code = agent_consts.ERROR.INVALID_CONFIG,
            message = config_err
        }, config_err)
    end

    local inputs = n:inputs()
    local input_context, agent_id_override, input_data, input_err = process_multiple_inputs(inputs, config.inputs)
    if input_err then
        return n:fail({
            code = agent_consts.ERROR.INPUT_VALIDATION_FAILED,
            message = input_err
        }, input_err)
    end


    local arena_context = config.arena.context or {}
    local session_context = {}
    for k, v in pairs(arena_context) do
        session_context[k] = v
    end

    local base_context = {
        enable_cache = false,
        delegate_tools = {
            enabled = agent_consts.DELEGATE_DEFAULTS.GENERATE_TOOL_SCHEMAS,
            description_suffix = agent_consts.DELEGATE_DEFAULTS.DESCRIPTION_SUFFIX,
            default_schema = agent_consts.DELEGATE_DEFAULTS.SCHEMA
        }
    }
    local merged_context = merge_contexts(base_context, input_context)
    local agent_ctx = agent_context.new(merged_context)

    local exit_tool_name = setup_exit_tool(agent_ctx, config.arena)

    local agent_to_load = agent_id_override or config.agent
    local agent_instance, agent_err = agent_ctx:load_agent(agent_to_load)
    if not agent_instance then
        return n:fail({
            code = agent_consts.ERROR.AGENT_LOAD_FAILED,
            message = string.format(agent_consts.ERROR_MSG.AGENT_LOAD_FAILED, agent_err or "unknown error")
        }, string.format(agent_consts.ERROR_MSG.AGENT_LOAD_FAILED, agent_err or "unknown error"))
    end

    local agent_config = agent_ctx:get_config()
    local agent_id = agent_config.current_agent_id or
    (type(agent_to_load) == "table" and agent_to_load.id or agent_to_load)
    local model_name = agent_config.current_model or "unknown"

    local builder, builder_err = prompt_builder.new(n.dataflow_id, n.node_id, n.path)
    if builder_err then
        return n:fail({
            code = agent_consts.ERROR.PROMPT_BUILD_FAILED,
            message = builder_err
        }, builder_err)
    end

    builder:with_arena_config(config.arena):with_initial_input(input_data)
    local caller = tool_caller.new()

    local iteration = 0
    local max_iterations = config.arena.max_iterations or agent_consts.DEFAULTS.MAX_ITERATIONS
    local min_iterations = config.arena.min_iterations or agent_consts.DEFAULTS.MIN_ITERATIONS
    local tool_calling = config.arena.tool_calling
    local show_tool_calls = config.show_tool_calls ~= false
    local task_complete = false
    local final_result = nil

    local total_tokens = {
        total_tokens = 0,
        prompt_tokens = 0,
        completion_tokens = 0,
        cache_read_tokens = 0,
        cache_write_tokens = 0,
        thinking_tokens = 0
    }
    local tool_calls_count = 0

    local initial_status = build_status_message(0, max_iterations, total_tokens, tool_calls_count, false, false)
    update_node_progress(n, 0, max_iterations, total_tokens, tool_calls_count, initial_status, agent_id, model_name)

    while iteration < max_iterations and not task_complete do
        iteration = iteration + 1

        local prompt, prompt_err = builder:build_prompt(config.arena.prompt)
        if prompt_err then
            return n:fail({
                code = agent_consts.ERROR.PROMPT_BUILD_FAILED,
                message = prompt_err
            }, prompt_err)
        end

        local step_options = { tool_call = tool_calling, context = session_context }
        local agent_result, step_err = agent_instance:step(prompt, step_options)
        if step_err then
            return n:fail({
                code = agent_consts.ERROR.AGENT_EXEC_FAILED,
                message = step_err
            }, step_err)
        end

        -- Agent already separated - trust the separation!
        local regular_tool_calls = agent_result.tool_calls or {}
        local delegate_calls = agent_result.delegate_calls or {}

        -- Count regular tools for status
        for _, tool_call in ipairs(regular_tool_calls) do
            if not exit_tool_name or tool_call.name ~= exit_tool_name then
                tool_calls_count = tool_calls_count + 1
            end
        end

        total_tokens = accumulate_tokens(total_tokens, agent_result.tokens)

        local status_msg = build_status_message(iteration, max_iterations, total_tokens, tool_calls_count, false, false)
        update_node_progress(n, iteration, max_iterations, total_tokens, tool_calls_count, status_msg, agent_id,
            model_name)

        store_memory_recall(n, agent_result, iteration)

        -- Store action with clean separation (no merging!)
        store_agent_action(n, agent_result, iteration, agent_id, model_name, exit_tool_name)

        -- Create viz nodes for regular tools only
        local tool_call_to_node_id = create_tool_viz_nodes(n, regular_tool_calls, iteration, show_tool_calls,
            exit_tool_name)

        local tool_results = execute_tools({ tool_calls = regular_tool_calls }, caller, session_context)

        if show_tool_calls then
            update_tool_viz_nodes(n, tool_results, tool_call_to_node_id)
        end

        -- Process results from regular tools only
        local control_responses, tool_complete, tool_result = process_tool_results(n, tool_results, iteration,
            exit_tool_name, { tool_calls = regular_tool_calls })

        local remaining_iterations = max_iterations - iteration
        if remaining_iterations == 2 then
            local warning_msg = string.format(agent_consts.FEEDBACK.ITERATIONS_WARNING, remaining_iterations)
            n:data(agent_consts.DATA_TYPE.AGENT_OBSERVATION, warning_msg, {
                key = iteration .. "_iterations_warning",
                content_type = "text/plain",
                node_id = n.node_id,
                metadata = {
                    iteration = iteration,
                    remaining_iterations = remaining_iterations
                }
            })
        elseif remaining_iterations == 1 then
            local warning_msg = agent_consts.FEEDBACK.FINAL_ITERATION
            n:data(agent_consts.DATA_TYPE.AGENT_OBSERVATION, warning_msg, {
                key = iteration .. "_final_warning",
                content_type = "text/plain",
                node_id = n.node_id,
                metadata = {
                    iteration = iteration,
                    remaining_iterations = remaining_iterations
                }
            })
        elseif remaining_iterations == 0 then
            local warning_msg = agent_consts.FEEDBACK.CRITICAL_FINAL
            n:data(agent_consts.DATA_TYPE.AGENT_OBSERVATION, warning_msg, {
                key = iteration .. "_critical_warning",
                content_type = "text/plain",
                node_id = n.node_id,
                metadata = {
                    iteration = iteration,
                    remaining_iterations = remaining_iterations
                }
            })
        end

        n:yield()

        if tool_complete then
            task_complete = true
            final_result = tool_result
        end

        local has_delegations = #delegate_calls > 0

        -- Handle delegations - separate processing
        if has_delegations then
            -- Apply control changes first
            if #control_responses > 0 then
                local changes_summary, changes_err = control_handler.apply_control_responses(control_responses, agent_ctx, n)
                if changes_err then
                    return n:fail({
                        code = agent_consts.ERROR.STEP_FUNCTION_FAILED,
                        message = changes_err
                    }, changes_err)
                end
            end

            -- Process delegations (only agent delegations now)
            local delegation_infos = delegation_handler.create_delegation_batch(
                { delegate_calls = delegate_calls },
                n,
                session_context
            )

            local delegation_results, delegation_err = delegation_handler.execute_delegation_batch(delegation_infos, n)
            if delegation_err then
                return n:fail({
                    code = agent_consts.ERROR.DELEGATION_FAILED,
                    message = delegation_err
                }, delegation_err)
            end

            delegation_handler.map_delegation_results_to_conversation(delegation_results, n, iteration)
            n:yield()
        elseif #control_responses > 0 then
            -- Apply control changes without delegations
            local changes_summary, changes_err = control_handler.apply_control_responses(control_responses, agent_ctx, n)
            if changes_err then
                return n:fail({
                    code = agent_consts.ERROR.STEP_FUNCTION_FAILED,
                    message = changes_err
                }, changes_err)
            end
        end

        if not task_complete and not has_delegations then
            task_complete, final_result = check_completion(tool_calling, agent_result, iteration, min_iterations,
                exit_tool_name, n)
        end
    end

    if not task_complete and iteration >= max_iterations then
        local final_status = build_status_message(iteration, max_iterations, total_tokens, tool_calls_count, true, false)
        update_node_progress(n, iteration, max_iterations, total_tokens, tool_calls_count, final_status, agent_id, model_name)

        return n:fail({
            code = agent_consts.ERROR.AGENT_EXEC_FAILED,
            message = "Maximum iterations reached without completion"
        }, "Maximum iterations reached")
    end

    local final_status = build_status_message(iteration, max_iterations, total_tokens, tool_calls_count, true,
        task_complete)
    update_node_progress(n, iteration, max_iterations, total_tokens, tool_calls_count, final_status, agent_id, model_name)

    local output_content = final_result or { success = false, error = "No result produced" }
    local success = final_result and final_result.success ~= false
    local message = success and agent_consts.STATUS.COMPLETED_SUCCESS or
        (final_result and final_result.error and (agent_consts.STATUS.COMPLETED_ERROR .. final_result.error) or "Agent execution failed")

    local delegation_data_id = get_delegation_data_id(n)
    if delegation_data_id then
        n:metadata({
            delegation_output_data_id = delegation_data_id
        })
    end

    return n:complete(output_content, message)
end

return { run = run }