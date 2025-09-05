local time = require("time")
local json = require("json")
local security = require("security")
local consts = require("consts")
local plugin_discovery = require("plugin_discovery")

local logger = require("logger"):named("relay")

local function run()
    -- Load configuration
    local config = consts.get_config()

    logger:info("relay central hub starting", {
        max_connections_per_user = config.max_connections_per_user,
        inactivity_timeout = config.user_hub_inactivity_timeout
    })

    -- Validate required configuration
    if not config.user_security_scope or config.user_security_scope == "" then
        error("RELAY_USER_SECURITY_SCOPE environment variable is required")
    end

    if not config.user_hub_host or config.user_hub_host == "" then
        error("RELAY_HOST environment variable is required")
    end

    -- Discover plugins once at startup
    local plugins, plugin_err = plugin_discovery.get_plugins()
    if plugin_err then
        error("Failed to discover plugins: " .. plugin_err)
    end

    logger:info("plugin discovery complete", { plugin_count = table_length(plugins) })

    -- Initialize state
    local state = {
        config = config,
        plugins = plugins,
        user_hubs = {}, -- user_id -> { hub_pid, last_activity, client_count }
        total_hubs = 0
    }

    -- Register this process
    process.registry.register(consts.CENTRAL_HUB_REGISTRY_NAME)

    -- Set trap_links to handle user hub failures gracefully
    process.set_options({ trap_links = true })

    -- Set up GC ticker
    local gc_ticker = time.ticker(config.gc_check_interval)

    -- Set up channels
    local inbox = process.inbox()
    local events = process.events()

    -- Main loop
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
            local msg = result.value
            local topic = msg:topic()
            local payload = msg:payload():data()

            if topic == consts.WS_TOPICS.JOIN then
                handle_client_connection(state, payload.client_pid, payload.metadata)
            elseif topic == consts.WS_TOPICS.LEAVE then
                -- Log user leave in central for tracking
                if payload.metadata and payload.metadata.user_id then
                    logger:info("user leaving central hub", { user_id = payload.metadata.user_id })
                end
            elseif topic == consts.HUB_TOPICS.ACTIVITY_UPDATE then
                handle_activity_update(state, payload)
            else
                -- Broadcast unknown messages to all user hubs
                for user_id, hub_info in pairs(state.user_hubs) do
                    if hub_info.hub_pid then
                        process.send(hub_info.hub_pid, topic, payload)
                    end
                end
            end

        elseif result.channel == events then
            local event = result.value
            handle_process_event(state, event)

        elseif result.channel == gc_ticker:channel() then
            check_inactive_hubs(state)
        end
    end

    -- Cleanup on exit
    gc_ticker:stop()

    logger:info("shutting down relay central hub", { active_hubs = state.total_hubs })

    -- Cancel all user hubs
    for user_id, hub_info in pairs(state.user_hubs) do
        if hub_info.hub_pid then
            process.cancel(hub_info.hub_pid, consts.CANCEL_TIMEOUT)
        end
    end

    return { status = "shutdown", hubs = state.total_hubs }
end

function table_length(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Handle client connection request
function handle_client_connection(state, client_pid, metadata)
    local user_id = metadata and metadata.user_id
    if not user_id then
        process.send(client_pid, consts.CLIENT_TOPICS.ERROR, {
            error = consts.ERROR_CODES.MISSING_USER_ID,
            message = "User ID is required for connection"
        })
        return
    end

    -- Check connection limit
    if state.user_hubs[user_id] and
       state.user_hubs[user_id].client_count >= state.config.max_connections_per_user then
        logger:warn("connection limit exceeded", { user_id = user_id, limit = state.config.max_connections_per_user })
        process.send(client_pid, consts.CLIENT_TOPICS.ERROR, {
            error = consts.ERROR_CODES.MAX_CONNECTIONS,
            message = "Maximum connection limit reached (" ..
                      state.config.max_connections_per_user .. " connections)"
        })
        return
    end

    -- Get or create user hub
    local user_hub_pid = get_or_create_user_hub(state, user_id, metadata)
    if not user_hub_pid then
        logger:error("user hub creation failed", { user_id = user_id })
        process.send(client_pid, consts.CLIENT_TOPICS.ERROR, {
            error = consts.ERROR_CODES.HUB_CREATION_FAILED,
            message = "Failed to create user hub"
        })
        return
    end

    -- Send control message to redirect client
    process.send(client_pid, consts.WS_TOPICS.CONTROL, {
        target_pid = user_hub_pid,
        metadata = metadata,
        plugins = state.plugins
    })

    -- Update activity
    if state.user_hubs[user_id] then
        state.user_hubs[user_id].last_activity = time.now()
    end
end

-- Get or create user hub for user
function get_or_create_user_hub(state, user_id, metadata)
    -- Check if hub already exists
    if state.user_hubs[user_id] and state.user_hubs[user_id].hub_pid then
        return state.user_hubs[user_id].hub_pid
    end

    -- Create user actor
    local user_metadata = metadata.user_metadata or {}
    local user_actor = security.new_actor(user_id, user_metadata)

    -- Get user scope
    local user_scope, scope_err = security.named_scope(state.config.user_security_scope)
    if scope_err then
        error("Failed to get user security scope: " .. scope_err)
    end

    -- Spawn user hub process with linking and monitoring
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

    -- Store hub info
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

-- Handle activity updates from user hubs
function handle_activity_update(state, payload)
    local user_id = payload.user_id
    if user_id and state.user_hubs[user_id] then
        state.user_hubs[user_id].client_count = payload.client_count or 0
        if payload.last_activity then
            local activity_time, err = time.parse(time.RFC3339, payload.last_activity)
            if activity_time then
                state.user_hubs[user_id].last_activity = activity_time
            end
        end
    end
end

-- Handle process events
function handle_process_event(state, event)
    if event.kind ~= process.event.EXIT and event.kind ~= process.event.LINK_DOWN then
        return
    end

    local from_pid = event.from

    -- Find and remove terminated hub
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

-- Check for inactive user hubs
function check_inactive_hubs(state)
    local now = time.now()
    local inactivity_duration, _ = time.parse_duration(state.config.user_hub_inactivity_timeout)

    for user_id, hub_info in pairs(state.user_hubs) do
        -- Skip if hub has clients or is being terminated
        if hub_info.client_count > 0 or hub_info.terminating then
            goto continue
        end

        -- Check inactivity
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

return { run = run }
