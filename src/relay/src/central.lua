local time = require("time")
local json = require("json")
local security = require("security")
local consts = require("consts")
local plugin_discovery = require("plugin_discovery")

local logger = require("logger"):named("relay")
local security_mod = security

type UserHubInfo = {
    hub_pid: string,
    created_at: time.Time,
    last_activity: time.Time,
    client_count: number,
    terminating?: boolean,
    termination_started_at?: time.Time,
}

type ValidatedConfig = {
    max_connections_per_user: number,
    user_hub_inactivity_timeout: string,
    user_hub_host: string,
    user_security_scope: string,
    gc_check_interval: string,
    heartbeat_interval: string,
    message_queue_size: number,
    queue_multiplier: number,
}

type CentralState = {
    config: ValidatedConfig,
    plugins: any,
    user_hubs: {[string]: UserHubInfo},
    total_hubs: number,
}

type UserHubUpgradeInfo = {
    hub_pid: string,
    created_at: string?,
    last_activity: string?,
    client_count: number,
    terminating: boolean?,
    termination_started_at: string?,
}

type CentralUpgradeState = {
    relay_upgrade: boolean,
    user_hubs: {[string]: UserHubUpgradeInfo},
    total_hubs: number,
}

local function table_length(t: any): number
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

local function encode_time(value: time.Time?): string?
    if not value then return nil end
    return value:format_rfc3339()
end

local function decode_time(value: any, field: string): time.Time?
    if value == nil then return nil end
    local parsed, parse_err = time.parse(time.RFC3339, tostring(value))
    if not parsed then
        error("invalid relay upgrade state " .. field .. ": " .. tostring(parse_err))
    end
    return parsed
end

local function snapshot_state(state: CentralState): CentralUpgradeState
    local user_hubs: {[string]: UserHubUpgradeInfo} = {}
    for user_id, hub in pairs(state.user_hubs) do
        user_hubs[user_id] = {
            hub_pid = hub.hub_pid,
            created_at = encode_time(hub.created_at),
            last_activity = encode_time(hub.last_activity),
            client_count = hub.client_count,
            terminating = hub.terminating,
            termination_started_at = encode_time(hub.termination_started_at),
        }
    end
    local snapshot: CentralUpgradeState = {
        relay_upgrade = true,
        user_hubs = user_hubs,
        total_hubs = state.total_hubs,
    }
    return snapshot
end

local function encode_upgrade_state(snapshot: CentralUpgradeState): string
    local encoded, encode_err = json.encode(snapshot)
    if not encoded then
        error("failed to encode relay central upgrade state: " .. tostring(encode_err))
    end
    return encoded
end

local function decode_upgrade_state(encoded: any): CentralUpgradeState
    if type(encoded) ~= "string" then
        error("invalid relay central upgrade state payload")
    end
    local snapshot, decode_err = json.decode(encoded)
    if not snapshot then
        error("failed to decode relay central upgrade state: " .. tostring(decode_err))
    end
    if type(snapshot) ~= "table" or snapshot.relay_upgrade ~= true then
        error("invalid relay central upgrade state marker")
    end
    return snapshot :: CentralUpgradeState
end

local function restore_hubs(snapshot: CentralUpgradeState): {[string]: UserHubInfo}
    local user_hubs: {[string]: UserHubInfo} = {}
    for user_id, hub in pairs(snapshot.user_hubs or {}) do
        if type(hub.hub_pid) ~= "string" or hub.hub_pid == "" then
            error("invalid relay upgrade state hub_pid for " .. tostring(user_id))
        end
        user_hubs[user_id] = {
            hub_pid = hub.hub_pid,
            created_at = decode_time(hub.created_at, "created_at")!,
            last_activity = decode_time(hub.last_activity, "last_activity")!,
            client_count = tonumber(hub.client_count) or 0,
            terminating = hub.terminating == true,
            termination_started_at = decode_time(hub.termination_started_at, "termination_started_at"),
        }
    end
    return user_hubs
end

local function identity_from_metadata(config: ValidatedConfig, user_id: string, metadata: any): (any?, any?, any?, string?)
    local user_metadata = type(metadata.user_metadata) == "table" and metadata.user_metadata or {}
    local scope_id = type(metadata.scope_id) == "string" and metadata.scope_id ~= "" and metadata.scope_id or config.user_security_scope
    local user_actor = security_mod.new_actor(user_id, user_metadata)

    local user_scope, scope_err = security_mod.named_scope(tostring(scope_id))
    if scope_err then
        return nil, nil, nil, "Failed to get user security scope: " .. scope_err
    end

    return user_actor, user_scope, user_metadata, nil
end

local function get_or_create_user_hub(state: CentralState, user_id: string, metadata: any): string?
    local hub = state.user_hubs[user_id]
    if hub then
        return hub.hub_pid
    end

    local user_actor, user_scope, user_metadata, identity_err = identity_from_metadata(state.config, user_id, metadata or {})
    if identity_err then error(identity_err) end

    local hub_pid, err = process.with_context({})
        :with_scope(user_scope)
        :with_actor(user_actor)
        :spawn_linked_monitored(
            consts.USER_HUB_PROCESS_ID,
            state.config.user_hub_host,
            {
                user_id = user_id,
                user_metadata = user_metadata,
                plugins = state.plugins,
                config = state.config,
                central_hub_pid = process.pid()
            }
        )

    if not hub_pid then
        logger:error("failed to spawn user hub", { user_id = user_id, error = err, host = state.config })
        return nil
    end

    state.user_hubs[user_id] = {
        hub_pid = hub_pid,
        created_at = time.now(),
        last_activity = time.now(),
        client_count = 0
    }

    state.total_hubs = state.total_hubs + 1

    logger:info("user hub created", { user_id = user_id, hub_pid = hub_pid, total_hubs = state.total_hubs })

    return hub_pid
end

local function handle_client_connection(state: CentralState, client_pid: any, metadata: any)
    local pid = string(client_pid)
    local user_id = (metadata and metadata.user_id) :: string?
    if not user_id then
        process.send(pid, consts.CLIENT_TOPICS.ERROR, {
            error = consts.ERROR_CODES.MISSING_USER_ID,
            message = "User ID is required for connection"
        })
        return
    end

    local existing_hub = state.user_hubs[user_id]
    if existing_hub and
       existing_hub.client_count >= state.config.max_connections_per_user then
        logger:warn("connection limit exceeded", { user_id = user_id, limit = state.config.max_connections_per_user })
        process.send(pid, consts.CLIENT_TOPICS.ERROR, {
            error = consts.ERROR_CODES.MAX_CONNECTIONS,
            message = "Maximum connection limit reached (" ..
                      state.config.max_connections_per_user .. " connections)"
        })
        return
    end

    local user_hub_pid = get_or_create_user_hub(state, user_id, metadata)
    if not user_hub_pid then
        logger:error("user hub creation failed", { user_id = user_id })
        process.send(pid, consts.CLIENT_TOPICS.ERROR, {
            error = consts.ERROR_CODES.HUB_CREATION_FAILED,
            message = "Failed to create user hub"
        })
        return
    end

    process.send(pid, consts.WS_TOPICS.CONTROL, {
        target_pid = user_hub_pid,
        metadata = metadata,
        plugins = state.plugins
    })

    local hub = state.user_hubs[user_id]
    if hub then
        hub.last_activity = time.now()
    end
end

local function handle_activity_update(state: CentralState, payload: any)
    local user_id = string(payload.user_id)
    local hub = state.user_hubs[user_id]
    if hub then
        hub.client_count = tonumber(payload.client_count) or 0
        if payload.last_activity then
            local activity_time, err = time.parse(time.RFC3339, string(payload.last_activity))
            if activity_time then
                hub.last_activity = activity_time
            end
        end
    end
end

local function handle_process_event(state: CentralState, event: any)
    if event.kind ~= process.event.EXIT and event.kind ~= process.event.LINK_DOWN then
        return
    end

    local from_pid = event.from

    for user_id, hub_info in pairs(state.user_hubs) do
        if hub_info.hub_pid == from_pid then
            state.user_hubs[user_id] = nil
            state.total_hubs = state.total_hubs - 1

            if event.kind == process.event.LINK_DOWN then
                logger:warn("user hub crashed", { user_id = user_id, hub_pid = from_pid, total_hubs = state.total_hubs })
            else
                logger:info("user hub terminated", { user_id = user_id, hub_pid = from_pid, total_hubs = state.total_hubs })
            end
            break
        end
    end
end

local function check_inactive_hubs(state: CentralState)
    local now = time.now()
    local inactivity_duration, _ = time.parse_duration(state.config.user_hub_inactivity_timeout)

    for user_id, hub_info in pairs(state.user_hubs) do
        if hub_info.client_count > 0 or hub_info.terminating then
            goto continue
        end

        local last_activity = hub_info.last_activity or hub_info.created_at
        local time_since_activity = now:sub(last_activity)

        if time_since_activity:seconds() > inactivity_duration:seconds() then
            local success, err = process.cancel(hub_info.hub_pid, consts.CANCEL_TIMEOUT)
            if success then
                hub_info.terminating = true
                hub_info.termination_started_at = now
                logger:info("terminating inactive user hub", { user_id = user_id, inactive_for_seconds = time_since_activity:seconds() })
            end
        end

        ::continue::
    end
end

local function run(upgrade_state: any?): any
    local config = consts.get_config()

    logger:info("relay central hub starting", {
        max_connections_per_user = config.max_connections_per_user,
        inactivity_timeout = config.user_hub_inactivity_timeout
    })

    if not config.user_security_scope or config.user_security_scope == "" then
        error("RELAY_USER_SECURITY_SCOPE environment variable is required")
    end

    if not config.user_hub_host or config.user_hub_host == "" then
        error("RELAY_HOST environment variable is required")
    end

    local plugins, plugin_err = plugin_discovery.get_plugins()
    if plugin_err then
        error("Failed to discover plugins: " .. plugin_err)
    end

    logger:info("plugin discovery complete", { plugin_count = table_length(plugins) })

    local resumed = upgrade_state ~= nil
    local user_hubs: {[string]: UserHubInfo} = {}
    local total_hubs = 0
    if resumed then
        local snapshot = decode_upgrade_state(upgrade_state)
        if type(snapshot.total_hubs) ~= "number" then
            error("invalid relay upgrade state total_hubs")
        end
        user_hubs = restore_hubs(snapshot)
        total_hubs = snapshot.total_hubs
    end
    local state: CentralState = {
        config = config :: ValidatedConfig,
        plugins = plugins,
        user_hubs = user_hubs,
        total_hubs = total_hubs,
    }

    if not resumed then
        local registered, register_err = process.registry.register(consts.CENTRAL_HUB_REGISTRY_NAME)
        if not registered then
            error("failed to register relay central hub: " .. tostring(register_err))
        end
    end
    process.set_options({ trap_links = true, upgradable = true })

    local gc_ticker = time.ticker(config.gc_check_interval)
    local inbox = process.inbox()
    local events = process.events()

    while true do
        local result = channel.select({
            inbox:case_receive(),
            events:case_receive(),
            gc_ticker:channel():case_receive()
        })

        if not result.ok then
            break
        end

        if result.channel == inbox then
            local msg: any = result.value
            local topic = string(msg:topic())
            local payload: any = msg:payload():data()

            if topic == consts.WS_TOPICS.JOIN then
                handle_client_connection(state, payload.client_pid, payload.metadata)
            elseif topic == consts.WS_TOPICS.LEAVE then
                if payload.metadata and payload.metadata.user_id then
                    logger:info("user leaving central hub", { user_id = payload.metadata.user_id })
                end
            elseif topic == consts.HUB_TOPICS.ACTIVITY_UPDATE then
                handle_activity_update(state, payload)
            else
                for user_id, hub_info in pairs(state.user_hubs) do
                    process.send(hub_info.hub_pid, topic, payload)
                end
            end

        elseif result.channel == events then
            local event: any = result.value
            if event.kind == process.event.CANCEL then
                logger:info("received cancel signal")
                break
            elseif event.kind == process.event.OUTDATED then
                local encoded_state = encode_upgrade_state(snapshot_state(state))
                gc_ticker:stop()
                logger:info("upgrading relay central hub", { active_hubs = state.total_hubs })
                process.upgrade("", encoded_state)
            end
            handle_process_event(state, event)

        elseif result.channel == gc_ticker:channel() then
            check_inactive_hubs(state)
        end
    end

    gc_ticker:stop()

    logger:info("shutting down relay central hub", { active_hubs = state.total_hubs })

    for user_id, hub_info in pairs(state.user_hubs) do
        process.cancel(hub_info.hub_pid, consts.CANCEL_TIMEOUT)
    end

    return { status = "shutdown", hubs = state.total_hubs }
end

return {
    run = run,
    _identity_from_metadata = identity_from_metadata,
    _set_security_for_test = function(fake: any)
        security_mod = fake or security
    end,
    _snapshot_state = snapshot_state,
    _restore_hubs = restore_hubs,
    _encode_upgrade_state = encode_upgrade_state,
    _decode_upgrade_state = decode_upgrade_state,
}
