local test = require("test")
local time = require("time")
local consts = require("consts")
local security = require("security")

local function define_tests()
    test.describe("relay user hub", function()
        test.it("sends a legacy-compatible welcome payload on join", function()
            local actor = security.new_actor("relay-user-test@wippy.local", {})
            local scope = security.named_scope("app:user")

            local hub_pid, spawn_err = process.with_context({})
                :with_actor(actor)
                :with_scope(scope)
                :spawn_linked_monitored(
                    consts.USER_HUB_PROCESS_ID,
                    "wippy.terminal:host",
                    {
                        user_id = "relay-user-test@wippy.local",
                        user_metadata = {},
                        plugins = {},
                        config = consts.get_config(),
                    }
                )

            test.expect(spawn_err).to_be_nil()
            test.expect(hub_pid).not_to_be_nil()

            local welcome = process.listen(consts.CLIENT_TOPICS.WELCOME)
            process.send(hub_pid :: string, consts.WS_TOPICS.JOIN, { client_pid = process.pid() })

            local timer = time.after(3000 * time.MILLISECOND)
            local res = channel.select({ welcome:case_receive(), timer:case_receive() })

            test.expect(res.channel == timer).to_be_falsy()
            test.expect(res.value).not_to_be_nil()
            test.expect(res.value.user_id).to_equal("relay-user-test@wippy.local")
            test.expect(type(res.value.plugins)).to_equal("table")
            test.expect(type(res.value.active_session_ids)).to_equal("table")
            test.expect(#res.value.active_session_ids).to_equal(0)
            test.expect(res.value.active_sessions).to_equal(0)

            process.cancel(hub_pid :: string, consts.CANCEL_TIMEOUT)
        end)
    end)
end

return { run = test.run_cases(define_tests) }
