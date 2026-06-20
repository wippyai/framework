local time = require("time")
local json = require("json")
local pg = require("pg")
local consts = require("consts")

local logger = require("logger"):named("relay.user")

type PluginConfig = {
    prefix: string,
    process_id: string,
    host: string?,
    auto_start: boolean,
}

type PluginState = {
    pid: string?,
    restart_count: number,
    status: string,
}

type UserState = {
    user_id: string,
    user_metadata: any,
    plugins: {[string]: PluginConfig},
    config: any,
    central_hub_pid: string?,
    active_plugins: {[string]: PluginState},
    connected_clients: {[string]: boolean},
    client_count: number,
    pg_scopes: {[string]: any},
    pg_groups: {[string]: string},
}

local function get_plugin_info(state: UserState): any
    local count = 0
    for _ in pairs(state.plugins) do count = count + 1 end
    local info = table.create(count, 0)
    for prefix, plugin_config in pairs(state.plugins) do
        local plugin_state = state.active_plugins[prefix]
        table.insert(info, {
            prefix = prefix,
            process_id = plugin_config.process_id,
            status = plugin_state and plugin_state.status or "not_started"
        })
    end
    return info
end

local function broadcast_to_clients(state: UserState, topic: string, message: any)
    logger:info("broadcasting topic to clients", {
        user_id = state.user_id,
        topic = topic,
        client_count = state.client_count
    })
    for client_pid, _ in pairs(state.connected_clients) do
        logger:info("broadcasting topic to client", {
            user_id = state.user_id,
            topic = topic,
            client_pid = client_pid
        })
        process.send(client_pid, topic, message)
    end
end

-- Group subscriptions. A trusted in-runtime process instructs the hub to join a
-- pg process group; the hub then receives that group's broadcasts in its inbox
-- and fans them to the user's clients via broadcast_to_clients (the else branch).
-- These control topics are not reachable from ws clients.
local function pg_scope_for(state: UserState, scope_id: string): (any, any)
    local existing = state.pg_scopes[scope_id]
    if existing then return existing, nil end
    local scope, err = pg.open(scope_id)
    if err or not scope then
        return nil, err or "failed to open pg scope"
    end
    state.pg_scopes[scope_id] = scope
    return scope, nil
end

local function handle_pg_subscribe(state: UserState, payload_data: any)
    local scope_id = payload_data.scope :: string?
    local group = payload_data.group :: string?
    if not scope_id or not group then
        logger:warn("pg.subscribe missing scope or group", { user_id = state.user_id })
        return
    end
    if state.pg_groups[group] then
        return
    end
    local scope, err = pg_scope_for(state, scope_id)
    if not scope then
        logger:error("pg.subscribe scope open failed", { user_id = state.user_id, scope = scope_id, error = err })
        return
    end
    local ok, jerr = scope:join(group)
    if not ok then
        logger:error("pg.subscribe join failed", { user_id = state.user_id, group = group, error = jerr })
        return
    end
    state.pg_groups[group] = scope_id
    logger:info("pg subscribed", { user_id = state.user_id, group = group })
end

local function handle_pg_unsubscribe(state: UserState, payload_data: any)
    local group = payload_data.group :: string?
    if not group then return end
    local scope_id = state.pg_groups[group]
    if not scope_id then return end
    local scope = state.pg_scopes[scope_id]
    if scope then
        scope:leave(group)
    end
    state.pg_groups[group] = nil
    logger:info("pg unsubscribed", { user_id = state.user_id, group = group })
end

local function release_pg(state: UserState)
    for group, scope_id in pairs(state.pg_groups) do
        local scope = state.pg_scopes[scope_id]
        if scope then
            scope:leave(group)
        end
    end
    state.pg_groups = {}
    for _, scope in pairs(state.pg_scopes) do
        scope:release()
    end
    state.pg_scopes = {}
end

local function notify_central_hub_activity(state: UserState)
    if state.central_hub_pid then
        process.send(state.central_hub_pid, consts.HUB_TOPICS.ACTIVITY_UPDATE, {
            user_id = state.user_id,
            client_count = state.client_count,
            last_activity = time.now():format_rfc3339()
        })
    end
end

local function spawn_plugin(state: UserState, prefix: string, plugin_config: PluginConfig): (boolean, string?)
    if not state.active_plugins[prefix] then
        state.active_plugins[prefix] = {
            pid = nil,
            restart_count = 0,
            status = "pending"
        }
    end

    local plugin_state = state.active_plugins[prefix]!

    if plugin_state.status == "failed" then
        return false, "Plugin " .. prefix .. " has failed permanently"
    end

    local plugin_pid, err = process.spawn_linked_monitored(
        plugin_config.process_id,
        plugin_config.host!,
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

local function find_plugin_for_command(state: UserState, command: string): (string?, PluginConfig?)
    for prefix, plugin_config in pairs(state.plugins) do
        if command:sub(1, #prefix) == prefix then
            return prefix, plugin_config
        end
    end
    return nil, nil
end

local function route_to_plugin(state: UserState, prefix: string, plugin_config: PluginConfig, topic: string, message_data: any, from_pid: string): (boolean, string?)
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

    if plugin_state then
        local pid = plugin_state.pid
        if pid then
            local payload_data = {
                conn_pid = from_pid,
                request_id = message_data.request_id,
                session_id = message_data.session_id,
                type = message_data.type,
                data = message_data.data,
                start_token = message_data.start_token,
                context = message_data.context
            }

            process.send(pid, topic, payload_data)
            return true
        end
    end

    return false, "Plugin not available"
end

local function handle_client_join(state: UserState, payload_data: any)
    local client_pid = payload_data.client_pid :: string?
    if client_pid then
        state.connected_clients[client_pid] = true
        state.client_count = state.client_count + 1

        logger:info("client connected", {
            client_pid = client_pid,
            client_count = state.client_count,
            user_id = state.user_id
        })

        if state.client_count == 1 then
            local session_plugin = state.active_plugins["session_"]
            if session_plugin then
                local pid = session_plugin.pid
                if pid then
                    process.send(pid, "resume", {})
                end
            end
        end

        process.send(client_pid, consts.CLIENT_TOPICS.WELCOME, {
            user_id = state.user_id,
            client_count = state.client_count,
            active_session_ids = {},
            active_sessions = 0,
            plugins = get_plugin_info(state)
        })

        notify_central_hub_activity(state)
    end
end

local function handle_client_leave(state: UserState, payload_data: any)
    local client_pid = payload_data.client_pid :: string?
    if client_pid and state.connected_clients[client_pid] then
        state.connected_clients[client_pid] = nil
        state.client_count = state.client_count - 1

        logger:info("client disconnected", {
            client_pid = client_pid,
            client_count = state.client_count,
            user_id = state.user_id
        })

        if state.client_count == 0 then
            local session_plugin = state.active_plugins["session_"]
            if session_plugin then
                local pid = session_plugin.pid
                if pid then
                    process.send(pid, "shutdown", {})
                end
            end
        end

        notify_central_hub_activity(state)
    end
end

local function handle_client_message(state: UserState, payload: any, from_pid: string)
    local message_data, err = json.decode(string(payload:data()))
    if not message_data then
        process.send(from_pid, consts.CLIENT_TOPICS.ERROR, {
            error = consts.ERROR_CODES.INVALID_JSON,
            message = "Failed to decode JSON message"
        })
        return
    end

    local msg_type = message_data.type :: string?
    if not msg_type then
        process.send(from_pid, consts.CLIENT_TOPICS.ERROR, {
            error = consts.ERROR_CODES.UNKNOWN_COMMAND,
            message = "Message type is required"
        })
        return
    end

    local plugin_prefix, plugin_config = find_plugin_for_command(state, msg_type)
    if not plugin_prefix or not plugin_config then
        process.send(from_pid, consts.CLIENT_TOPICS.ERROR, {
            error = consts.ERROR_CODES.PLUGIN_NOT_FOUND,
            message = "No plugin found for command: " .. msg_type
        })
        return
    end

    local stripped_topic = msg_type:sub(#plugin_prefix + 1)
    local success, route_err = route_to_plugin(state, plugin_prefix!, plugin_config!, stripped_topic, message_data, from_pid)
    if not success then
        process.send(from_pid, consts.CLIENT_TOPICS.ERROR, {
            error = consts.ERROR_CODES.PLUGIN_FAILED,
            message = route_err or "Failed to route message to plugin"
        })
    end
end

local function handle_process_event(state: UserState, event: any)
    if event.kind ~= process.event.EXIT and event.kind ~= process.event.LINK_DOWN then
        return
    end

    local from_pid = event.from
    local plugin_prefix: string? = nil
    local plugin_state: PluginState? = nil

    for prefix, pstate in pairs(state.active_plugins) do
        if pstate.pid == from_pid then
            plugin_prefix = prefix
            plugin_state = pstate
            break
        end
    end

    if not plugin_prefix or not plugin_state then
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

    local restart_config = state.plugins[plugin_prefix] :: PluginConfig?
    if restart_config then
        spawn_plugin(state, plugin_prefix, restart_config)
    end
end

local function run(args: any): any
    if not args or not args.user_id or not args.plugins or not args.config then
        error("Missing required arguments: user_id, plugins, config")
    end

    local user_id = string(args.user_id)
    local central_hub_pid = args.central_hub_pid :: string?

    local plugins = args.plugins :: {[string]: PluginConfig}
    local state: UserState = {
        user_id = user_id,
        user_metadata = args.user_metadata or {},
        plugins = plugins,
        config = args.config,
        central_hub_pid = central_hub_pid,
        active_plugins = {},
        connected_clients = {},
        client_count = 0,
        pg_scopes = {},
        pg_groups = {}
    }

    local registry_name = consts.USER_HUB_REGISTRY_PREFIX .. state.user_id
    local registered, register_err = process.registry.register(registry_name)
    if not registered then
        error("Failed to register user hub " .. registry_name .. ": " .. (register_err or "unknown error"))
    end
    logger:info("user hub registered", { user_id = state.user_id, registry_name = registry_name })
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
            local msg: any = result.value
            local topic = string(msg:topic())
            local payload: any = msg:payload()
            local from_pid = string(msg:from())

            if topic == consts.WS_TOPICS.JOIN then
                handle_client_join(state, payload:data())
            elseif topic == consts.WS_TOPICS.LEAVE then
                handle_client_leave(state, payload:data())
            elseif topic == consts.WS_TOPICS.MESSAGE then
                handle_client_message(state, payload, from_pid)
            elseif topic == consts.WS_TOPICS.CANCEL then
                logger:info("received cancel signal")
                break
            elseif topic == consts.HUB_CONTROL.PG_SUBSCRIBE then
                handle_pg_subscribe(state, payload:data())
            elseif topic == consts.HUB_CONTROL.PG_UNSUBSCRIBE then
                handle_pg_unsubscribe(state, payload:data())
            else
                broadcast_to_clients(state, topic, payload:data())
            end
        elseif result.channel == events then
            local event: any = result.value
            if event.kind == process.event.CANCEL then
                break
            else
                handle_process_event(state, event)
            end
        end
    end

    release_pg(state)

    for prefix, plugin_state in pairs(state.active_plugins) do
        local pid = plugin_state.pid
        if pid then
            process.cancel(pid, consts.CANCEL_TIMEOUT)
        end
    end

    return { status = "shutdown", user_id = state.user_id }
end

return { run = run }
