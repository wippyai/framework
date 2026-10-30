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

type Route = {
    prefix: string,
    config: PluginConfig,
    topic: string,
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
    retiring: boolean?,
    pg_scopes: {[string]: any},
    pg_groups: {[string]: string},
    routes: {[any]: Route},
    route_count: number,
    disconnect_started_at: string?,
}

local MAX_CACHED_ROUTES = 64

type UserUpgradeState = {
    relay_user_upgrade: boolean,
    user_id: string,
    user_metadata: any,
    plugins: {[string]: PluginConfig},
    config: any,
    central_hub_pid: string?,
    active_plugins: {[string]: PluginState},
    connected_clients: {[string]: boolean},
    client_count: number,
    retiring: boolean?,
    pg_groups: {[string]: string},
    disconnect_started_at: string?,
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
    for client_pid, _ in pairs(state.connected_clients) do
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

local function snapshot_state(state: UserState): UserUpgradeState
    local groups = {}
    for group, scope_id in pairs(state.pg_groups) do
        groups[group] = scope_id
    end
    return {
        relay_user_upgrade = true,
        user_id = state.user_id,
        user_metadata = state.user_metadata,
        plugins = state.plugins,
        config = state.config,
        central_hub_pid = state.central_hub_pid,
        active_plugins = state.active_plugins,
        connected_clients = state.connected_clients,
        client_count = state.client_count,
        retiring = state.retiring,
        pg_groups = groups,
        disconnect_started_at = state.disconnect_started_at,
    }
end

local function encode_upgrade_state(snapshot: UserUpgradeState): string
    local encoded, encode_err = json.encode(snapshot)
    if not encoded then
        error("failed to encode relay user upgrade state: " .. tostring(encode_err))
    end
    return encoded
end

local function decode_upgrade_state(encoded: any): UserUpgradeState
    if type(encoded) ~= "string" then
        error("invalid relay user upgrade state payload")
    end
    local snapshot, decode_err = json.decode(encoded)
    if not snapshot then
        error("failed to decode relay user upgrade state: " .. tostring(decode_err))
    end
    if type(snapshot) ~= "table" or snapshot.relay_user_upgrade ~= true then
        error("invalid relay user upgrade state marker")
    end
    return snapshot :: UserUpgradeState
end

local function restore_pg(state: UserState, groups: {[string]: string})
    for group, scope_id in pairs(groups or {}) do
        local scope, scope_err = pg_scope_for(state, scope_id)
        if not scope then
            error("failed to restore relay group " .. group .. ": " .. tostring(scope_err))
        end
        local joined, join_err = scope:join(group)
        if not joined then
            error("failed to restore relay group " .. group .. ": " .. tostring(join_err))
        end
        state.pg_groups[group] = scope_id
    end
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
                attention_context_enabled = message_data.attention_context_enabled,
                context = message_data.context
            }

            local sent, send_err = process.send(pid, topic, payload_data)
            if not sent then
                return false, "Failed to send message to plugin: " .. tostring(send_err)
            end
            return true
        end
    end

    return false, "Plugin not available"
end

local function registered_pid(name: string): string?
    local current, lookup_err = process.registry.lookup(name)
    if lookup_err and not errors.is(lookup_err, errors.NOT_FOUND) then error(lookup_err) end
    return current
end

local function is_current_hub(state: UserState): boolean
    return registered_pid(consts.USER_HUB_REGISTRY_PREFIX .. state.user_id) == process.pid()
end

local function handle_client_join(state: UserState, payload_data: any)
    local client_pid = payload_data.client_pid :: string?
    if client_pid then
        if state.retiring and not is_current_hub(state) then
            process.send(client_pid, consts.CLIENT_TOPICS.ERROR, {
                error = consts.ERROR_CODES.HUB_CREATION_FAILED,
                message = "User hub has retired",
            })
            return
        end
        if not state.connected_clients[client_pid] then
            state.connected_clients[client_pid] = true
            state.client_count = state.client_count + 1

            logger:info("client connected", {
                client_pid = client_pid,
                client_count = state.client_count,
                user_id = state.user_id
            })

            if state.client_count == 1 then
                state.retiring = false
                state.disconnect_started_at = nil
                local session_plugin = state.active_plugins["session_"]
                if session_plugin then
                    local pid = session_plugin.pid
                    if pid then
                        process.send(pid, "resume", {})
                    end
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
            state.disconnect_started_at = time.now():format(time.RFC3339NANO)
        end

        notify_central_hub_activity(state)
    end
end

local function handle_client_message(state: UserState, payload: any, from_pid: string)
    if not state.connected_clients[from_pid] then
        logger:warn("message from unconnected client rejected", {
            user_id = state.user_id,
            client_pid = from_pid,
        })
        return
    end

    local message_data, err = json.decode(payload:data())
    if err then
        process.send(from_pid, consts.CLIENT_TOPICS.ERROR, {
            error = consts.ERROR_CODES.INVALID_JSON,
            message = "Failed to decode JSON message"
        })
        return
    end

    if type(message_data) ~= "table" then
        process.send(from_pid, consts.CLIENT_TOPICS.ERROR, {
            error = consts.ERROR_CODES.UNKNOWN_COMMAND,
            message = "Message must be a JSON object"
        })
        return
    end

    local msg_type: any = message_data.type
    local route = state.routes[msg_type]
    if not route then
        if type(msg_type) ~= "string" or msg_type == "" then
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

        route = { prefix = plugin_prefix, config = plugin_config, topic = msg_type:sub(#plugin_prefix + 1) }
        if state.route_count < MAX_CACHED_ROUTES then
            state.routes[msg_type] = route
            state.route_count = state.route_count + 1
        end
    end

    local success, route_err = route_to_plugin(state, route.prefix, route.config, route.topic, message_data, from_pid)
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

    -- A disconnected hub must not restart the session plugin it is waiting
    -- to retire. Its normal crash recovery records any unfinished work.
    if state.retiring and state.client_count == 0 and plugin_prefix == "session_" then
        plugin_state.status = "stopped"
        return
    end

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
    local resumed = type(args) == "string"
    if resumed then
        args = decode_upgrade_state(args)
    end
    if not args or not args.user_id or not args.plugins or not args.config then
        error("Missing required arguments: user_id, plugins, config")
    end

    local active_plugins: {[string]: PluginState} = {}
    local connected_clients: {[string]: boolean} = {}
    local client_count = 0
    local upgrade_groups: {[string]: string} = {}
    if resumed then
        local resume_state = args :: UserUpgradeState
        active_plugins = resume_state.active_plugins
        connected_clients = resume_state.connected_clients
        -- Older duplicate JOINs could inflate the saved counter. Memberships
        -- are authoritative; rebuilding the derived count keeps final LEAVE valid.
        for _ in pairs(connected_clients) do
            client_count = client_count + 1
        end
        upgrade_groups = resume_state.pg_groups
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
        active_plugins = active_plugins,
        connected_clients = connected_clients,
        client_count = client_count,
        retiring = resumed and args.retiring == true,
        pg_scopes = {},
        pg_groups = {},
        routes = {},
        route_count = 0,
        disconnect_started_at = resumed and args.disconnect_started_at or nil,
    }

    local registry_name = consts.USER_HUB_REGISTRY_PREFIX .. state.user_id
    if not resumed and (not central_hub_pid or central_hub_pid ~= registered_pid(consts.CENTRAL_HUB_REGISTRY_NAME)) then
        local registered, register_err = process.registry.register(registry_name)
        if not registered then
            error("Failed to register user hub " .. registry_name .. ": " .. (register_err or "unknown error"))
        end
        logger:info("user hub registered", { user_id = state.user_id, registry_name = registry_name })
    end
    process.set_options({ trap_links = true, upgradable = true })

    if resumed then
        restore_pg(state, upgrade_groups)
        logger:info("user hub upgraded", {
            user_id = state.user_id,
            client_count = state.client_count,
        })
    else
        for prefix, plugin_config in pairs(state.plugins) do
            if plugin_config.auto_start then
                spawn_plugin(state, prefix, plugin_config)
            end
        end
    end

    local inbox = process.inbox()
    local events = process.events()
    local select_cases = { inbox:case_receive(), events:case_receive() }
    local disconnect_timer: any = nil
    local timer_started_at: string? = nil

    while true do
        if timer_started_at ~= state.disconnect_started_at then
            if disconnect_timer then disconnect_timer:stop() end
            disconnect_timer = nil
            timer_started_at = state.disconnect_started_at
            select_cases[3] = nil
            if timer_started_at then
                local started, parse_err = time.parse(time.RFC3339NANO, timer_started_at)
                if not started then error("Invalid disconnect timestamp: " .. tostring(parse_err)) end
                local grace, duration_err = time.parse_duration(consts.DISCONNECT_GRACE)
                if not grace then error("Invalid disconnect grace: " .. tostring(duration_err)) end
                local remaining = math.max(0, grace:milliseconds() - time.now():sub(started):milliseconds())
                disconnect_timer = time.timer(remaining * time.MILLISECOND)
                select_cases[3] = disconnect_timer:channel():case_receive()
            end
        end
        local result = channel.select(select_cases)

        if not result.ok then
            break
        end

        if disconnect_timer and result.channel == disconnect_timer:channel() then
            disconnect_timer:stop()
            if state.client_count == 0 then
                local session_plugin = state.active_plugins["session_"]
                if session_plugin and session_plugin.pid then
                    local sent, send_err = process.send(session_plugin.pid, "shutdown", {})
                    if not sent then
                        logger:error("disconnect shutdown delivery failed", {
                            user_id = state.user_id, plugin_pid = session_plugin.pid, error = tostring(send_err),
                        })
                    end
                end
            end
            state.disconnect_started_at = nil
        elseif result.channel == inbox then
            local msg: any = result.value
            local topic: string = msg:topic()
            local payload: any = msg:payload()
            local from_pid: string = msg:from()

            if topic == consts.WS_TOPICS.JOIN then
                handle_client_join(state, payload:data())
            elseif topic == consts.WS_TOPICS.LEAVE then
                handle_client_leave(state, payload:data())
            elseif topic == consts.WS_TOPICS.MESSAGE then
                handle_client_message(state, payload, from_pid)
            elseif topic == consts.WS_TOPICS.CANCEL then
                logger:info("received cancel signal")
                break
            elseif topic == consts.HUB_CONTROL.RETIRE then
                if from_pid == state.central_hub_pid then
                    local current = is_current_hub(state)
                    -- A current hub ignores an inactivity observation overtaken
                    -- by JOIN. A superseded frame admits no more client work.
                    if state.client_count == 0 or not current then
                        if not current then
                            broadcast_to_clients(state, consts.CLIENT_TOPICS.ERROR, {
                                error = consts.ERROR_CODES.HUB_CREATION_FAILED,
                                message = "User hub has retired",
                            })
                            state.connected_clients = {}
                            state.client_count = 0
                            state.disconnect_started_at = nil
                        end
                        state.retiring = true
                        local session = state.active_plugins["session_"]
                        if session and session.pid then process.send(session.pid, "shutdown", {}) end
                    end
                end
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
            elseif event.kind == process.event.OUTDATED then
                if disconnect_timer then disconnect_timer:stop() end
                local upgrade_state = encode_upgrade_state(snapshot_state(state))
                release_pg(state)
                logger:info("upgrading user hub", {
                    user_id = state.user_id,
                    client_count = state.client_count,
                })
                process.upgrade("", upgrade_state)
            else
                handle_process_event(state, event)
            end
        end
        if state.retiring and state.client_count == 0 then
            local session = state.active_plugins["session_"]
            if not session or not session.pid then break end
        end
    end

    release_pg(state)
    if disconnect_timer then disconnect_timer:stop() end

    for prefix, plugin_state in pairs(state.active_plugins) do
        local pid = plugin_state.pid
        if pid then
            process.cancel(pid, consts.CANCEL_TIMEOUT)
        end
    end

    return { status = "shutdown", user_id = state.user_id }
end

return {
    run = run,
    _snapshot_state = snapshot_state,
    _encode_upgrade_state = encode_upgrade_state,
    _decode_upgrade_state = decode_upgrade_state,
}
