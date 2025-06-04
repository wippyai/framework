local time = require("time")
local json = require("json")
local actor = require("actor")
local uuid = require("uuid")
local funcs = require("funcs")
local security = require("security")

-- Registry constants
local USER_HUB_REGISTRY_PREFIX = "user."

-- WebSocket topics (external layer - cannot be changed)
local WS_JOIN_TOPIC = "ws.join"
local WS_LEAVE_TOPIC = "ws.leave"
local WS_MESSAGE_TOPIC = "ws.message"
local WS_CANCEL_TOPIC = "ws.cancel"
local WS_HEARTBEAT_TOPIC = "ws.heartbeat"

-- Topics we send to user clients
local CLIENT_WELCOME_TOPIC = "welcome"
local CLIENT_SESSION_OPENED_TOPIC = "session.opened"
local CLIENT_SESSION_CLOSED_TOPIC = "session.closed"
local CLIENT_ERROR_TOPIC = "error"

-- Topics we receive/send to sessions
local SESSION_MESSAGE_TOPIC = "message"
local SESSION_COMMAND_TOPIC = "command"
local SESSION_PROCESS_ID = "wippy.session.process:session"
local SESSION_HOST = "app:processes"

-- Topics we send to central hub
local HUB_ACTIVITY_UPDATE_TOPIC = "hub.activity_update"

-- Command types received from clients
local CMD_SESSION_OPEN = "session_open"
local CMD_SESSION_CLOSE = "session_close"
local CMD_SESSION_MESSAGE = "session_message"
local CMD_SESSION_COMMAND = "session_command"

-- Error codes
local ERROR_INVALID_JSON = "invalid_json"
local ERROR_SESSION_LIMIT = "session_limit_reached"
local ERROR_SESSION_ID_GEN = "session_id_gen_error"
local ERROR_SESSION_EXISTS = "session_exists"
local ERROR_SESSION_SPAWN = "session_spawn_error"
local ERROR_INVALID_SESSION_ID = "invalid_session_id"
local ERROR_SESSION_NOT_FOUND = "session_not_found"
local ERROR_INVALID_MESSAGE_TYPE = "invalid_message_type"

-- Session constants
local MAX_SESSIONS_PER_USER = 300 -- Maximum allowed sessions per user (todo: downgrade)

-- User Hub Process - Handles WebSocket connections and session management
local function run(args)
    -- Verify required arguments
    if not args or not args.user_id then
        return { error = "Missing required arguments" }
    end

    local user_id = args.user_id
    local user_metadata = args.user_metadata or {}
    local central_hub_pid = args.central_hub_pid

    -- Initialize actor state
    local initial_state = {
        user_id = user_id,
        metadata = user_metadata,
        connected_clients = {},
        client_count = 0,
        central_hub_pid = central_hub_pid,
        active_sessions = {}, -- Map of session_id -> session_pid
        session_count = 0     -- Counter for active sessions
    }

    -- Define handlers for different message topics
    local handlers = {
        -- Initialize the actor
        __init = function(state)
            -- Register this process with the user's ID for easy discovery
            local registry_name = USER_HUB_REGISTRY_PREFIX .. state.user_id
            process.registry.register(registry_name)

            -- Set process options to trap links for session monitoring
            process.set_options({ trap_links = true })

            return state
        end,

        -- Handle process termination events (especially for linked sessions)
        __on_event = function(state, event)
            if event.kind == process.event.LINK_DOWN or event.kind == process.event.EXIT then
                -- Find and remove the terminated session
                for session_id, pid in pairs(state.active_sessions) do
                    if pid == event.from then
                        local err = "terminated"
                        if event.result and event.result.error then
                            err = tostring(event.result.error)
                        end

                        state.active_sessions[session_id] = nil
                        state.session_count = state.session_count - 1
                        broadcast_to_clients(state, CLIENT_SESSION_CLOSED_TOPIC, {
                            session_id = session_id,
                            reason = err,
                            active_session_ids = get_active_session_ids(state)
                        })
                        break
                    end
                end
            end
            return state
        end,

        -- Handle cancellation
        __on_cancel = function(state)
            -- Cancel all active sessions
            for session_id, pid in pairs(state.active_sessions) do
                process.cancel(pid, "10s")
            end

            -- Notify clients about shutdown
            broadcast_to_clients(state, WS_CANCEL_TOPIC, {
                message = "Hub shutting down"
            })

            return actor.exit({ status = "shutdown" })
        end,

        -- Handle WebSocket join
        [WS_JOIN_TOPIC] = function(state, payload)
            local client_pid = payload.client_pid
            state.connected_clients[client_pid] = true
            state.client_count = state.client_count + 1

            -- Send welcome message with user ID and sessions
            process.send(client_pid, CLIENT_WELCOME_TOPIC, {
                user_id = state.user_id,
                client_count = state.client_count,
                active_sessions = state.session_count,
                active_session_ids = get_active_session_ids(state)
            })

            -- Notify central hub about client count change
            if state.central_hub_pid then
                process.send(state.central_hub_pid, HUB_ACTIVITY_UPDATE_TOPIC, {
                    user_id = state.user_id,
                    client_count = state.client_count,
                    last_activity = time.now():format_rfc3339()
                })
            end

            return state
        end,

        -- Handle WebSocket leave
        [WS_LEAVE_TOPIC] = function(state, payload)
            local client_pid = payload.client_pid
            if state.connected_clients[client_pid] then
                state.connected_clients[client_pid] = nil
                state.client_count = state.client_count - 1

                -- Notify central hub about client count change
                if state.central_hub_pid then
                    process.send(state.central_hub_pid, HUB_ACTIVITY_UPDATE_TOPIC, {
                        user_id = state.user_id,
                        client_count = state.client_count,
                        last_activity = time.now():format_rfc3339()
                    })
                end
            end
            return state
        end,

        -- Handle WebSocket messages
        [WS_MESSAGE_TOPIC] = function(state, payload, topic, from)
            local message_data, err = json.decode(payload)
            if not message_data then
                -- Send error back to the specific client that sent the malformed message
                process.send(from, CLIENT_ERROR_TOPIC, {
                    error = ERROR_INVALID_JSON,
                    message = "Failed to decode JSON message"
                })
                return state
            end

            local msg_type = message_data.type
            local data = message_data.data
            local session_id = message_data.session_id
            local request_id = message_data.request_id

            -- Route message based on type
            if msg_type == CMD_SESSION_OPEN then
                -- Check if maximum session limit is reached
                if state.session_count >= MAX_SESSIONS_PER_USER then
                    process.send(from, CLIENT_ERROR_TOPIC, {
                        error = ERROR_SESSION_LIMIT,
                        message = "Maximum session limit reached (" ..
                            MAX_SESSIONS_PER_USER .. " sessions). Please close an existing session.",
                        active_session_ids = get_active_session_ids(state),
                        request_id = request_id
                    })
                    return state
                end

                local create = true
                if not session_id then
                    -- Generate new session ID
                    local id, err = uuid.v7()
                    if err then
                        process.send(from, CLIENT_ERROR_TOPIC, {
                            error = ERROR_SESSION_ID_GEN,
                            message = "Failed to generate session ID: " .. err,
                            request_id = request_id
                        })
                        return state
                    end
                    session_id = id
                else
                    if state.active_sessions[session_id] then
                        broadcast_to_clients(state, CLIENT_SESSION_OPENED_TOPIC, {
                            session_id = session_id,
                            active_session_ids = get_active_session_ids(state),
                            request_id = request_id
                        })
                        return state
                    end

                    create = false
                end

                -- Create session init data
                local session_init = {
                    session_id = session_id,
                    user_id = state.user_id,
                    conn_pid = from,
                    parent_pid = process.pid(),
                    start_token = message_data.start_token,
                    start_context = message_data.context,
                    create = create
                }

                -- Spawn session process
                local session_pid, err = process.with_context({
                    session_id = session_id,
                    user_id = state.user_id,
                }):spawn_linked_monitored(
                    SESSION_PROCESS_ID,
                    SESSION_HOST,
                    session_init
                )

                if err then
                    process.send(from, CLIENT_ERROR_TOPIC, {
                        error = ERROR_SESSION_SPAWN,
                        message = "Failed to create session: " .. err,
                        request_id = request_id
                    })
                    return state
                end

                if session_pid then
                    state.active_sessions[session_id] = session_pid

                    state.session_count = state.session_count + 1
                    broadcast_to_clients(state, CLIENT_SESSION_OPENED_TOPIC, {
                        session_id = session_id,
                        active_session_ids = get_active_session_ids(state),
                        request_id = request_id
                    })
                end
            elseif msg_type == CMD_SESSION_CLOSE then
                -- Validate session ID is provided
                if not session_id then
                    process.send(from, CLIENT_ERROR_TOPIC, {
                        error = ERROR_INVALID_SESSION_ID,
                        message = "Session ID is required for closing a session",
                        request_id = request_id
                    })
                    return state
                end

                -- Close session if it exists
                local session_pid = state.active_sessions[session_id]
                if session_pid then
                    if #state.active_sessions > 1 then
                        -- this will keep last session always on for user, avoiding uncessesary restarts
                        process.cancel(session_pid)
                        state.active_sessions[session_id] = nil
                        state.session_count = state.session_count - 1
                        broadcast_to_clients(state, CLIENT_SESSION_CLOSED_TOPIC, {
                            session_id = session_id,
                            active_session_ids = get_active_session_ids(state),
                            request_id = request_id
                        })
                    end
                else
                    -- Send error when trying to close non-existent session
                    process.send(from, CLIENT_ERROR_TOPIC, {
                        error = ERROR_SESSION_NOT_FOUND,
                        message = "Cannot close session: session ID not found or invalid",
                        request_id = request_id
                    })
                end
            elseif msg_type == CMD_SESSION_MESSAGE then
                -- Validate session ID is provided
                if not session_id then
                    process.send(from, CLIENT_ERROR_TOPIC, {
                        error = ERROR_INVALID_SESSION_ID,
                        message = "Session ID is required for sending a message",
                        request_id = request_id
                    })
                    return state
                end

                -- Forward message to session if it exists
                local session_pid = state.active_sessions[session_id]
                if session_pid then
                    process.send(session_pid, SESSION_MESSAGE_TOPIC, {
                        conn_pid = from,
                        data = data,
                        request_id = request_id
                    })
                else
                    process.send(from, CLIENT_ERROR_TOPIC, {
                        error = ERROR_SESSION_NOT_FOUND,
                        message = "Session not found: " .. session_id,
                        request_id = request_id
                    })
                end
            elseif msg_type == CMD_SESSION_COMMAND then
                -- Validate session ID is provided
                if not session_id then
                    process.send(from, CLIENT_ERROR_TOPIC, {
                        error = ERROR_INVALID_SESSION_ID,
                        message = "Session ID is required for sending a command",
                        request_id = request_id
                    })
                    return state
                end

                -- Forward command to session if it exists
                local session_pid = state.active_sessions[session_id]
                if session_pid then
                    data["conn_pid"] = from

                    -- Include request_id in the command data if available
                    if request_id then
                        data["request_id"] = request_id
                    end

                    process.send(session_pid, SESSION_COMMAND_TOPIC, data)
                else
                    -- Send error when trying to send command to a non-existent session
                    process.send(from, CLIENT_ERROR_TOPIC, {
                        error = ERROR_SESSION_NOT_FOUND,
                        message = "Cannot send command: session ID not found or invalid",
                        request_id = request_id
                    })
                end
            else
                -- Unrecognized message type
                process.send(from, CLIENT_ERROR_TOPIC, {
                    error = ERROR_INVALID_MESSAGE_TYPE,
                    message = "Unrecognized message type: " .. (msg_type or "nil"),
                    request_id = request_id
                })
            end

            return state
        end,

        -- Forward any other messages to clients (including responses from sessions)
        __default = function(state, payload, topic)
            if topic == WS_HEARTBEAT_TOPIC then
                return state
            end

            broadcast_to_clients(state, topic, payload)
            return state
        end
    }

    -- Helper function to broadcast a message to all connected clients
    function broadcast_to_clients(state, topic, message)
        for client_pid, _ in pairs(state.connected_clients) do
            process.send(client_pid, topic, message)
        end
    end

    -- Helper function to get all active session IDs as an array
    function get_active_session_ids(state)
        local session_ids = {}
        for session_id, _ in pairs(state.active_sessions) do
            table.insert(session_ids, session_id)
        end
        return session_ids
    end

    -- Create and run the actor
    local user_hub_actor = actor.new(initial_state, handlers)
    return user_hub_actor.run()
end

return { run = run }
