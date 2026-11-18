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
            { "decoded empty object", json.decode("{}"), "{}" },
            { "decoded empty array", json.decode("[]"), "[]" },
            { "decoded empty object in an object", json.decode('{"b":{},"a":[]}'), '{"a":[],"b":{}}' },
            { "decoded empty object in an array", json.decode("[{},[],{}]"), "[{},[],{}]" },
            { "decoded tool schema without properties", json.decode(
                '{"type":"object","properties":{},"additionalProperties":false}'),
                '{"additionalProperties":false,"properties":{},"type":"object"}' },
            { "whole float", 2.0, "2" },
            { "whole floats in a table", { n = 2.0, list = { 1.0, 3.0 } }, '{"list":[1,3],"n":2}' },
        }
        -- One table reached through two keys is written in full at both places.
        local shared = { x = 1, list = { 2 } }
        cases[#cases + 1] = { "shared subtable in an object", { a = shared, b = shared },
            '{"a":{"list":[2],"x":1},"b":{"list":[2],"x":1}}' }
        cases[#cases + 1] = { "shared subtable in an array", { shared, { inner = shared } },
            '[{"list":[2],"x":1},{"inner":{"list":[2],"x":1}}]' }

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

        it("keeps a decoded array with many leading nulls", function()
            local text = "[" .. string.rep("null,", 1025) .. "1]"
            test.eq(canonical.encode(json.decode(text)), text)
            local nested = '{"args":[' .. string.rep("null,", 5000) .. '"x"]}'
            test.eq(canonical.encode(json.decode(nested)), nested)
        end)

        it("refuses a mostly empty array whose largest index is above the cap", function()
            test.eq(canonical.MAX_INDEX, 1000000)
            test.eq(#canonical.encode({ [canonical.MAX_INDEX] = 1 }), 1 + (canonical.MAX_INDEX - 1) * 5 + 2)
            for _, value in ipairs({ { [canonical.MAX_INDEX + 1] = 1 }, { [1e9] = 1 }, { 1, 2, [1e9] = 3 } }) do
                local ok = pcall(canonical.encode, value)
                test.ok(not ok)
                local text, err = canonical.try_encode(value)
                test.is_nil(text)
                test.contains(tostring(err), "only")
            end
        end)

        -- Above MAX_INDEX an array may have as many missing indexes as items, not one more.
        local function half_filled(max_index)
            local value = {}
            for index = 2, max_index, 2 do value[index] = 0 end
            return value
        end

        it("encodes an array above the cap with exactly half of its indexes missing", function()
            local max_index = canonical.MAX_INDEX + 2
            local value = half_filled(max_index)
            local expected = string.rep("null,0,", max_index / 2)
            expected = "[" .. expected:sub(1, #expected - 1) .. "]"
            test.eq(canonical.encode(value), expected)
            local text, err = canonical.try_encode(value)
            test.is_nil(err)
            test.eq(text, expected)
        end)

        it("refuses an array above the cap with one index more missing than half", function()
            local value = half_filled(canonical.MAX_INDEX + 2)
            value[2] = nil
            test.ok(not pcall(canonical.encode, value))
            local text, err = canonical.try_encode(value)
            test.is_nil(text)
            test.contains(tostring(err), "only 500000 items")
        end)

        it("encodes the deepest JSON the runtime decoder accepts", function()
            -- The runtime decoder accepts 128 containers around a value, or 129 when
            -- the innermost one is empty, and refuses one more level with
            -- "maximum nesting depth exceeded".
            local arrays = string.rep("[", 128) .. "1" .. string.rep("]", 128)
            local empty = string.rep("[", 129) .. string.rep("]", 129)
            local objects = string.rep('{"a":', 128) .. "1" .. string.rep("}", 128)
            test.is_nil(json.decode(string.rep("[", 129) .. "1" .. string.rep("]", 129)))
            test.is_nil(json.decode(string.rep("[", 130) .. string.rep("]", 130)))
            test.is_nil(json.decode(string.rep('{"a":', 129) .. "1" .. string.rep("}", 129)))
            for _, text in ipairs({ arrays, empty, objects }) do
                local value = json.decode(text)
                test.not_nil(value)
                test.eq(canonical.encode(value), text)
                local encoded, err = canonical.try_encode(value)
                test.is_nil(err)
                test.eq(encoded, text)
            end
        end)

        it("encodes Lua tables nested far deeper than the call stack", function()
            local value = {}
            for _ = 1, 10000 do value = { value } end
            -- 10000 wrappers around the innermost empty table.
            test.eq(canonical.encode(value), string.rep("[", 10001) .. string.rep("]", 10001))
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
