local canonical = require("canonical")
local json = require("json")

local function define_tests()
    describe("Canonical JSON", function()
        -- Text the encoder wrote before arrays with holes and mixed keys were fixed.
        -- Stored hashes depend on it, so every one of these must stay byte-identical.
        local cases = {
            { "nested object in key order", { b = 1, a = { d = true, c = false } }, '{"a":{"c":false,"d":true},"b":1}' },
            { "array without holes", { 1, 2, 3 }, "[1,2,3]" },
            { "nested arrays and objects", { { 1, { x = "y" } }, {} }, '[[1,{"x":"y"}],[]]' },
            { "empty table", {}, "[]" },
            { "empty string", "", '""' },
            { "string escapes", 'q"b\\n\n\t<>&\226\128\168\195\169',
                '"q\\"b\\\\n\\n\\t\\u003c\\u003e\\u0026\\u2028\195\169"' },
            { "integers", { 0, -7, 42, 9007199254740992 }, "[0,-7,42,9007199254740992]" },
            { "floats", { 1.5, -0.25, 0.1, 1e300, 1e-7 }, "[1.5,-0.25,0.1,1e+300,1e-7]" },
            { "true", true, "true" },
            { "false", false, "false" },
            { "nil", nil, "null" },
            { "json.null", json.null, "null" },
            { "json.null in an array", { 1, json.null, 3 }, "[1,null,3]" },
            { "json.null in an object", { a = json.null }, '{"a":null}' },
            { "numeric string key", { ["2"] = "read" }, '{"2":"read"}' },
            { "keys in byte order", { b = 1, ['a"q'] = 2, Z = 3, ["\195\169"] = 4, a = 5 },
                '{"Z":3,"a":5,"a\\"q":2,"b":1,"\195\169":4}' },
            { "decoded tool schema", json.decode(
                '{"type":"object","required":["x","y"],"properties":{"y":{"type":"integer","minimum":1},'
                    .. '"x":{"type":"string","enum":["a","b"]}}}'),
                '{"properties":{"x":{"enum":["a","b"],"type":"string"},"y":{"minimum":1,"type":"integer"}},'
                    .. '"required":["x","y"],"type":"object"}' },
        }

        it("keeps the exact text of every value it already encoded correctly", function()
            for _, case in ipairs(cases) do
                test.eq(canonical.encode(case[2]), case[3], case[1])
            end
        end)

        it("keeps every array item after a null", function()
            local first = canonical.encode(json.decode("[1,null,3]"))
            local second = canonical.encode(json.decode("[1,null,9]"))
            test.eq(first, "[1,null,3]")
            test.eq(second, "[1,null,9]")
            test.eq(canonical.encode(json.decode("[null,2]")), "[null,2]")
            test.eq(canonical.encode(json.decode('{"a":[null,null,{"b":[1,null,true]}]}')),
                '{"a":[null,null,{"b":[1,null,true]}]}')
        end)

        it("writes sparse arrays the way the runtime JSON encoder does", function()
            for _, value in ipairs({ { [1] = "a", [3] = "c" }, { [5] = "a" } }) do
                test.eq(canonical.encode(value), json.encode(value))
            end
            test.eq(canonical.encode({ [5] = "a" }), '[null,null,null,null,"a"]')
        end)

        -- A different value must never give the same text. An error is also correct.
        local function distinct(a, b)
            local ok_a, out_a = pcall(canonical.encode, a)
            local ok_b, out_b = pcall(canonical.encode, b)
            return not ok_a or not ok_b or out_a ~= out_b
        end

        it("does not let a number key and a string key share one name", function()
            test.ok(distinct({ [2] = "delete", ["2"] = "read" }, { [2] = "keep", ["2"] = "read" }))
            local text, err = canonical.try_encode({ [2] = "delete", ["2"] = "read" })
            test.is_nil(text)
            test.contains(tostring(err), "mixes")
        end)

        local function inf() return math.huge end
        local refused = {
            { "NaN", 0 / 0 },
            { "infinity", math.huge },
            { "negative infinity", -math.huge },
            { "function", inf },
            { "function in an object", { f = inf } },
            { "NaN in an array", { 1, 0 / 0 } },
            { "infinity in an object", { n = math.huge } },
            { "mixed keys", { 1, a = 2 } },
            { "zero key", { [0] = "x" } },
            { "negative key", { [-1] = "x" } },
            { "fractional key", { [1.5] = "x" } },
            { "boolean key", { [true] = "x" } },
            { "table key", { [{}] = "x" } },
        }

        it("refuses values JSON cannot represent instead of writing null", function()
            for _, case in ipairs(refused) do
                local ok = pcall(canonical.encode, case[2])
                test.ok(not ok, case[1] .. " must not encode")
                local text, err = canonical.try_encode(case[2])
                test.is_nil(text, case[1])
                test.eq(type(err), "string", case[1])
            end
        end)

        it("refuses a sparse table whose largest index is far above its item count", function()
            test.eq(#canonical.encode({ [1025] = 1 }), 1 + 1024 * 5 + 2)
            for _, value in ipairs({ { [1026] = 1 }, { [1e9] = 1 }, { 1, 2, [2051] = 3 } }) do
                local ok = pcall(canonical.encode, value)
                test.ok(not ok)
                local text, err = canonical.try_encode(value)
                test.is_nil(text)
                test.contains(tostring(err), "holes")
            end
            test.eq(#canonical.encode({ 1, 2, [1026] = 3 }), #"[1,2," + 1023 * 5 + #"3]")
        end)

        it("refuses a table that contains itself", function()
            local value = { a = 1 }
            value.self = value
            local text, err = canonical.try_encode(value)
            test.is_nil(text)
            test.contains(tostring(err), "contains itself")
        end)

        it("returns the same text from try_encode for valid values", function()
            for _, case in ipairs(cases) do
                local text, err = canonical.try_encode(case[2])
                test.is_nil(err, case[1])
                test.eq(text, case[3], case[1])
            end
        end)
    end)
end

return require("test").run_cases(define_tests)
