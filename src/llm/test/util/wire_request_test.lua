local test = require("test")
local wire_request = require("wire_request")
local json = require("json")

local function define_tests()
    describe("Wire request merge", function()
        local reserved = { "model", "messages" }

        it("leaves the body unchanged without a request", function()
            local body = { model = "m", max_tokens = 10 }
            test.is_nil(wire_request.apply(body, nil, reserved))
            test.eq(body.model, "m")
            test.eq(body.max_tokens, 10)
        end)

        it("merges maps recursively and lets request values win", function()
            local body = { thinking = { type = "adaptive" }, output_config = { effort = "medium", format = { type = "x" } } }
            local err = wire_request.apply(body, {
                thinking = { type = "between_tools" },
                output_config = { effort = "low" },
                top_k = 3
            }, reserved)
            test.is_nil(err)
            test.eq(body.thinking.type, "between_tools")
            test.eq(body.output_config.effort, "low")
            test.eq(body.output_config.format.type, "x")
            test.eq(body.top_k, 3)
        end)

        it("rejects a request naming a reserved nested path", function()
            local body = { text = { verbosity = "low", format = { type = "json_schema" } } }
            local err = wire_request.apply(body, { text = { format = { type = "json_object" } } }, { "text.format" })
            test.contains(err, "text.format")
            test.eq(body.text.format.type, "json_schema")
            test.is_nil(wire_request.apply(body, { text = { verbosity = "high" } }, { "text.format" }))
            test.eq(body.text.verbosity, "high")
            test.eq(body.text.format.type, "json_schema")
        end)

        it("keeps an empty object an object on the wire", function()
            local body = { model = "m" }
            test.is_nil(wire_request.apply(body, json.decode('{"metadata":{}}'), reserved))
            test.eq(json.encode(body.metadata), "{}")
        end)

        it("replaces arrays instead of merging them", function()
            local body = { stop_sequences = { "a", "b", "c" } }
            test.is_nil(wire_request.apply(body, { stop_sequences = { "z" } }, reserved))
            test.eq(#body.stop_sequences, 1)
            test.eq(body.stop_sequences[1], "z")
        end)

        it("replaces a map with a scalar and a scalar with a map", function()
            local body = { thinking = { type = "adaptive" }, service_tier = "auto" }
            test.is_nil(wire_request.apply(body, { thinking = false, service_tier = { tier = "flex" } }, reserved))
            test.eq(body.thinking, false)
            test.eq(body.service_tier.tier, "flex")
        end)

        it("never writes into the body's nested tables or aliases the request", function()
            local shared = { effort = "medium" }
            local request = { output_config = { effort = "low", extra = { on = true } } }
            local body = { output_config = shared }
            test.is_nil(wire_request.apply(body, request, reserved))
            test.eq(shared.effort, "medium")
            body.output_config.extra.on = false
            test.is_true(request.output_config.extra.on)
        end)

        it("rejects a request setting a key the driver owns, naming the key", function()
            local body = { model = "m", messages = {} }
            local err = wire_request.apply(body, { messages = {}, top_k = 1 }, reserved)
            test.contains(err, "messages")
            test.is_nil(body.top_k)
        end)

        it("rejects a request that is not an object", function()
            for _, request in ipairs({ "thinking", 5, { "a" } }) do
                local err = wire_request.apply({}, request, reserved)
                test.contains(err, "options.request")
            end
        end)
    end)
end

return test.run_cases(define_tests)
