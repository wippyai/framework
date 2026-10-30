local time = require("time")
local json = require("json")
local security = require("security")
local consts = require("consts")
local plugin_discovery = require("plugin_discovery")

local logger = require("logger"):named("relay")
local security_mod = security

type HubIdentity = {
    actor_id: string,
    actor_meta: any,
    policy_ids: {[string]: boolean},
}

type UserHubInfo = {
    hub_pid: string,
    created_at: time.Time,
    last_activity: time.Time,
    client_count: number,
    terminating?: boolean,
    termination_started_at?: time.Time,
    identity?: HubIdentity,
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
    identity?: HubIdentity,
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

local function authority_identity(identity: HubIdentity?): HubIdentity?
    if not identity then return nil end
    local actor_meta = {}
    for key, value in pairs(identity.actor_meta) do
        if key ~= "session" then actor_meta[key] = value end
    end
    return {
        actor_id = identity.actor_id,
        actor_meta = actor_meta,
        policy_ids = identity.policy_ids,
    }
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
            identity = authority_identity(hub.identity),
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
            identity = authority_identity(hub.identity),
        }
    end
    return user_hubs
end

local function identity_from_metadata(config: ValidatedConfig, user_id: string, metadata: any): (any?, any?, any?, any?)
    local user_metadata = type(metadata.user_metadata) == "table" and metadata.user_metadata or {}
    local scope_id = type(metadata.scope_id) == "string" and metadata.scope_id ~= "" and metadata.scope_id or config.user_security_scope
    local user_actor = security_mod.new_actor(user_id, user_metadata)

    local user_scope, scope_err
    if metadata.scope_policy_ids ~= nil then
        if type(metadata.scope_policy_ids) ~= "table" then
            return nil, nil, nil, errors.new({kind = errors.INVALID, message = "scope_policy_ids must be an array"})
        end
        local policies = {}
        local count = #metadata.scope_policy_ids
        local present = 0
        for index, id in pairs(metadata.scope_policy_ids) do
            if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > count
                or type(id) ~= "string" or id == "" then
                return nil, nil, nil, errors.new({kind = errors.INVALID, message = "scope_policy_ids must contain policy ids"})
            end
            present = present + 1
        end
        if present ~= count then
            return nil, nil, nil, errors.new({kind = errors.INVALID, message = "scope_policy_ids must be dense"})
        end
        for _, id in ipairs(metadata.scope_policy_ids) do
            local policy, policy_err = security_mod.policy(id)
            if policy_err then return nil, nil, nil, policy_err end
            if not policy then
                return nil, nil, nil, errors.new({kind = errors.INTERNAL, message = "authenticated policy is unavailable"})
            end
            policies[#policies + 1] = policy
        end
        user_scope = security_mod.new_scope(policies)
    else
        user_scope, scope_err = security_mod.named_scope(tostring(scope_id))
    end
    if scope_err then return nil, nil, nil, scope_err end

    return user_actor, user_scope, user_metadata, nil
end

local function same_identity(left: any, right: any): boolean
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    for key, value in pairs(left) do
        if not same_identity(value, right[key]) then return false end
    end
    for key in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

local function get_or_create_user_hub(state: CentralState, user_id: string, metadata: any): string?
    local user_actor, user_scope, user_metadata, identity_err = identity_from_metadata(state.config, user_id, metadata or {})
    if identity_err then error(identity_err) end

    local policy_ids: {[string]: boolean} = {}
    for _, policy in ipairs(user_scope:policies()) do policy_ids[policy:id()] = true end
    local identity = authority_identity({actor_id = user_actor:id(), actor_meta = user_actor:meta(), policy_ids = policy_ids})
    local hub = state.user_hubs[user_id]
    if hub and same_identity(hub.identity, identity) then return hub.hub_pid end

    local registry_name = consts.USER_HUB_REGISTRY_PREFIX .. user_id
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

    -- Stage the new frame before moving the canonical name. Until handover
    -- succeeds, the old frame and cached admission remain authoritative.
    local unregistered, registered = false, false
    local admitted, admission_err = pcall(function()
        if hub then
            local _, unregister_err = process.registry.unregister(registry_name)
            if unregister_err then error(unregister_err) end
            unregistered = true
        end
        local register_ok, register_err = process.registry.register(registry_name, hub_pid)
        if not register_ok then error(register_err) end
        registered = true
        if hub then
            local sent, retire_err = process.send(hub.hub_pid, consts.HUB_CONTROL.RETIRE, {})
            if not sent then error(retire_err) end
        end
    end)
    if not admitted then
        if registered then
            local _, cleanup_err = process.registry.unregister(registry_name)
            if cleanup_err then
                logger:error("failed to remove unadmitted hub registration", {user_id = user_id, error = cleanup_err})
            end
        end
        if hub and unregistered then
            local restored, restore_err = process.registry.register(registry_name, hub.hub_pid)
            if not restored then
                logger:error("failed to restore user hub registration", {user_id = user_id, error = restore_err})
            end
        end
        local cancelled, cancel_err = process.cancel(hub_pid, consts.CANCEL_TIMEOUT)
        if not cancelled then
            logger:error("failed to cancel unadmitted user hub", {user_id = user_id, hub_pid = hub_pid, error = cancel_err})
        end
        error(admission_err)
    end
    state.user_hubs[user_id] = {
        hub_pid = hub_pid,
        created_at = time.now(),
        last_activity = time.now(),
        client_count = 0,
        identity = identity,
    }

    if not hub then state.total_hubs = state.total_hubs + 1 end

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

    local admitted, user_hub_pid = pcall(get_or_create_user_hub, state, user_id, metadata)
    if not admitted or not user_hub_pid then
        logger:error("user hub creation failed", { user_id = user_id, error = not admitted and tostring(user_hub_pid) or nil })
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

local function handle_activity_update(state: CentralState, payload: any, from_pid: string)
    local user_id = string(payload.user_id)
    local hub = state.user_hubs[user_id]
    if hub and hub.hub_pid == from_pid then
        hub.client_count = tonumber(payload.client_count) or 0
        if hub.client_count > 0 then
            hub.terminating = false
            hub.termination_started_at = nil
        end
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
            -- Session retirement is cooperative. Cancelling its parent here
            -- would propagate cancellation to an otherwise healthy turn.
            local success, err = process.send(hub_info.hub_pid, consts.HUB_CONTROL.RETIRE, {})
            if success then
                hub_info.terminating = true
                hub_info.termination_started_at = now
                logger:info("retiring inactive user hub", { user_id = user_id, inactive_for_seconds = time_since_activity:seconds() })
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
                handle_activity_update(state, payload, msg:from())
            elseif topic == consts.HUB_CONTROL.RETIRE then
                -- Collection is issued only by our own inactivity sweep.
                -- Never turn an incoming request into a trusted broadcast.
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
    _check_inactive_hubs = check_inactive_hubs,
    _handle_activity_update = handle_activity_update,
    _get_or_create_user_hub = get_or_create_user_hub,
    _handle_client_connection = handle_client_connection,
    _handle_process_event = handle_process_event,
}
