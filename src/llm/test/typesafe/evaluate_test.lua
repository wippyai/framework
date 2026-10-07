local evaluate_handler = require("evaluate_handler")
local json = require("json")
local test = require("test")

local function define_tests()
    describe("TypeSafe Evaluation Handler", function()

        after_each(function()
            -- Clean up injected dependencies
            evaluate_handler._client._ctx = nil
            evaluate_handler._client._env = nil
            evaluate_handler._client._http_client = nil
        end)

        local function with_client(post)
            evaluate_handler._client._ctx = {
                all = function()
                    return { api_key = "test-api-key" }
                end
            }
            evaluate_handler._client._env = {
                get = function(key)
                    return nil
                end
            }
            evaluate_handler._client._http_client = { post = post }
        end

        local support_questions = {
            topic = {
                type = "choice",
                instructions = "Which department owns this ticket?",
                domain = { "billing", "technical", "sales" }
            },
            escalate = {
                type = "predicate",
                instructions = "Escalate to a supervisor?",
                domain = { yes = "escalate now", no = "routine handling" }
            },
            anger = {
                type = "score",
                instructions = "How angry is the customer?",
                domain = { "Calm", "Frustrated", "Very angry" }
            }
        }

        local support_body = {
            model = "jev-1.13.0",
            answers = {
                topic = {
                    type = "choice",
                    choice = "technical",
                    probabilities = { billing = 0.08, technical = 0.85, sales = 0.07 },
                    confidence = 0.82
                },
                escalate = { type = "noul", noul = 0.92 },
                anger = {
                    type = "score",
                    score = 1.6,
                    legend = { ["0"] = "Calm", ["1"] = "Frustrated", ["2"] = "Very angry" },
                    probabilities = { ["0"] = 0.05, ["1"] = 0.3, ["2"] = 0.65 },
                    confidence = 0.78
                }
            },
            usage = { input_tokens = 312, output_tokens = 48 }
        }

        describe("Contract Argument Validation", function()
            it("should require a model", function()
                local response, err = evaluate_handler.handler({ questions = support_questions })

                test.is_nil(response)
                assert(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "Model is required")
            end)

            it("should require a questions", function()
                local response, err = evaluate_handler.handler({ model = "jev-latest" })

                test.is_nil(response)
                assert(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "Questions must be a table")
            end)

            it("should require at least one slot", function()
                local response, err = evaluate_handler.handler({ model = "jev-latest", questions = {} })

                test.is_nil(response)
                assert(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "at least one slot")
            end)

            it("should reject a slot type it cannot map", function()
                local response, err = evaluate_handler.handler({
                    model = "jev-latest",
                    state = "ticket",
                    questions = { mood = { type = "gradient", instructions = "How is the mood?" } }
                })

                test.is_nil(response)
                assert(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "mood")
            end)

            it("should reject malformed choice domains through a direct contract call", function()
                for _, domain in ipairs({ {"billing", "billing"}, {"billing", "technical", extra = "mixed"}, {[1] = "billing", [3] = "technical"} }) do
                    local response, err = evaluate_handler.handler({
                        model = "jev-latest", state = "ticket",
                        questions = { intent = { type = "choice", instructions = "Where?", domain = domain } }
                    })
                    test.is_nil(response)
                    assert(err)
                    test.eq(err:kind(), "Invalid")
                end
            end)

            it("should reject a missing domain before calling transport", function()
                local response, err = evaluate_handler.handler({
                    model = "jev-latest", state = "ticket",
                    questions = { intent = { type = "choice", instructions = "Where?" } }
                })
                test.is_nil(response)
                assert(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "Choice domain")
            end)
        end)

        describe("Request Building", function()
            it("should post the state, model and questions to the System One endpoint", function()
                local seen_url = nil
                local seen_payload = nil

                with_client(function(url, options)
                    seen_url = url
                    seen_payload = json.decode(tostring(options.body))
                    return { status_code = 200, body = json.encode(support_body), headers = {} }
                end)

                local response, err = evaluate_handler.handler({
                    model = "jev-latest",
                    state = { ticket = "charged twice", channel = "email" },
                    questions = support_questions
                })

                test.is_nil(err)
                test.eq(seen_url, "https://api.typesafe.ai/v1/systemone")
                assert(seen_payload)
                test.eq(seen_payload.model, "jev-latest")
                test.eq(seen_payload.state.ticket, "charged twice")
                test.eq(seen_payload.questions.topic.type, "choice")
                test.eq(seen_payload.questions.escalate.type, "noul")
                test.eq(seen_payload.questions.anger.type, "score")
            end)

            it("should pass the call timeout and retry policy to the client", function()
                local seen_timeout = nil
                local calls = 0

                with_client(function(url, options)
                    calls = calls + 1
                    seen_timeout = options.timeout
                    if calls == 1 then
                        return { status_code = 503, body = json.encode({ detail = { message = "unavailable" } }), headers = {} }
                    end
                    return { status_code = 200, body = json.encode(support_body), headers = {} }
                end)

                local response, err = evaluate_handler.handler({
                    model = "jev-latest",
                    state = "ticket",
                    questions = support_questions,
                    timeout = 7,
                    retry = { attempts = 2, backoff_ms = 0 }
                })

                test.is_nil(err)
                test.eq(seen_timeout, 7)
                test.eq(calls, 2)
            end)
        end)

        describe("Response Mapping", function()
            it("should return one reading per declared slot", function()
                with_client(function(url, options)
                    return {
                        status_code = 200,
                        body = json.encode(support_body),
                        headers = { ["x-typesafe-request-id"] = "req_support" }
                    }
                end)

                local response, err = evaluate_handler.handler({
                    model = "jev-latest",
                    state = "ticket",
                    questions = support_questions
                })

                test.is_nil(err)
                assert(response)
                test.is_true(response.success)

                local readings = response.result.readings
                test.eq(readings.topic.type, "choice")
                test.eq(readings.topic.choice, "technical")
                test.eq(readings.topic.probabilities.technical, 0.85)
                test.eq(readings.topic.confidence, 0.82)

                test.eq(readings.escalate.type, "predicate")
                test.eq(readings.escalate.probability, 0.92)

                test.eq(readings.anger.type, "score")
                test.eq(readings.anger.score, 2.6)
                test.eq(readings.anger.level, 3)
                test.eq(readings.anger.probabilities[3], 0.65)
                test.eq(readings.anger.confidence, 0.78)
            end)

            it("should report token usage", function()
                with_client(function(url, options)
                    return { status_code = 200, body = json.encode(support_body), headers = {} }
                end)

                local response, err = evaluate_handler.handler({
                    model = "jev-latest",
                    state = "ticket",
                    questions = support_questions
                })

                test.is_nil(err)
                assert(response)
                test.eq(response.tokens.prompt_tokens, 312)
                test.eq(response.tokens.completion_tokens, 48)
                test.eq(response.tokens.total_tokens, 360)
            end)

            it("should report the versioned model and the request id", function()
                with_client(function(url, options)
                    return {
                        status_code = 200,
                        body = json.encode(support_body),
                        headers = { ["x-typesafe-request-id"] = "req_support" }
                    }
                end)

                local response, err = evaluate_handler.handler({
                    model = "jev-latest",
                    state = "ticket",
                    questions = support_questions
                })

                test.is_nil(err)
                assert(response)
                test.eq(response.metadata.model, "jev-1.13.0")
                test.eq(response.metadata.request_id, "req_support")
            end)

            it("should omit tokens when the response reports no usage", function()
                with_client(function(url, options)
                    return {
                        status_code = 200,
                        body = json.encode({
                            model = "jev-1.13.0",
                            answers = { escalate = { type = "noul", noul = 0.3 } }
                        }),
                        headers = {}
                    }
                end)

                local response, err = evaluate_handler.handler({
                    model = "jev-latest",
                    state = "ticket",
                    questions = { escalate = { type = "predicate", instructions = "Escalate?" } }
                })

                test.is_nil(err)
                assert(response)
                test.is_nil(response.tokens)
            end)
        end)

        describe("Error Handling", function()
            it("should classify an authentication failure", function()
                with_client(function(url, options)
                    return {
                        status_code = 401,
                        body = json.encode({
                            detail = {
                                error_type = "authentication_error",
                                message = "Cannot authenticate with the server."
                            }
                        }),
                        headers = {}
                    }
                end)

                local response, err = evaluate_handler.handler({
                    model = "jev-latest",
                    state = "ticket",
                    questions = support_questions
                })

                test.is_nil(response)
                assert(err)
                test.eq(err:kind(), "PermissionDenied")
                test.contains(tostring(err:message()), "Cannot authenticate")
            end)

            it("should classify a validation failure", function()
                with_client(function(url, options)
                    return {
                        status_code = 422,
                        body = json.encode({
                            detail = { { type = "missing", loc = { "body", "state" }, msg = "Field required" } }
                        }),
                        headers = {}
                    }
                end)

                local response, err = evaluate_handler.handler({
                    model = "jev-latest",
                    state = "ticket",
                    questions = support_questions
                })

                test.is_nil(response)
                assert(err)
                test.eq(err:kind(), "Invalid")
                test.contains(tostring(err:message()), "body.state")
            end)

            it("should classify a rate limit", function()
                with_client(function(url, options)
                    return {
                        status_code = 429,
                        body = json.encode({ detail = { message = "Rate limit exceeded" } }),
                        headers = {}
                    }
                end)

                local response, err = evaluate_handler.handler({
                    model = "jev-latest",
                    state = "ticket",
                    questions = support_questions
                })

                test.is_nil(response)
                assert(err)
                test.eq(err:kind(), "RateLimited")
            end)

            it("should classify a transport failure", function()
                with_client(function(url, options)
                    return nil, "connection refused"
                end)

                local response, err = evaluate_handler.handler({
                    model = "jev-latest",
                    state = "ticket",
                    questions = support_questions
                })

                test.is_nil(response)
                assert(err)
                test.eq(err:kind(), "Unavailable")
            end)

            it("should reject a response that omits a declared slot", function()
                with_client(function(url, options)
                    return {
                        status_code = 200,
                        body = json.encode({
                            model = "jev-1.13.0",
                            answers = { escalate = { type = "noul", noul = 0.9 } }
                        }),
                        headers = {}
                    }
                end)

                local response, err = evaluate_handler.handler({
                    model = "jev-latest",
                    state = "ticket",
                    questions = {
                        topic = {
                            type = "choice",
                            instructions = "Which department owns this ticket?",
                            domain = { "billing", "technical" }
                        },
                        escalate = { type = "predicate", instructions = "Escalate?" }
                    }
                })

                test.is_nil(response)
                assert(err)
                test.eq(err:kind(), "NotFound")
                test.contains(tostring(err:message()), "topic")
            end)

            it("should reject a reading that contradicts the declared domain", function()
                with_client(function(url, options)
                    return {
                        status_code = 200,
                        body = json.encode({
                            model = "jev-1.13.0",
                            answers = {
                                anger = {
                                    type = "score",
                                    score = 1.0,
                                    probabilities = { ["0"] = 0.5, ["1"] = 0.5 }
                                }
                            }
                        }),
                        headers = {}
                    }
                end)

                local response, err = evaluate_handler.handler({
                    model = "jev-latest",
                    state = "ticket",
                    questions = {
                        anger = {
                            type = "score",
                            instructions = "How angry?",
                            domain = { "Calm", "Frustrated", "Very angry" }
                        }
                    }
                })

                test.is_nil(response)
                assert(err)
                test.eq(err:kind(), "NotFound")
                test.contains(tostring(err:message()), "anger")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
