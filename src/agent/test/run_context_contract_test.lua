local test = require("test")
local registry = require("registry")
local json = require("json")

local function assert_rejected(schema, value)
    local valid, err = json.validate(schema, value)
    test.is_false(valid)
    test.not_nil(err)
end

local function define_tests()
    test.describe("Runner-neutral run context contract", function()
        local methods
        test.before_all(function()
            local entry, err = registry.get("wippy.agent:run_context")
            test.is_nil(err)
            test.not_nil(entry)
            methods = {}
            for _, method in ipairs(entry.data.methods) do methods[method.name] = method end
        end)

        test.it("rejects a host without its stable opaque identity", function()
            local context_schema = assert(json.decode(methods.get_context.input_schemas[1].definition))
            local host = context_schema.properties.host.properties
            test.eq(host.kind.type, "string")
            test.is_nil(host.kind.enum)
            test.eq(host.id.type, "string")
            for _, method_name in ipairs({ "get_context", "get_history", "get_prompt" }) do
                local schema = assert(json.decode(methods[method_name].input_schemas[1].definition))
                assert_rejected(schema, { host = { kind = "automation" } })
            end
        end)

        test.it("rejects history events without an authoritative author", function()
            local schema = assert(json.decode(methods.get_history.output_schemas[1].definition))
            local event = schema.properties.events.items.properties
            test.not_nil(event)
            test.eq(event.author.type, "object")
            test.eq(event.author.properties.kind.type, "string")
            test.eq(event.author.properties.id.type, "string")
            assert_rejected(schema, { events = { { id = "event-1", role = "user" } } })
        end)

        test.it("rejects identified authors without their identity", function()
            local schema = assert(json.decode(methods.get_history.output_schemas[1].definition))
            assert_rejected(schema, { events = { {
                id = "event-1", role = "user", author = { kind = "user" },
            } } })
            assert_rejected(schema, { events = { {
                id = "event-2", role = "assistant", author = { kind = "agent" },
            } } })
        end)

        test.it("accepts system and unknown context without a claimed identity", function()
            local schema = assert(json.decode(methods.get_history.output_schemas[1].definition))
            local valid, err = json.validate(schema, { events = {
                { id = "event-1", role = "tool", author = { kind = "system" } },
                { id = "event-2", role = "user", author = { kind = "unknown" } },
            } })
            test.is_true(valid)
            test.is_nil(err)
        end)

        test.it("accepts document provenance without claiming an importing identity", function()
            local schema = assert(json.decode(methods.get_history.output_schemas[1].definition))
            local valid, err = json.validate(schema, { events = {
                { id = "document-1", role = "document", author = { kind = "document" } },
            } })
            test.is_true(valid)
            test.is_nil(err)
        end)
    end)
end

return { run_tests = test.run_cases(define_tests) }
