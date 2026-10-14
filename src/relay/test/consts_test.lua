local test = require("test")
local consts = require("consts")

local function define_tests()
    test.describe("consts", function()
        test.describe("constants", function()
            test.it("defines registry names", function()
                test.eq(consts.CENTRAL_HUB_REGISTRY_NAME, "wippy.central")
                test.eq(consts.USER_HUB_REGISTRY_PREFIX, "user.")
                test.eq(consts.USER_HUB_PROCESS_ID, "wippy.relay:user")
            end)

            test.it("defines WebSocket topics", function()
                test.eq(consts.WS_TOPICS.JOIN, "ws.join")
                test.eq(consts.WS_TOPICS.LEAVE, "ws.leave")
                test.eq(consts.WS_TOPICS.MESSAGE, "ws.message")
                test.eq(consts.WS_TOPICS.CANCEL, "ws.cancel")
                test.eq(consts.WS_TOPICS.CONTROL, "ws.control")
                test.eq(consts.WS_TOPICS.HEARTBEAT, "ws.heartbeat")
            end)

            test.it("defines hub topics", function()
                test.eq(consts.HUB_TOPICS.ACTIVITY_UPDATE, "hub.activity_update")
            end)

            test.it("defines client topics", function()
                test.eq(consts.CLIENT_TOPICS.WELCOME, "welcome")
                test.eq(consts.CLIENT_TOPICS.ERROR, "error")
            end)

            test.it("defines error codes", function()
                test.eq(consts.ERROR_CODES.MAX_CONNECTIONS, "max_connections_reached")
                test.eq(consts.ERROR_CODES.MISSING_USER_ID, "missing_user_id")
                test.eq(consts.ERROR_CODES.HUB_CREATION_FAILED, "hub_creation_failed")
                test.eq(consts.ERROR_CODES.INVALID_JSON, "invalid_json")
                test.eq(consts.ERROR_CODES.UNKNOWN_COMMAND, "unknown_command")
                test.eq(consts.ERROR_CODES.PLUGIN_NOT_FOUND, "plugin_not_found")
                test.eq(consts.ERROR_CODES.PLUGIN_FAILED, "plugin_failed")
            end)

            test.it("defines plugin constants", function()
                test.eq(consts.PLUGIN_META_TYPE, "relay.plugin")
                test.eq(consts.PLUGIN_MESSAGE_TOPIC, "plugin_message")
                test.eq(consts.MAX_PLUGIN_RESTARTS, 1)
            end)

            test.it("defines defaults", function()
                test.eq(consts.DEFAULTS.MAX_CONNECTIONS_PER_USER, 10)
                test.eq(consts.DEFAULTS.USER_HUB_INACTIVITY_TIMEOUT, "7200s")
                test.eq(consts.DEFAULTS.QUEUE_MULTIPLIER, 100)
                test.is_nil(consts.DEFAULTS.HOST)
                test.is_nil(consts.DEFAULTS.USER_SECURITY_SCOPE)
            end)

            test.it("defines cancel timeout", function()
                test.eq(consts.CANCEL_TIMEOUT, "10s")
            end)
        end)

        test.describe("get_config", function()
            test.it("returns config with default values", function()
                local config = consts.get_config()

                test.not_nil(config)
                test.is_number(config.max_connections_per_user)
                test.is_string(config.user_hub_inactivity_timeout)
                test.is_number(config.queue_multiplier)
            end)

            test.it("computes message_queue_size from connections and multiplier", function()
                local config = consts.get_config()

                test.eq(config.message_queue_size, config.max_connections_per_user * config.queue_multiplier)
            end)

            test.it("computes gc_check_interval from inactivity timeout", function()
                local config = consts.get_config()

                test.is_string(config.gc_check_interval)
                test.matches(config.gc_check_interval, "%d+s")
            end)

            test.it("computes heartbeat_interval from inactivity timeout", function()
                local config = consts.get_config()

                test.is_string(config.heartbeat_interval)
                test.matches(config.heartbeat_interval, "%d+s")
            end)

            test.it("gc_check_interval is shorter than inactivity timeout", function()
                local config = consts.get_config()

                local gc_seconds = tonumber(config.gc_check_interval:match("(%d+)"))
                local heartbeat_seconds = tonumber(config.heartbeat_interval:match("(%d+)"))

                test.not_nil(gc_seconds)
                test.not_nil(heartbeat_seconds)
                test.gt(gc_seconds, heartbeat_seconds)
            end)

            test.it("returns env IDs for all config variables", function()
                test.is_string(consts.ENV_IDS.MAX_CONNECTIONS_PER_USER)
                test.is_string(consts.ENV_IDS.USER_HUB_INACTIVITY_TIMEOUT)
                test.is_string(consts.ENV_IDS.QUEUE_MULTIPLIER)
                test.is_string(consts.ENV_IDS.HOST)
                test.is_string(consts.ENV_IDS.USER_SECURITY_SCOPE)
            end)
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
