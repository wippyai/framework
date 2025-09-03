local env = require("env")
local time = require("time")

local consts = {
    -- Registry names
    CENTRAL_HUB_REGISTRY_NAME = "wippy.central",
    USER_HUB_REGISTRY_PREFIX = "user.",
    USER_HUB_PROCESS_ID = "wippy.relay:user",

    -- Environment variable IDs
    ENV_IDS = {
        MAX_CONNECTIONS_PER_USER = "wippy.relay.env:max_connections_per_user",
        USER_HUB_INACTIVITY_TIMEOUT = "wippy.relay.env:user_hub_inactivity_timeout",
        QUEUE_MULTIPLIER = "wippy.relay.env:queue_multiplier",
        HOST = "wippy.relay.env:host",
        USER_SECURITY_SCOPE = "wippy.relay.env:user_security_scope"
    },

    -- WebSocket topics
    WS_TOPICS = {
        JOIN = "ws.join",
        LEAVE = "ws.leave",
        MESSAGE = "ws.message",
        CANCEL = "ws.cancel",
        CONTROL = "ws.control",
        HEARTBEAT = "ws.heartbeat"
    },

    -- Hub topics
    HUB_TOPICS = {
        ACTIVITY_UPDATE = "hub.activity_update"
    },

    -- Client topics
    CLIENT_TOPICS = {
        WELCOME = "welcome",
        ERROR = "error"
    },

    -- Error codes
    ERROR_CODES = {
        MAX_CONNECTIONS = "max_connections_reached",
        MISSING_USER_ID = "missing_user_id",
        HUB_CREATION_FAILED = "hub_creation_failed",
        INVALID_JSON = "invalid_json",
        UNKNOWN_COMMAND = "unknown_command",
        PLUGIN_NOT_FOUND = "plugin_not_found",
        PLUGIN_FAILED = "plugin_failed"
    },

    -- Plugin constants
    PLUGIN_META_TYPE = "relay.plugin",
    PLUGIN_MESSAGE_TOPIC = "plugin_message",
    MAX_PLUGIN_RESTARTS = 1,

    -- Defaults
    DEFAULTS = {
        MAX_CONNECTIONS_PER_USER = 10,
        USER_HUB_INACTIVITY_TIMEOUT = "300s",
        QUEUE_MULTIPLIER = 100,
        HOST = nil,
        USER_SECURITY_SCOPE = nil
    },

    -- Fixed timeouts
    CANCEL_TIMEOUT = "10s"
}

function consts.get_config()
    -- Get base values from environment
    local max_conn, _ = env.get(consts.ENV_IDS.MAX_CONNECTIONS_PER_USER)
    local max_connections = (max_conn and tonumber(max_conn)) or consts.DEFAULTS.MAX_CONNECTIONS_PER_USER

    local timeout_str, _ = env.get(consts.ENV_IDS.USER_HUB_INACTIVITY_TIMEOUT)
    local inactivity_timeout = timeout_str or consts.DEFAULTS.USER_HUB_INACTIVITY_TIMEOUT

    local mult, _ = env.get(consts.ENV_IDS.QUEUE_MULTIPLIER)
    local queue_multiplier = (mult and tonumber(mult)) or consts.DEFAULTS.QUEUE_MULTIPLIER

    local host, _ = env.get(consts.ENV_IDS.HOST)
    local user_hub_host = host or consts.DEFAULTS.HOST

    local scope, _ = env.get(consts.ENV_IDS.USER_SECURITY_SCOPE)
    local user_security_scope = scope or consts.DEFAULTS.USER_SECURITY_SCOPE

    -- Parse inactivity timeout for derived calculations
    local inactivity_duration, _ = time.parse_duration(inactivity_timeout)
    local inactivity_seconds = inactivity_duration and inactivity_duration:seconds() or 300

    -- Calculate derived values
    local gc_seconds = math.floor(inactivity_seconds / 2.5)
    local heartbeat_seconds = math.floor(inactivity_seconds / 5)

    return {
        -- Base configuration
        max_connections_per_user = max_connections,
        user_hub_inactivity_timeout = inactivity_timeout,
        queue_multiplier = queue_multiplier,
        user_hub_host = user_hub_host,
        user_security_scope = user_security_scope,

        -- Derived values
        message_queue_size = max_connections * queue_multiplier,
        gc_check_interval = tostring(gc_seconds) .. "s",
        heartbeat_interval = tostring(heartbeat_seconds) .. "s"
    }
end

return consts
