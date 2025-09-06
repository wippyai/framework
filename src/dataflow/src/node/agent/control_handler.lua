local json = require("json")
local uuid = require("uuid")
local agent_consts = require("agent_consts")
local data_reader = require("data_reader")

local control_handler = {}

-- Process session context changes
function control_handler.process_session_context(control, node_sdk)
    if not control.context or not control.context.session then
        return {}
    end

    local changes = {}
    local current_metadata = {} -- Should get from node_sdk metadata

    if control.context.session.set then
        for k, v in pairs(control.context.session.set) do
            current_metadata[k] = v
            changes[k] = { action = "set", value = v }
        end
    end

    if control.context.session.delete then
        for _, k in ipairs(control.context.session.delete) do
            current_metadata[k] = nil
            changes[k] = { action = "delete" }
        end
    end

    if next(changes) then
        node_sdk:metadata({ session_context = current_metadata })
        return { session_context = changes }
    end

    return {}
end

-- Process public metadata changes
function control_handler.process_public_metadata(control, node_sdk)
    if not control.context or not control.context.public_meta then
        return {}
    end

    local changes = {}
    local current_public_meta = {} -- Should get from node_sdk metadata

    if control.context.public_meta.clear then
        for id, item in pairs(current_public_meta) do
            if item.type == control.context.public_meta.clear then
                current_public_meta[id] = nil
            end
        end
        changes.clear = control.context.public_meta.clear
    end

    if control.context.public_meta.set then
        changes.set = control.context.public_meta.set
        if type(control.context.public_meta.set) == "table" and #control.context.public_meta.set > 0 then
            for _, item in ipairs(control.context.public_meta.set) do
                if item.id then
                    current_public_meta[item.id] = item
                end
            end
        else
            for key, value in pairs(control.context.public_meta.set) do
                current_public_meta[key] = value
            end
        end
    end

    if control.context.public_meta.delete then
        changes.delete = control.context.public_meta.delete
        for _, id in ipairs(control.context.public_meta.delete) do
            current_public_meta[id] = nil
        end
    end

    if next(changes) then
        node_sdk:metadata({ public_meta = current_public_meta })
        return { public_meta = changes }
    end

    return {}
end

-- Process memory operations
function control_handler.process_memory_operations(control, node_sdk, iteration)
    if not control.memory then
        return {}
    end

    local memory_changes = {}

    if control.memory.add then
        for _, memory_item in ipairs(control.memory.add) do
            if memory_item.type and memory_item.text then
                node_sdk:data(agent_consts.DATA_TYPE.AGENT_MEMORY, memory_item.text, {
                    key = memory_item.type .. "_" .. iteration,
                    metadata = {
                        memory_type = memory_item.type,
                        created_by_control = true,
                        iteration = iteration
                    }
                })
                table.insert(memory_changes, {
                    action = "add",
                    type = memory_item.type,
                    text_length = #memory_item.text
                })
            end
        end
    end

    if control.memory.clear then
        table.insert(memory_changes, {
            action = "clear",
            type = control.memory.clear
        })
    end

    if control.memory.delete then
        for _, memory_id in ipairs(control.memory.delete) do
            table.insert(memory_changes, {
                action = "delete",
                memory_id = memory_id
            })
        end
    end

    return memory_changes
end

-- Process artifact creation
function control_handler.process_artifacts(control, node_sdk, iteration)
    if not control.artifacts then
        return {}
    end

    local artifact_changes = {}

    for _, artifact in ipairs(control.artifacts) do
        if artifact.content then
            local content_type = artifact.content_type or "text/plain"
            local artifact_id = uuid.v7()
            local title = artifact.title or "Untitled"

            node_sdk:data("workflow.artifact", artifact.content, {
                data_id = artifact_id,
                key = title,
                content_type = content_type,
                metadata = {
                    title = title,
                    comment = artifact.description,
                    artifact_type = artifact.type or "inline",
                    created_in_control = true,
                    iteration = iteration
                }
            })

            table.insert(artifact_changes, {
                artifact_id = artifact_id,
                title = title,
                type = artifact.type or "inline"
            })
        end
    end

    return artifact_changes
end

-- Process direct commands
function control_handler.process_commands(control, node_sdk)
    if not control.commands then
        return {}
    end

    local command_changes = {}

    for _, cmd in ipairs(control.commands) do
        if cmd.type and cmd.payload then
            node_sdk:command(cmd)
            table.insert(command_changes, {
                type = cmd.type,
                payload_summary = control_handler._summarize_command_payload(cmd.payload)
            })
        end
    end

    return command_changes
end

-- Create summary of command payload for logging
function control_handler._summarize_command_payload(payload)
    local summary = {
        type = payload.type or "unknown"
    }

    if payload.node_id then
        summary.node_id = payload.node_id
    end

    if payload.data_type then
        summary.data_type = payload.data_type
    end

    if payload.key then
        summary.key = payload.key
    end

    if payload.content then
        local content_type = type(payload.content)
        if content_type == "string" then
            summary.content_length = #payload.content
        elseif content_type == "table" then
            summary.content_type = "table"
        else
            summary.content_type = content_type
        end
    end

    return summary
end

-- Process a single control directive from tool result
-- Returns: cleaned_result, control_response
function control_handler.process_control_directive(tool_result, node_sdk, iteration)
    if type(tool_result) ~= "table" or not tool_result._control then
        return tool_result, nil
    end

    local control = tool_result._control
    local control_response = {
        agent_change = nil,
        model_change = nil,
        yield = nil,
        changes_applied = {}
    }

    -- Process session context changes
    local session_changes = control_handler.process_session_context(control, node_sdk)
    if next(session_changes) then
        control_response.changes_applied.session_context = session_changes
    end

    -- Process public metadata changes
    local metadata_changes = control_handler.process_public_metadata(control, node_sdk)
    if next(metadata_changes) then
        control_response.changes_applied.public_meta = metadata_changes
    end

    -- Process memory operations
    local memory_changes = control_handler.process_memory_operations(control, node_sdk, iteration)
    if #memory_changes > 0 then
        control_response.changes_applied.memory = memory_changes
    end

    -- Process artifact creation
    local artifact_changes = control_handler.process_artifacts(control, node_sdk, iteration)
    if #artifact_changes > 0 then
        control_response.changes_applied.artifacts = artifact_changes
    end

    -- Process direct commands
    local command_changes = control_handler.process_commands(control, node_sdk)
    if #command_changes > 0 then
        control_response.changes_applied.commands = command_changes
    end

    -- Handle configuration changes (agent/model)
    if control.config then
        if control.config.agent then
            control_response.agent_change = control.config.agent
        end

        if control.config.model then
            control_response.model_change = control.config.model
        end
    end

    -- Handle yield requests
    if control.yield then
        control_response.yield = control.yield

        -- Queue yield commands if any
        if control.yield.commands then
            for _, cmd in ipairs(control.yield.commands) do
                if cmd.type and cmd.payload then
                    node_sdk:command(cmd)
                end
            end
        end
    end

    -- Remove _control from tool result
    tool_result._control = nil

    return tool_result, control_response
end

-- Apply collected control responses to agent context and node state
-- Returns: changes_summary, error
function control_handler.apply_control_responses(control_responses, agent_context, node_sdk)
    local changes_summary = {
        agent_changed = false,
        model_changed = false,
        yielded = false,
        errors = {}
    }

    for _, response in ipairs(control_responses) do
        -- Handle agent changes
        if response.agent_change then
            local success, err = agent_context:switch_to_agent(response.agent_change)
            if success then
                changes_summary.agent_changed = true
                changes_summary.new_agent = response.agent_change
            else
                table.insert(changes_summary.errors,
                    string.format("Failed to change agent: %s", err or "unknown error"))
            end
        end

        -- Handle model changes
        if response.model_change then
            local success, err = agent_context:switch_to_model(response.model_change)
            if success then
                changes_summary.model_changed = true
                changes_summary.new_model = response.model_change
            else
                table.insert(changes_summary.errors,
                    string.format("Failed to change model: %s", err or "unknown error"))
            end
        end

        -- Handle yield requests
        if response.yield then
            local yield_options = {}

            if response.yield.user_context and response.yield.user_context.run_node_ids then
                yield_options.run_nodes = response.yield.user_context.run_node_ids
            end

            local yield_result, yield_err = node_sdk:yield(yield_options)
            if yield_result then
                changes_summary.yielded = true
                changes_summary.yield_result = yield_result
            else
                table.insert(changes_summary.errors,
                    string.format("Failed to yield: %s", yield_err or "unknown error"))
            end
        end
    end

    return changes_summary, (#changes_summary.errors > 0) and table.concat(changes_summary.errors, "; ") or nil
end

return control_handler