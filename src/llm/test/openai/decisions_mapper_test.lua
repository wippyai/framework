local mapper = require("decisions_mapper")
local json = require("json")
local output = require("output")
local test = require("test")

local function questions()
    return {
        a_truth = { type = "predicate", instructions = "Is it broken?", domain = { yes = "damaged", no = "intact" } },
        b_route = { type = "choice", instructions = { task = "Route it" }, domain = { billing = "payments", technical = "defects" } },
        c_severity = { type = "score", instructions = "Rate severity", domain = { "low", "medium", "high" } }
    }
end

local function response()
    return { answers = {
        { type = "predicate", name = "q1", probability = 0.9 },
        { type = "choice", name = "q2", choice = "technical", confidence = 0.8, probabilities = {
            { value = "technical", probability = 0.9 }, { value = "billing", probability = 0.1 }
        } },
        { type = "score", name = "q3", score = 1.1, confidence = 0.55, probabilities = {
            { value = 2, label = "level_2", probability = 0.2 },
            { value = 0, label = "level_0", probability = 0.1 },
            { value = 1, label = "level_1", probability = 0.7 }
        } }
    } }
end

local function define_tests()
    describe("OpenAI Decisions Mapper", function()
        it("maps all question types and JSON text without exposing caller keys", function()
            local payload, err = mapper.map_request({ model = "gpt-6-luna", state = { ticket = "broken" }, questions = questions() })
            test.is_nil(err)
            assert(payload)
            test.eq(json.decode(payload.input).ticket, "broken")
            test.eq(#payload.questions, 3)
            test.eq(payload.questions[1].name, "q1")
            test.eq(payload.questions[1].type, "predicate")
            test.eq(payload.questions[1].instructions, "Is it broken?\n\nOutcome criteria:\nTrue: damaged\nFalse: intact")
            test.eq(json.decode(payload.questions[2].instructions).task, "Route it")
            test.eq(payload.questions[2].choices[1].value, "billing")
            test.eq(payload.questions[2].choices[1].description, "payments")
            test.eq(payload.questions[3].levels[1].label, "level_0")
            test.eq(payload.questions[3].levels[1].description, "low")
            local encoded = json.encode(payload)
            test.is_nil((encoded:find("a_truth", 1, true)))
            test.is_nil((encoded:find("b_route", 1, true)))
            test.is_nil((encoded:find("c_severity", 1, true)))
        end)

        it("preserves ordered array choices, repeated score descriptions and plain predicate instructions", function()
            local payload, err = mapper.map_request({ model = "future-model", state = "text", questions = {
                a = { type = "choice", instructions = "Choose", domain = { "second", "first" } },
                b = { type = "predicate", instructions = "True?", domain = {} },
                c = { type = "score", instructions = "Rate", domain = { "same", "same" } }
            } })
            test.is_nil(err)
            assert(payload)
            test.eq(payload.input, "text")
            test.eq(payload.questions[1].choices[1].value, "second")
            test.is_nil(payload.questions[1].choices[1].description)
            test.eq(payload.questions[2].instructions, "True?")
            test.eq(payload.questions[3].levels[2].label, "level_1")
            test.eq(payload.questions[3].levels[2].description, "same")
        end)

        it("accepts explicit safety identifiers and excludes facade tracking options", function()
            local payload, err = mapper.map_request({ model = "gpt-6-luna", state = "text", questions = questions(),
                options = { safety_identifier = "opaque-hash", user = "actor-id", metadata = { tag = "usage" }, timestamp = 42 } })
            test.is_nil(err)
            assert(payload)
            test.eq(payload.safety_identifier, "opaque-hash")
            test.is_nil(payload.user)
            test.is_nil(payload.metadata)
            payload, err = mapper.map_request({ model = "gpt-6-luna", state = "text", questions = questions(), options = { user = "actor-id" } })
            test.is_nil(err)
            assert(payload)
            test.is_nil(payload.safety_identifier)
        end)

        it("rejects invalid input and unsupported inference options", function()
            local invalid = {
                { model = "gpt-6-luna", state = "text", questions = {} },
                { model = "gpt-6-luna", state = 42, questions = questions() },
                { model = "gpt-6-luna", state = "text", questions = questions(), options = "invalid" },
                { model = "gpt-6-luna", state = "text", questions = questions(), options = { temperature = 0 } },
                { model = "gpt-6-luna", state = "text", questions = questions(), stream = false },
                { model = "gpt-6-luna", state = "text", questions = questions(), tools = {} },
                { model = "gpt-6-luna", state = "text", questions = questions(), options = { safety_identifier = 42 } },
                { model = "gpt-6-luna", state = "text", questions = questions(), options = { safety_identifier = string.rep("x", 129) } }
            }
            for _, args in ipairs(invalid) do
                local payload, err = mapper.map_request(args)
                test.is_nil(payload)
                test.not_nil(err)
            end
            local domain = {}
            for index = 1, 256 do domain[index] = "option_" .. tostring(index) end
            local payload, err = mapper.map_request({ model = "gpt-6-luna", state = "text", questions = {
                route = { type = "choice", instructions = "Choose", domain = domain }
            } })
            test.is_nil(payload)
            test.contains(err, "255")
        end)

        it("matches out of order answers and probability values to the original slots", function()
            local body = response()
            body.answers[1], body.answers[3] = body.answers[3], body.answers[1]
            local readings, err = mapper.map_response(body, questions())
            test.is_nil(err)
            assert(readings)
            test.eq(readings.a_truth.probability, 0.9)
            test.eq(readings.b_route.choice, "technical")
            test.eq(readings.b_route.probabilities.billing, 0.1)
            test.eq(readings.b_route.confidence, 0.8)
            test.eq(readings.c_severity.score, 2.1)
            test.eq(readings.c_severity.level, 2)
            test.eq(readings.c_severity.probabilities[1], 0.1)
            test.eq(readings.c_severity.probabilities[3], 0.2)
            test.eq(readings.c_severity.confidence, 0.55)
        end)

        it("converts endpoint score extremes and selects the first modal level on ties", function()
            local slot = { score = { type = "score", instructions = "Rate", domain = { "low", "high" } } }
            for _, value in ipairs({ 0, 1 }) do
                local reading, err = mapper.map_response({ answers = { { name = "q1", type = "score", score = value, confidence = 1,
                    probabilities = { { value = 0, label = "level_0", probability = 1 - value }, { value = 1, label = "level_1", probability = value } }
                } } }, slot)
                test.is_nil(err)
                assert(reading)
                test.eq(reading.score.score, value + 1)
                test.eq(reading.score.level, value + 1)
            end
            local body = response()
            body.answers[3].score = 0.5
            body.answers[3].probabilities[1].probability = 0
            body.answers[3].probabilities[2].probability = 0.5
            body.answers[3].probabilities[3].probability = 0.5
            local readings, err = mapper.map_response(body, questions())
            test.is_nil(err)
            assert(readings)
            test.eq(readings.c_severity.level, 1)
        end)

        it("fails the whole evaluation when any known slot is refused", function()
            local body = response()
            body.answers[2] = { name = "q2", type = "refusal" }
            local readings, err, kind = mapper.map_response(body, questions())
            test.is_nil(readings)
            test.contains(err, "b_route")
            test.eq(kind, output.ERROR_TYPE.CONTENT_FILTER)
        end)

        it("rejects missing, duplicate, unknown and unnamed answers and malformed arrays", function()
            local mutations = {
                function(body) body.answers = nil end,
                function(body) body.answers[3] = nil end,
                function(body) body.answers[2].name = "q1" end,
                function(body) body.answers[2].name = "unknown" end,
                function(body) body.answers[2].name = nil end,
                function(body) body.answers.extra = {} end,
                function(body) body.answers[2] = "invalid" end,
                function(body) body.answers[1].type = "choice" end
            }
            for _, mutate in ipairs(mutations) do
                local body = response()
                mutate(body)
                local readings, err = mapper.map_response(body, questions())
                test.is_nil(readings)
                test.not_nil(err)
            end
            for _, body in ipairs({ false, 42, "invalid" }) do
                local readings, err = mapper.map_response(body, questions())
                test.is_nil(readings)
                test.not_nil(err)
            end
        end)

        it("rejects malformed and inconsistent probabilities, confidence and scores", function()
            local mutations = {
                function(body) body.answers[1].probability = 0 / 0 end,
                function(body) body.answers[1].probability = math.huge end,
                function(body) body.answers[2].confidence = nil end,
                function(body) body.answers[2].confidence = 1.1 end,
                function(body) body.answers[2].choice = "billing" end,
                function(body) body.answers[2].choice = true end,
                function(body) body.answers[2].probabilities[2].value = "technical" end,
                function(body) body.answers[2].probabilities[2].value = "outside" end,
                function(body) body.answers[2].probabilities[2].value = false end,
                function(body) body.answers[2].probabilities[2].probability = -0.1 end,
                function(body) body.answers[2].probabilities[2].probability = 0.5 end,
                function(body) body.answers[2].probabilities.extra = {} end,
                function(body) body.answers[2].probabilities[1] = nil end,
                function(body) body.answers[3].score = 0 / 0 end,
                function(body) body.answers[3].score = 3 end,
                function(body) body.answers[3].score = 0.5 end,
                function(body) body.answers[3].probabilities[1].value = 0.5 end,
                function(body) body.answers[3].probabilities[1].value = 4 end,
                function(body) body.answers[3].probabilities[1].label = "wrong" end,
                function(body) body.answers[3].probabilities[1].value = 0; body.answers[3].probabilities[1].label = "level_0" end
            }
            for _, mutate in ipairs(mutations) do
                local body = response()
                mutate(body)
                local readings, err = mapper.map_response(body, questions())
                test.is_nil(readings)
                test.not_nil(err)
            end
        end)

        it("preserves input only usage without inventing absent details", function()
            local tokens, err = mapper.map_tokens({ input_tokens = 42, output_tokens = 0, total_tokens = 42 })
            test.is_nil(err)
            assert(tokens)
            test.eq(tokens.prompt_tokens, 42)
            test.eq(tokens.completion_tokens, 0)
            test.eq(tokens.total_tokens, 42)
            test.is_nil(tokens.thinking_tokens)
            test.is_nil(tokens.cache_read_tokens)
            test.is_nil(tokens.cache_write_tokens)
            test.is_nil(mapper.map_tokens(nil))
            tokens, err = mapper.map_tokens({ input_tokens = 42 })
            test.is_nil(err)
            assert(tokens)
            test.is_nil(tokens.completion_tokens)
            test.is_nil(tokens.total_tokens)
        end)

        it("keeps reported cache and reasoning categories disjoint for usage tracking", function()
            local tokens, err = mapper.map_tokens({ input_tokens = 100, output_tokens = 5, total_tokens = 105,
                input_tokens_details = { cached_tokens = 20, cache_write_tokens = 10 }, output_tokens_details = { reasoning_tokens = 2 } })
            test.is_nil(err)
            assert(tokens)
            test.eq(tokens.prompt_tokens, 70)
            test.eq(tokens.cache_read_tokens, 20)
            test.eq(tokens.cache_write_tokens, 10)
            test.eq(tokens.cache_read_input_tokens, 20)
            test.eq(tokens.cache_creation_input_tokens, 10)
            test.eq(tokens.thinking_tokens, 2)
            test.eq(tokens.total_tokens, 105)
        end)

        it("rejects malformed usage instead of silently replacing it with zero", function()
            for _, usage in ipairs({ false, { input_tokens = "42" }, { output_tokens = -1 }, { total_tokens = math.huge },
                { input_tokens_details = false }, { input_tokens_details = { cached_tokens = 0.5 } },
                { input_tokens = 1, input_tokens_details = { cached_tokens = 2 } },
                { output_tokens_details = { reasoning_tokens = -1 } },
                { input_tokens = 42, output_tokens = 0, total_tokens = 41 },
                { output_tokens = 0, output_tokens_details = { reasoning_tokens = 1 } } }) do
                local tokens, err = mapper.map_tokens(usage)
                test.is_nil(tokens)
                test.not_nil(err)
            end
        end)
    end)
end

return require("test").run_cases(define_tests)
