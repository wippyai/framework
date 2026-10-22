local test = require("test")
local json = require("json")
local registry = require("registry")

-- Model providers accept function parameters only when the schema root is a
-- plain object: type object, with no composition or enumeration at the top.
local ROOT_KEYWORDS = { "oneOf", "anyOf", "allOf", "not", "enum", "const" }

local function decoded(raw)
    if type(raw) == "table" then return raw, nil end
    if type(raw) ~= "string" then return nil, "input_schema is missing" end
    local value, err = json.decode(raw)
    if err or type(value) ~= "table" then return nil, "input_schema is not a JSON object" end
    return value, nil
end

local function root_violation(raw)
    local schema, err = decoded(raw)
    if not schema then return err end
    if schema.type ~= "object" then return "root type is " .. tostring(schema.type) .. ", expected object" end
    for _, keyword in ipairs(ROOT_KEYWORDS) do
        if schema[keyword] ~= nil then return "root declares " .. keyword end
    end
    return nil
end

local function define_tests()
    test.describe("Tool input schema roots", function()
        test.it("every registered tool declares a plain object root", function()
            local entries, err = registry.find({ ["meta.type"] = "tool" })
            test.is_nil(err, tostring(err))
            test.ok(#(entries or {}) > 0, "no registered tools")
            local offenders = {}
            for _, entry in ipairs(entries or {}) do
                local violation = root_violation((entry.meta or {}).input_schema)
                if violation then offenders[#offenders + 1] = tostring(entry.id) .. ": " .. violation end
            end
            table.sort(offenders)
            test.eq(#offenders, 0, table.concat(offenders, "; "))
        end)

        test.it("reports a non-object root and top-level composition", function()
            test.not_nil(root_violation('{"type":"object","anyOf":[{"required":["a"]}]}'))
            test.not_nil(root_violation({ type = "object", allOf = {} }))
            test.not_nil(root_violation({ type = "object", enum = { {} } }))
            test.not_nil(root_violation('{"type":"array"}'))
            test.not_nil(root_violation('{}'))
            test.not_nil(root_violation(nil))
            test.is_nil(root_violation('{"type":"object","properties":{"a":{"oneOf":[{"type":"string"},{"type":"integer"}]}}}'))
        end)
    end)
end

return { run_tests = test.run_cases(define_tests) }
