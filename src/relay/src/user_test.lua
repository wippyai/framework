local test = require("test")
local time = require("time")
local consts = require("consts")
local security = require("security")

local function define_tests()
    test.describe("relay user hub", function()
        test.it("sends a legacy-compatible welcome payload on join", function()
            local actor = security.new_actor("relay-user-test@wippy.local", {})
            local scope, scope_err = security.named_scope("app:user")
            test.is_nil(scope_err)

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

            test.is_nil(spawn_err)
            test.not_nil(hub_pid)

            local welcome = process.listen(consts.CLIENT_TOPICS.WELCOME)
            local send_ok, send_err = process.send(hub_pid :: string, consts.WS_TOPICS.JOIN, { client_pid = process.pid() })
            test.is_nil(send_err)

            local timer = time.after(3000 * time.MILLISECOND)
            local res = channel.select({ welcome:case_receive(), timer:case_receive() })

            test.is_false(res.channel == timer)
            test.not_nil(res.value)
            test.eq(res.value.user_id, "relay-user-test@wippy.local")
            test.eq(type(res.value.plugins), "table")
            test.eq(type(res.value.active_session_ids), "table")
            test.eq(#res.value.active_session_ids, 0)
            test.eq(res.value.active_sessions, 0)

            process.cancel(hub_pid :: string, consts.CANCEL_TIMEOUT)
        end)
    end)
end

return { run = test.run_cases(define_tests) }
