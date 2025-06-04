local time = require("time")
local json = require("json")
local actor = require("actor")
local security = require("security")

-- Registry constants
local CENTRAL_HUB_REGISTRY_NAME = "wippy.central"

-- WebSocket topics (external layer - cannot be changed)
local WS_JOIN_TOPIC = "ws.join"
local WS_LEAVE_TOPIC = "ws.leave"

local WS_CONTROL_TOPIC = "ws.control"
local WS_HEARTBEAT_TOPIC = "ws.heartbeat"

-- Hub communication topics
local HUB_ACTIVITY_UPDATE_TOPIC = "hub.activity_update"

-- Client topics
local CLIENT_ERROR_TOPIC = "error"

-- Error codes
local ERROR_MAX_CONNECTIONS = "max_connections_reached"
local ERROR_MISSING_USER_ID = "missing_user_id"
local ERROR_HUB_CREATION_FAILED = "hub_creation_failed"

-- Process information
local USER_HUB_PROCESS_ID = "wippy.relay:user"
local USER_HUB_HOST = "app:processes"

-- Time constants
local USER_HUB_INACTIVITY_TIMEOUT = "300s"
local GC_CHECK_INTERVAL = "120s" -- Check for inactive hubs every 120 seconds

-- User limits
local MAX_CONNECTIONS_PER_USER = 10 -- Maximum allowed connections per user

-- Central Hub Process - Central hub that manages user-specific hubs
local function run()
    local initial_state = {
        user_hubs = {}, -- Map of user_id -> { hub_pid, last_ping, client_count, messages_handled }
        total_hubs = 0,
        gc_ticker = nil -- Garbage collection ticker
    }

    local handlers = {
        -- Initialize the actor
        __init = function(state)
            -- Register this process with a name for easy discovery
            process.registry.register(CENTRAL_HUB_REGISTRY_NAME)

            -- Create garbage collection ticker
            state.gc_ticker = time.ticker(GC_CHECK_INTERVAL)
            state.register_channel(state.gc_ticker:channel(), function(s, _, ok)
                if ok then
                    -- Check for inactive user hubs
                    check_inactive_hubs(s)
                end
                return s
            end)

            return state
        end,

        -- Handle system events
        __on_event = function(state, event)
            if event.kind == process.event.EXIT then
                -- A monitored process has exited
                local from_pid = event.from

                if from_pid then
                    -- Find which user hub this was
                    for user_id, hub_info in pairs(state.user_hubs) do
                        if hub_info.hub_pid == from_pid then
                            state.user_hubs[user_id] = nil
                            state.total_hubs = state.total_hubs - 1
                            break
                        end
                    end
                end
            end

            return state
        end,

        -- Handle cancellation
        __on_cancel = function(state)
            for user_id, hub_info in pairs(state.user_hubs) do
                process.cancel(hub_info.hub_pid)
            end

            -- Stop GC ticker
            if state.gc_ticker then
                state.gc_ticker:stop()
            end

            return actor.exit({ status = "shutdown", hubs = state.total_hubs })
        end,

        __default = function(state, payload, topic, from)
            -- broadcast to all clients
            for user_id, hub_info in pairs(state.user_hubs) do
                if hub_info.hub_pid then
                    process.send(hub_info.hub_pid, topic, payload)
                end
            end
            print("central hub received message", topic)
            return state
        end,

        -- Handle WebSocket join requests
        [WS_JOIN_TOPIC] = function(state, payload)
            handle_client_connection(state, payload.client_pid, payload.metadata)
            return state
        end,

        -- Handle WebSocket join requests
        [WS_LEAVE_TOPIC] = function(state, payload)
            -- nothing really
            return state
        end,

        -- Handle activity updates from user hubs
        [HUB_ACTIVITY_UPDATE_TOPIC] = function(state, payload)
            local user_id = payload.user_id

            if user_id and state.user_hubs[user_id] then
                -- Update hub stats
                state.user_hubs[user_id].client_count = payload.client_count
                state.user_hubs[user_id].messages_handled = payload.messages_handled

                if payload.last_activity then
                    local activity_time, err = time.parse(time.RFC3339, payload.last_activity)
                    if activity_time then
                        state.user_hubs[user_id].last_activity = activity_time
                    end
                end
            end

            return state
        end
    }

    -- Helper function to extract user_id from metadata
    local function extract_user_id(metadata)
        if type(metadata) ~= "table" then
            return nil
        end
        return metadata.user_id
    end

    -- Function to handle client connection
    function handle_client_connection(state, client_pid, metadata)
        -- Extract user ID from metadata
        local user_id = extract_user_id(metadata)
        if not user_id then
            -- Send error to client
            process.send(client_pid, CLIENT_ERROR_TOPIC, {
                error = ERROR_MISSING_USER_ID,
                message = "User ID is required for connection"
            })

            return
        end

        -- Check if user has reached maximum connections limit
        if state.user_hubs[user_id] and state.user_hubs[user_id].client_count >= MAX_CONNECTIONS_PER_USER then
            -- Send error to client
            process.send(client_pid, CLIENT_ERROR_TOPIC, {
                error = ERROR_MAX_CONNECTIONS,
                message = "Maximum connection limit reached (" .. MAX_CONNECTIONS_PER_USER .. " connections)"
            })

            return
        end

        -- Get or create user hub for this user
        local user_hub_pid = create_user_hub(state, user_id, metadata)
        if not user_hub_pid then
            -- Send error to client
            process.send(client_pid, CLIENT_ERROR_TOPIC, {
                error = ERROR_HUB_CREATION_FAILED,
                message = "Failed to create user hub"
            })

            return
        end

        -- Send redirection control message to WebSocket relay
        process.send(client_pid, WS_CONTROL_TOPIC, {
            target_pid = user_hub_pid,
            metadata = metadata
        })

        -- Update stats
        if state.user_hubs[user_id] then
            state.user_hubs[user_id].last_activity = time.now()
        end
    end

    -- Function to create a new user hub for a specific user
    function create_user_hub(state, user_id, metadata)
        -- Check if a hub already exists for this user
        if state.user_hubs[user_id] and state.user_hubs[user_id].hub_pid then
            return state.user_hubs[user_id].hub_pid
        end

        -- User metadata
        local user_metadata = metadata.user_metadata or {}

        -- Create a new actor for this user
        local user_actor = security.new_actor(user_id, user_metadata)

        -- Get the user scope
        local USER_SCOPE = "app.security:user"
        local user_scope, scope_err = security.named_scope(USER_SCOPE)

        -- Create a new user hub for this user
        -- Spawn a monitored user hub process with actor and scope
        local hub_pid, err = process.with_context({}):with_scope(user_scope):with_actor(user_actor):spawn_monitored(
            USER_HUB_PROCESS_ID,
            USER_HUB_HOST,
            {
                user_id = user_id,
                user_metadata = user_metadata,
                inactivity_timeout = USER_HUB_INACTIVITY_TIMEOUT,
                central_hub_pid = process.pid(),
                actor_id = current_actor and current_actor:id() or nil,
                actor_scope = user_scope,
                actor = current_actor
            }
        )

        if not hub_pid then
            return nil
        end

        -- Store the hub information
        state.user_hubs[user_id] = {
            hub_pid = hub_pid,
            created_at = time.now(),
            last_activity = time.now(),
            client_count = 0,
            messages_handled = 0,
        }

        state.total_hubs = state.total_hubs + 1

        return hub_pid
    end

    -- Function to check for inactive user hubs
    function check_inactive_hubs(state)
        local now = time.now()
        local inactivity_duration = time.parse_duration(USER_HUB_INACTIVITY_TIMEOUT)

        for user_id, hub_info in pairs(state.user_hubs) do
            -- Skip hubs that are already being terminated
            if hub_info.terminating then
                goto continue
            end

            -- Only check hubs with no clients
            if hub_info.client_count > 0 then
                goto continue
            end

            -- Check if hub has been inactive for too long
            local last_activity_time = hub_info.last_activity or hub_info.created_at
            local time_since_activity = now:sub(last_activity_time)

            -- If hub has no clients and has been inactive for too long, terminate it
            if time_since_activity:seconds() > inactivity_duration:seconds() then
                local success, err = process.cancel(hub_info.hub_pid, "10s")
                print("terminating user hub", user_id)
                if success then
                    -- Mark as being terminated to avoid repeated termination attempts
                    hub_info.terminating = true
                    hub_info.termination_started_at = now
                end
            end

            ::continue::
        end
    end

    return actor.new(initial_state, handlers).run()
end

return { run = run }
