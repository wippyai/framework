local test = require("test")
local route = require("route")

local function equal(actual: any, expected: any)
    if type(expected) ~= "table" then
        test.eq(actual, expected)
        return
    end
    test.eq(type(actual), "table")
    for key, value in pairs(expected) do equal(actual[key], value) end
    for key in pairs(actual) do test.ok(expected[key] ~= nil, "unexpected key " .. key) end
end

local function define_tests()
    describe("Route facts", function()
        it("keeps missing facts unknown", function()
            equal(route.accepts(nil, nil, "resolved"), {})
        end)
        it("maps every legacy route field", function()
            equal(route.accepts({ options = { reasoning_model_request = true } }, {}, "resolved"),
                { thinking = "adaptive", sampling = false })
            equal(route.accepts({ options = { reasoning_model_request = false } }, {}, "resolved"), {})
            equal(route.accepts({ options = { model_profile = {
                thinking_mode = "adaptive_only", forced_tool_choice = false, structured_output_mode = "native"
            } } }, {}, "resolved"), { thinking = "adaptive", forced_tool_choice = false, structured_output = "native" })
            equal(route.accepts({ options = { model_profile = { forced_tool_choice = true } } }, {}, "resolved"),
                { forced_tool_choice = true })
        end)
        it("lets canonical facts win over legacy and caller facts", function()
            equal(route.accepts({ thinking = "none", sampling = true, forced_tool_choice = true,
                structured_output = "tool", options = { reasoning_model_request = true, model_profile = {
                    forced_tool_choice = false, structured_output_mode = "native"
                } } }, { reasoning_model_request = true, model_profile = { forced_tool_choice = false } }, "resolved"),
                { thinking = "none", sampling = true, forced_tool_choice = true, structured_output = "tool" })
        end)
        it("applies per-call legacy reasoning without overriding canonical declarations", function()
            equal(route.accepts({ sampling = true }, { reasoning_model_request = true }, "resolved"),
                { thinking = "adaptive", sampling = true })
            equal(route.accepts({}, { reasoning_model_request = true }, "direct"),
                { thinking = "adaptive", sampling = false })
            equal(route.accepts({}, { reasoning_model_request = false }, "resolved"), {})
        end)
        it("lets a per-call legacy reasoning false turn off facts derived from the legacy route flag", function()
            equal(route.accepts({ options = { reasoning_model_request = true } },
                { reasoning_model_request = false }, "resolved"), {})
            equal(route.accepts({ thinking = "adaptive", options = { reasoning_model_request = true } },
                { reasoning_model_request = false }, "resolved"), { thinking = "adaptive" })
        end)
        it("maps direct caller profiles and gives accepts precedence", function()
            equal(route.accepts({ id = "direct" }, { reasoning_model_request = true,
                model_profile = { thinking_mode = "adaptive_only", forced_tool_choice = false,
                    structured_output_mode = "native" },
                accepts = { thinking = "budget", sampling = true } }, "direct"),
                { thinking = "budget", sampling = true, forced_tool_choice = false, structured_output = "native" })
        end)
        it("rejects resolved caller accepts and ignores caller profiles", function()
            local facts, err = route.accepts({ id = "route-id" }, { accepts = {} }, "resolved")
            test.is_nil(facts)
            test.contains(err, "route-id")
            test.contains(err, "accepts")
            equal(route.accepts({}, { model_profile = { thinking_mode = "adaptive_only" } }, "resolved"), {})
        end)
        it("validates each canonical fact in both modes", function()
            for key, allowed in pairs({ thinking = "adaptive", sampling = "boolean",
                forced_tool_choice = "boolean", structured_output = "native" }) do
                for _, value in ipairs({ "unknown", 12, {} }) do
                    for _, mode in ipairs({ "direct", "resolved" }) do
                        local ref = { id = "bad-route" }
                        local options = {}
                        if mode == "direct" then options.accepts = { [key] = value }
                        else ref[key] = value end
                        local facts, err = route.accepts(ref, options, mode)
                        test.is_nil(facts)
                        test.contains(err, "bad-route")
                        test.contains(err, key)
                        test.contains(err, allowed)
                    end
                end
            end
        end)
        it("rejects non-table accepts and unknown accepts keys", function()
            for _, value in ipairs({ false, "adaptive", { unexpected = true } }) do
                local facts, err = route.accepts({ id = "direct" }, { accepts = value }, "direct")
                test.is_nil(facts)
                test.contains(err, "accepts")
            end
        end)
        it("cleans fact options without mutating the caller", function()
            local options = { reasoning_model_request = true, model_profile = {}, accepts = {}, temperature = 0.4 }
            equal(route.clean_options(options), { temperature = 0.4 })
            equal(options.reasoning_model_request, true)
        end)
    end)

    describe("Route capability helpers", function()
        local capability = {
            name = "Test",
            defaults = { thinking = "budget", sampling = true, forced_tool_choice = true, structured_output = "tool" },
            supported = { thinking = { adaptive = true, none = true }, structured_output = { native = true } }
        }

        it("falls back to the driver default when a fact is undeclared", function()
            test.eq(route.fact(nil, "thinking", capability), "budget")
            test.eq(route.fact({}, "sampling", capability), true)
            test.eq(route.fact({ thinking = "none" }, "thinking", capability), "none")
            test.eq(route.fact({ forced_tool_choice = false }, "forced_tool_choice", capability), false)
        end)

        it("rejects a declared value outside the driver's supported set", function()
            local err = route.unsupported_fact_error({ thinking = "budget" }, capability)
            test.contains(err, "Test")
            test.contains(err, "thinking")
            test.contains(err, "budget")
            test.contains(err, "adaptive")
            test.contains(err, "none")
        end)

        it("accepts a declared value within the driver's supported set", function()
            test.is_nil(route.unsupported_fact_error({ thinking = "adaptive" }, capability))
            test.is_nil(route.unsupported_fact_error(nil, capability))
        end)

        it("does not restrict a fact the capability leaves unsupported-listed", function()
            test.is_nil(route.unsupported_fact_error({ sampling = false }, capability))
        end)

        it("builds a strict error naming every adjusted parameter, sorted", function()
            local err = route.strict_error("my-route", true, { top_p = {}, temperature = {} })
            test.contains(err, "my-route")
            local top_p_at = err:find("top_p")
            local temperature_at = err:find("temperature")
            test.is_true(top_p_at ~= nil and temperature_at ~= nil and temperature_at < top_p_at)
        end)

        it("returns no strict error when not strict or nothing was adjusted", function()
            test.is_nil(route.strict_error("r", false, { temperature = {} }))
            test.is_nil(route.strict_error("r", true, {}))
            test.is_nil(route.strict_error("r", true, nil))
        end)

        it("attaches nothing when no adjustment was recorded", function()
            local empty: any = {}
            route.attach_adjusted(empty, {})
            test.is_nil(empty.metadata)
        end)

        it("attaches adjustments to metadata when at least one was recorded", function()
            local result: any = {}
            route.attach_adjusted(result, { temperature = { requested = 0.4 } })
            test.eq(result.metadata.adjusted.temperature.requested, 0.4)
        end)

        it("rejects forced structured output on a route that forbids forcing", function()
            local err = route.forced_tool_output_error({ forced_tool_choice = false }, capability)
            test.contains(err, "forced_tool_choice")

            test.is_nil(route.forced_tool_output_error({ forced_tool_choice = false, structured_output = "native" },
                { name = "Test", defaults = {}, supported = {} }))
            test.is_nil(route.forced_tool_output_error({ forced_tool_choice = true }, capability))
        end)
    end)
end

return test.run_cases(define_tests)
