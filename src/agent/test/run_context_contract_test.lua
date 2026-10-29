local test = require("test")
local registry = require("registry")
local json = require("json")

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

        test.it("describes an open runner kind and stable opaque identity", function()
            local schema = assert(json.decode(methods.get_context.input_schemas[1].definition))
            local host = schema.properties.host.properties
            test.eq(host.kind.type, "string")
            test.is_nil(host.kind.enum)
            test.eq(host.id.type, "string")
        end)

        test.it("describes event authors independently of prompt roles", function()
            local schema = assert(json.decode(methods.get_history.output_schemas[1].definition))
            local event = schema.properties.events.items.properties
            test.not_nil(event)
            test.eq(event.author.type, "object")
            test.eq(event.author.properties.kind.type, "string")
            test.eq(event.author.properties.id.type, "string")
        end)
    end)
end

return { run_tests = test.run_cases(define_tests) }
