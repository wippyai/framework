local test = require("test")
local fallback = require("fallback")

local function names(routes: {any}): {string}
    local out: {string} = {}
    for _, route in ipairs(routes) do
        table.insert(out, tostring(route.name))
    end
    return out
end

local function define_tests()
    describe("Fallback policy", function()
        describe("set_of", function()
            it("builds a membership set from a list", function()
                local set = fallback.set_of({ "a", "b" })
                test.is_true(set.a)
                test.is_true(set.b)
                test.is_nil(set.c)
            end)
        end)

        describe("string_list", function()
            it("returns nil for anything but a table", function()
                test.is_nil(fallback.string_list(nil))
                test.is_nil(fallback.string_list("gpt-4o"))
                test.is_nil(fallback.string_list(42))
            end)

            it("keeps non-empty strings in order and drops everything else", function()
                local list = fallback.string_list({ "a", "", 3, "b", false, "c" }) :: {string}
                test.eq(#list, 3)
                test.eq(list[1], "a")
                test.eq(list[2], "b")
                test.eq(list[3], "c")
            end)

            it("returns an empty list for an empty table", function()
                local list = fallback.string_list({}) :: {string}
                test.eq(#list, 0)
            end)
        end)

        describe("ordered_routes", function()
            it("orders routes by descending priority", function()
                local card = { providers = {
                    { name = "low", priority = 10 },
                    { name = "high", priority = 100 },
                    { name = "mid", priority = 50 },
                } }
                local order = names(fallback.ordered_routes(card))
                test.eq(order[1], "high")
                test.eq(order[2], "mid")
                test.eq(order[3], "low")
            end)

            it("counts a missing priority as zero", function()
                local card = { providers = {
                    { name = "unset" },
                    { name = "negative", priority = -1 },
                    { name = "positive", priority = 1 },
                } }
                local order = names(fallback.ordered_routes(card))
                test.eq(order[1], "positive")
                test.eq(order[2], "unset")
                test.eq(order[3], "negative")
            end)

            it("keeps list order between equal priorities", function()
                local providers = {}
                for i = 1, 12 do
                    table.insert(providers, { name = "r" .. tostring(i), priority = (i % 2 == 0) and 5 or nil })
                end
                local order = names(fallback.ordered_routes({ providers = providers }))
                test.eq(#order, 12)
                local expected = { "r2", "r4", "r6", "r8", "r10", "r12", "r1", "r3", "r5", "r7", "r9", "r11" }
                for i, name in ipairs(expected) do
                    test.eq(order[i], name)
                end
            end)

            it("accepts a numeric string priority", function()
                local order = names(fallback.ordered_routes({ providers = {
                    { name = "plain", priority = 5 },
                    { name = "string", priority = "50" },
                } }))
                test.eq(order[1], "string")
            end)

            it("skips entries that are not tables and copes with a card without routes", function()
                local order = names(fallback.ordered_routes({ providers = { "bogus", { name = "only" } } }))
                test.eq(#order, 1)
                test.eq(order[1], "only")
                test.eq(#fallback.ordered_routes({}), 0)
                test.eq(#fallback.ordered_routes({ providers = "nope" }), 0)
                test.eq(#fallback.ordered_routes(nil), 0)
            end)

            it("does not reorder the card's own list", function()
                local card = { providers = { { name = "a" }, { name = "b", priority = 9 } } }
                fallback.ordered_routes(card)
                test.eq(card.providers[1].name, "a")
                test.eq(card.providers[2].name, "b")
            end)
        end)

        describe("find_route", function()
            local card = { providers = {
                { name = "direct", id = "p.claude", provider_model = "claude-a" },
                { name = "bedrock", id = "p.bedrock", provider_model = "claude-a-bedrock", priority = 10 },
                { name = "direct-b", id = "p.claude", provider_model = "claude-b" },
            } }

            it("finds a route by provider id in chain order", function()
                local found = fallback.find_route(card, "p.claude")
                test.eq(found.name, "direct")
                test.eq(fallback.find_route(card, "p.bedrock").name, "bedrock")
            end)

            it("narrows by provider model when one is given", function()
                test.eq(fallback.find_route(card, "p.claude", "claude-b").name, "direct-b")
            end)

            it("returns nil when nothing matches", function()
                test.is_nil(fallback.find_route(card, "p.openai"))
                test.is_nil(fallback.find_route(card, "p.claude", "claude-z"))
                test.is_nil(fallback.find_route({}, "p.claude"))
            end)
        end)

        describe("should_switch", function()
            local default_on = fallback.set_of(fallback.DEFAULT_FALLBACK_ON)

            it("never switches without details or without an error type", function()
                test.is_false(fallback.should_switch(nil, true, false, default_on))
                test.is_false(fallback.should_switch(nil, false, false, default_on))
                test.is_false(fallback.should_switch({}, true, false, default_on))
                test.is_false(fallback.should_switch({ status_code = 503 }, false, false, default_on))
                test.is_false(fallback.should_switch({ error_type = 42 }, false, false, default_on))
            end)

            it("switches the primary on the default transient types only", function()
                for _, error_type in ipairs({ "rate_limit_exceeded", "server_error", "timeout_error", "network_error" }) do
                    test.is_true(fallback.should_switch({ error_type = error_type }, true, false, default_on), error_type)
                end
                for _, error_type in ipairs({ "authentication_error", "model_error", "context_length_exceeded",
                    "invalid_request", "content_filtered" }) do
                    test.is_false(fallback.should_switch({ error_type = error_type }, true, false, default_on), error_type)
                end
            end)

            it("switches the primary on exactly the types a card lists", function()
                local custom = fallback.set_of({ "authentication_error", "content_filtered" })
                test.is_true(fallback.should_switch({ error_type = "authentication_error" }, true, false, custom))
                test.is_true(fallback.should_switch({ error_type = "content_filtered" }, true, false, custom))
                test.is_false(fallback.should_switch({ error_type = "server_error" }, true, false, custom))
            end)

            it("moves past a fallback candidate on transient and candidate failures", function()
                for _, error_type in ipairs({ "rate_limit_exceeded", "server_error", "timeout_error", "network_error",
                    "authentication_error", "model_error", "context_length_exceeded" }) do
                    test.is_true(fallback.should_switch({ error_type = error_type }, false, false, {}), error_type)
                end
            end)

            it("stops at a fallback candidate when the request itself is unusable", function()
                test.is_false(fallback.should_switch({ error_type = "invalid_request" }, false, false, default_on))
                test.is_false(fallback.should_switch({ error_type = "content_filtered" }, false, false, default_on))
                test.is_false(fallback.should_switch({ error_type = "something_new" }, false, false, default_on))
            end)

            it("requires a streaming driver to report that nothing was sent", function()
                test.is_false(fallback.should_switch({ error_type = "server_error" }, true, true, default_on))
                test.is_false(fallback.should_switch({ error_type = "server_error", stream_started = true }, true, true, default_on))
                test.is_false(fallback.should_switch({ error_type = "server_error", stream_started = "no" }, false, true, default_on))
                test.is_true(fallback.should_switch({ error_type = "server_error", stream_started = false }, true, true, default_on))
                test.is_true(fallback.should_switch({ error_type = "model_error", stream_started = false }, false, true, default_on))
            end)

            it("ignores stream_started when the call does not stream", function()
                test.is_true(fallback.should_switch({ error_type = "server_error", stream_started = true }, true, false, default_on))
            end)
        end)

        describe("switch_set", function()
            it("uses the default set when nothing usable is configured", function()
                local cases: {any} = { {}, "server_error", 42, { 429, "" } }
                local sets = { fallback.switch_set(nil) }
                for _, value in ipairs(cases) do
                    table.insert(sets, fallback.switch_set(value))
                end
                test.eq(#sets, 5)
                for _, set in ipairs(sets) do
                    test.is_true(set.server_error)
                    test.is_true(set.rate_limit_exceeded)
                    test.is_true(set.timeout_error)
                    test.is_true(set.network_error)
                    test.is_nil(set.authentication_error)
                end
            end)

            it("uses exactly the configured types", function()
                local set = fallback.switch_set({ "authentication_error", "content_filtered" })
                test.is_true(set.authentication_error)
                test.is_true(set.content_filtered)
                test.is_nil(set.server_error)
            end)
        end)

        describe("capped_timeout", function()
            it("keeps a smaller timeout and caps a larger one", function()
                test.eq(fallback.capped_timeout(30, 60000), 30)
                test.eq(fallback.capped_timeout(600, 60000), 60)
            end)

            it("uses the remaining budget when the timeout is unset or not a number of seconds", function()
                test.eq(fallback.capped_timeout(nil, 42500), 42)
                test.eq(fallback.capped_timeout("30s", 42500), 42)
                test.eq(fallback.capped_timeout(0, 42500), 42)
                test.eq(fallback.capped_timeout(-5, 42500), 42)
            end)

            it("accepts a numeric string timeout", function()
                test.eq(fallback.capped_timeout("20", 42500), 20)
            end)

            it("never returns less than one second", function()
                test.eq(fallback.capped_timeout(nil, 200), 1)
                test.eq(fallback.capped_timeout(30, 0), 1)
                test.eq(fallback.capped_timeout(30, -100), 1)
            end)
        end)

        describe("error_details and error_message", function()
            it("reads details and message from a structured error", function()
                local err = errors.new({ message = "busy", kind = errors.UNAVAILABLE, details = { error_type = "server_error" } })
                local details = fallback.error_details(err) :: { [string]: any }
                test.eq(details.error_type, "server_error")
                test.eq(fallback.error_message(err), "busy")
            end)

            it("returns no details for strings, nil and plain tables", function()
                test.is_nil(fallback.error_details("boom"))
                test.is_nil(fallback.error_details(nil))
                test.is_nil(fallback.error_details({ message = "x" }))
            end)

            it("returns a plain string error as its own message", function()
                test.eq(fallback.error_message("Provider unavailable"), "Provider unavailable")
            end)

            it("stringifies a value without a message method", function()
                test.eq(fallback.error_message(42), "42")
            end)
        end)

        describe("summary", function()
            it("lists failed and skipped candidates in order", function()
                local text = fallback.summary({
                    { model = "claude", provider_id = "p.claude", error_type = "rate_limit_exceeded" },
                    { model = "gemini", skipped = true, message = "Model or class not found: gemini" },
                    { model = "gpt", provider_id = "p.openai" },
                })
                test.eq(text, "claude via p.claude: rate_limit_exceeded; gemini: skipped, "
                    .. "Model or class not found: gemini; gpt via p.openai: error")
            end)

            it("returns an empty string for no failures", function()
                test.eq(fallback.summary({}), "")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
