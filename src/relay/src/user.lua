local time = require("time")
local json = require("json")
local consts = require("consts")

local logger = require("logger"):named("relay.user")

local function run(args)
    if not args or not args.user_id or not args.plugins or not args.config then
        error("Missing required arguments: user_id, plugins, config")
    end

    local state = {
        user_id = args.user_id,
        user_metadata = args.user_metadata or {},
        plugins = args.plugins,
        config = args.config,
        central_hub_pid = args.central_hub_pid,
        active_plugins = {},
        connected_clients = {},
        client_count = 0
    }

    local registry_name = consts.USER_HUB_REGISTRY_PREFIX .. state.user_id
    process.registry.register(registry_name)
    process.set_options({ trap_links = true })

    for prefix, plugin_config in pairs(state.plugins) do
        if plugin_config.auto_start then
            spawn_plugin(state, prefix, plugin_config)
        end
    end

    local inbox = process.inbox()
    local events = process.events()

    while true do
        local result = channel.select({
            inbox:case_receive(),
            events:case_receive()
        })

        if not result.ok then
            break
        end

        if result.channel == inbox then
            local msg = result.value
            local topic = msg:topic()
            local payload = msg:payload()
            local from_pid = msg:from()

            if topic == consts.WS_TOPICS.JOIN then
                handle_client_join(state, payload:data())
            elseif topic == consts.WS_TOPICS.LEAVE then
                handle_client_leave(state, payload:data())
            elseif topic == consts.WS_TOPICS.MESSAGE then
                handle_client_message(state, payload, from_pid)
            elseif topic == consts.WS_TOPICS.CANCEL then
                logger:info("received cancel signal")
                break
            else
                broadcast_to_clients(state, topic, payload:data())
            end
        elseif result.channel == events then
            local event = result.value
            if event.kind == process.event.CANCEL then
                break
            else
                handle_process_event(state, event)
            end
        end
    end

    for prefix, plugin_state in pairs(state.active_plugins) do
        if plugin_state.pid then
            process.cancel(plugin_state.pid, consts.CANCEL_TIMEOUT)
        end
    end

    return { status = "shutdown", user_id = state.user_id }
end

function handle_client_join(state, payload_data)
    local client_pid = payload_data.client_pid
    if client_pid then
        state.connected_clients[client_pid] = true
        state.client_count = state.client_count + 1

        logger:info("client connected", {
            client_pid = client_pid,
            client_count = state.client_count,
            user_id = state.user_id
        })

        -- If this is the first client after being at 0, notify session plugin to cancel shutdown
        if state.client_count == 1 then
            local session_plugin = state.active_plugins["session_"]
            if session_plugin and session_plugin.pid then
                process.send(session_plugin.pid, "resume", {})
            end
        end

        process.send(client_pid, consts.CLIENT_TOPICS.WELCOME, {
            user_id = state.user_id,
            client_count = state.client_count,
            plugins = get_plugin_info(state)
        })

        notify_central_hub_activity(state)
    end
end

function handle_client_leave(state, payload_data)
    local client_pid = payload_data.client_pid
    if client_pid and state.connected_clients[client_pid] then
        state.connected_clients[client_pid] = nil
        state.client_count = state.client_count - 1

        logger:info("client disconnected", {
            client_pid = client_pid,
            client_count = state.client_count,
            user_id = state.user_id
        })

        -- If this was the last client, notify session plugin to shutdown
        if state.client_count == 0 then
            local session_plugin = state.active_plugins["session_"]
            if session_plugin and session_plugin.pid then
                process.send(session_plugin.pid, "shutdown", {})
            end
        end

        notify_central_hub_activity(state)
    end
end

function handle_client_message(state, payload, from_pid)
    local message_data, err = json.decode(payload:data())
    if not message_data then
        process.send(from_pid, consts.CLIENT_TOPICS.ERROR, {
            error = consts.ERROR_CODES.INVALID_JSON,
            message = "Failed to decode JSON message"
        })
        return
    end

    local msg_type = message_data.type
    if not msg_type then
        process.send(from_pid, consts.CLIENT_TOPICS.ERROR, {
            error = consts.ERROR_CODES.UNKNOWN_COMMAND,
            message = "Message type is required"
        })
        return
    end

    local plugin_prefix, plugin_config = find_plugin_for_command(state, msg_type)
    if not plugin_prefix then
        process.send(from_pid, consts.CLIENT_TOPICS.ERROR, {
            error = consts.ERROR_CODES.PLUGIN_NOT_FOUND,
            message = "No plugin found for command: " .. msg_type
        })
        return
    end

    local stripped_topic = msg_type:sub(#plugin_prefix + 1)
    -- Pass the parsed message_data and from_pid instead of raw payload
    local success, route_err = route_to_plugin(state, plugin_prefix, plugin_config, stripped_topic, message_data, from_pid)
    if not success then
        process.send(from_pid, consts.CLIENT_TOPICS.ERROR, {
            error = consts.ERROR_CODES.PLUGIN_FAILED,
            message = route_err or "Failed to route message to plugin"
        })
    end
end

function find_plugin_for_command(state, command)
    for prefix, plugin_config in pairs(state.plugins) do
        if command:sub(1, #prefix) == prefix then
            return prefix, plugin_config
        end
    end
    return nil, nil
end

function route_to_plugin(state, prefix, plugin_config, topic, message_data, from_pid)
    local plugin_state = state.active_plugins[prefix]

    if plugin_state and plugin_state.status == "failed" then
        return false, "Plugin " .. prefix .. " has failed permanently"
    end

    if not plugin_state or not plugin_state.pid then
        local success, err = spawn_plugin(state, prefix, plugin_config)
        if not success then
            return false, err
        end
        plugin_state = state.active_plugins[prefix]
    end

    if plugin_state and plugin_state.pid then
        -- Create payload data with conn_pid included
        local payload_data = {
            conn_pid = from_pid,
            request_id = message_data.request_id,
            session_id = message_data.session_id,
            type = message_data.type,
            data = message_data.data,
            start_token = message_data.start_token,
            context = message_data.context
        }

        process.send(plugin_state.pid, topic, payload_data)
        return true
    end

    return false, "Plugin not available"
end

function spawn_plugin(state, prefix, plugin_config)
    if not state.active_plugins[prefix] then
        state.active_plugins[prefix] = {
            pid = nil,
            restart_count = 0,
            status = "pending"
        }
    end

    local plugin_state = state.active_plugins[prefix]

    if plugin_state.status == "failed" then
        return false, "Plugin " .. prefix .. " has failed permanently"
    end

    local plugin_pid, err = process.spawn_linked_monitored(
        plugin_config.process_id,
        plugin_config.host,
        {
            user_id = state.user_id,
            user_metadata = state.user_metadata,
            user_hub_pid = process.pid(),
            config = state.config
        }
    )

    if not plugin_pid then
        plugin_state.status = "failed"
        return false, "Failed to spawn plugin process: " .. (err or "unknown error")
    end

    plugin_state.pid = plugin_pid
    plugin_state.status = "running"

    logger:info("plugin spawned", { user_id = state.user_id, prefix = prefix, pid = plugin_pid })

    return true
end

function handle_process_event(state, event)
    if event.kind ~= process.event.EXIT and event.kind ~= process.event.LINK_DOWN then
        return
    end

    local from_pid = event.from
    local plugin_prefix = nil
    local plugin_state = nil

    for prefix, pstate in pairs(state.active_plugins) do
        if pstate.pid == from_pid then
            plugin_prefix = prefix
            plugin_state = pstate
            break
        end
    end

    if not plugin_prefix then
        return
    end

    plugin_state.pid = nil

    local was_crash = false
    if event.kind == process.event.LINK_DOWN then
        was_crash = true
    elseif event.kind == process.event.EXIT then
        if event.result and event.result.error then
            was_crash = true
        end
    end

    if not was_crash then
        plugin_state.status = "stopped"
        logger:info("plugin stopped", { user_id = state.user_id, prefix = plugin_prefix })
        return
    end

    if plugin_state.restart_count >= consts.MAX_PLUGIN_RESTARTS then
        plugin_state.status = "failed"
        logger:error("plugin failed permanently", { user_id = state.user_id, prefix = plugin_prefix, restart_count = plugin_state.restart_count })
        return
    end

    plugin_state.restart_count = plugin_state.restart_count + 1
    logger:warn("plugin crashed, restarting", { user_id = state.user_id, prefix = plugin_prefix, restart_count = plugin_state.restart_count })

    local plugin_config = state.plugins[plugin_prefix]
    spawn_plugin(state, plugin_prefix, plugin_config)
end

function get_plugin_info(state)
    local info = {}
    for prefix, plugin_config in pairs(state.plugins) do
        local plugin_state = state.active_plugins[prefix]
        info[prefix] = {
            prefix = prefix,
            process_id = plugin_config.process_id,
            status = plugin_state and plugin_state.status or "not_started"
        }
    end
    return info
end

function broadcast_to_clients(state, topic, message)
    for client_pid, _ in pairs(state.connected_clients) do
        process.send(client_pid, topic, message)
    end
end

function notify_central_hub_activity(state)
    if state.central_hub_pid then
        process.send(state.central_hub_pid, consts.HUB_TOPICS.ACTIVITY_UPDATE, {
            user_id = state.user_id,
            client_count = state.client_count,
            last_activity = time.now():format_rfc3339()
        })
    end
end

return { run = run }