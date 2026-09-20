local typesafe_mapper = require("typesafe_mapper")
local output = require("output")
local test = require("test")

local function define_tests()
    describe("TypeSafe Mapper", function()

        describe("Request Mapping", function()
            it("should map a choice slot with an array domain to empty descriptions", function()
                local payload, err = typesafe_mapper.map_request({
                    model = "jev-latest",
                    state = "ticket text",
                    questions = {
                        topic = {
                            type = "choice",
                            instructions = "Which department owns this?",
                            domain = { "billing", "technical", "sales" }
                        }
                    }
                })

                test.is_nil(err)
                assert(payload)
                test.eq(payload.model, "jev-latest")
                test.eq(payload.state, "ticket text")

                local question = payload.questions.topic
                test.eq(question.type, "choice")
                test.eq(question.instructions, "Which department owns this?")
                test.eq(question.criteria.billing, "")
                test.eq(question.criteria.technical, "")
                test.eq(question.criteria.sales, "")
            end)

            it("should pass through a choice domain map", function()
                local payload, err = typesafe_mapper.map_request({
                    model = "jev-latest",
                    state = "ticket text",
                    questions = {
                        topic = {
                            type = "choice",
                            instructions = "Which department owns this?",
                            domain = { billing = "charges and refunds", technical = "product defects" }
                        }
                    }
                })

                test.is_nil(err)
                assert(payload)
                test.eq(payload.questions.topic.criteria.billing, "charges and refunds")
                test.eq(payload.questions.topic.criteria.technical, "product defects")
            end)

            it("should map a predicate slot without a domain to a criteria-free noul question", function()
                local payload, err = typesafe_mapper.map_request({
                    model = "jev-latest",
                    state = "ticket text",
                    questions = {
                        escalate = { type = "predicate", instructions = "Escalate to a supervisor?" }
                    }
                })

                test.is_nil(err)
                assert(payload)
                test.eq(payload.questions.escalate.type, "noul")
                test.eq(payload.questions.escalate.instructions, "Escalate to a supervisor?")
                test.is_nil(payload.questions.escalate.criteria)
            end)

            it("should map a predicate domain onto true and false criteria", function()
                local payload, err = typesafe_mapper.map_request({
                    model = "jev-latest",
                    state = "ticket text",
                    questions = {
                        escalate = {
                            type = "predicate",
                            instructions = "Escalate to a supervisor?",
                            domain = { yes = "escalate now", no = "routine handling" }
                        }
                    }
                })

                test.is_nil(err)
                assert(payload)
                test.eq(payload.questions.escalate.criteria["true"], "escalate now")
                test.eq(payload.questions.escalate.criteria["false"], "routine handling")
            end)

            it("should omit predicate criteria keys whose description is absent", function()
                local payload, err = typesafe_mapper.map_request({
                    model = "jev-latest",
                    state = "ticket text",
                    questions = {
                        escalate = {
                            type = "predicate",
                            instructions = "Escalate to a supervisor?",
                            domain = { yes = "escalate now" }
                        }
                    }
                })

                test.is_nil(err)
                assert(payload)
                test.eq(payload.questions.escalate.criteria["true"], "escalate now")
                test.is_nil(payload.questions.escalate.criteria["false"])
            end)

            it("should map a score slot domain to an ordered criteria array", function()
                local payload, err = typesafe_mapper.map_request({
                    model = "jev-latest",
                    state = "ticket text",
                    questions = {
                        anger = {
                            type = "score",
                            instructions = "How angry is the customer?",
                            domain = { "Calm", "Frustrated", "Very angry" }
                        }
                    }
                })

                test.is_nil(err)
                assert(payload)
                test.eq(payload.questions.anger.type, "score")
                test.eq(#payload.questions.anger.criteria, 3)
                test.eq(payload.questions.anger.criteria[1], "Calm")
                test.eq(payload.questions.anger.criteria[3], "Very angry")
            end)

            it("should pass a table state through unchanged", function()
                local payload, err = typesafe_mapper.map_request({
                    model = "jev-latest",
                    state = { ticket = "double charged", channel = "email" },
                    questions = {
                        escalate = { type = "predicate", instructions = "Escalate?" }
                    }
                })

                test.is_nil(err)
                assert(payload)
                test.eq(payload.state.ticket, "double charged")
                test.eq(payload.state.channel, "email")
            end)

            it("should leave an absent state absent", function()
                local payload, err = typesafe_mapper.map_request({
                    model = "jev-latest",
                    questions = {
                        escalate = { type = "predicate", instructions = "Escalate?" }
                    }
                })

                test.is_nil(err)
                assert(payload)
                test.is_nil(payload.state)
            end)

            it("should pass structured instructions through unchanged", function()
                local payload, err = typesafe_mapper.map_request({
                    model = "jev-latest",
                    state = "ticket text",
                    questions = {
                        escalate = {
                            type = "predicate",
                            instructions = { task = "Escalate?", rule = "only when the customer asks" }
                        }
                    }
                })

                test.is_nil(err)
                assert(payload)
                test.eq(payload.questions.escalate.instructions.task, "Escalate?")
                test.eq(payload.questions.escalate.instructions.rule, "only when the customer asks")
            end)

            it("should reject a slot type it cannot map", function()
                local payload, err = typesafe_mapper.map_request({
                    model = "jev-latest",
                    state = "ticket text",
                    questions = {
                        mood = { type = "gradient", instructions = "How is the mood?" }
                    }
                })

                test.is_nil(payload)
                test.contains(tostring(err), "mood")
                test.contains(tostring(err), "gradient")
            end)
        end)

        describe("Response Mapping", function()
            local choice_questions = {
                topic = {
                    type = "choice", instructions = "Which department owns this?",
                    domain = { "billing", "technical", "sales" }
                }
            }
            it("should accept a rounded Laya distribution and zero-output-token usage", function()
                local readings, err = typesafe_mapper.map_response({ answers = {
                    topic = { type = "choice", choice = "billing", probabilities = {billing = 0.3333, technical = 0.3333, sales = 0.3333} }
                } }, choice_questions)
                test.is_nil(err)
                assert(readings)
                test.eq(readings.topic.choice, "billing")
                local usage = typesafe_mapper.map_tokens({input_tokens = 12, output_tokens = 0})
                test.eq(usage.completion_tokens, 0)
            end)

            it("should reject invalid distributions, inconsistent choices and invalid confidence", function()
                local invalid = {
                    { choice = "billing", probabilities = { billing = 1.1, technical = -0.1, sales = 0 } },
                    { choice = "billing", probabilities = { billing = 0.2, technical = 0.5, sales = 0.3 } },
                    { choice = "billing", probabilities = { billing = 0.1, technical = 0.1, sales = 0.1 } },
                    { choice = "billing", probabilities = { billing = 0.8, technical = 0.1, sales = 0.1 }, confidence = 2 }
                }
                for _, answer in ipairs(invalid) do
                    answer.type = "choice"
                    local readings, err = typesafe_mapper.map_response({ answers = {topic = answer} }, choice_questions)
                    test.is_nil(readings)
                    assert(err)
                end
            end)
            it("should map a choice answer", function()
                local readings, err = typesafe_mapper.map_response({
                    answers = {
                        topic = {
                            type = "choice",
                            choice = "technical",
                            probabilities = { billing = 0.08, technical = 0.85, sales = 0.07 },
                            confidence = 0.82
                        }
                    }
                }, choice_questions)

                test.is_nil(err)
                assert(readings)
                test.eq(readings.topic.type, "choice")
                test.eq(readings.topic.choice, "technical")
                test.eq(readings.topic.probabilities.billing, 0.08)
                test.eq(readings.topic.probabilities.technical, 0.85)
                test.eq(readings.topic.probabilities.sales, 0.07)
                test.eq(readings.topic.confidence, 0.82)
            end)

            it("should map a choice answer declared through a domain map", function()
                local readings, err = typesafe_mapper.map_response({
                    answers = {
                        topic = {
                            type = "choice",
                            choice = "billing",
                            probabilities = { billing = 0.9, technical = 0.1 }
                        }
                    }
                }, {
                    topic = {
                        type = "choice",
                        instructions = "Which department owns this?",
                        domain = { billing = "charges", technical = "defects" }
                    }
                })

                test.is_nil(err)
                assert(readings)
                test.eq(readings.topic.choice, "billing")
                test.eq(readings.topic.probabilities.billing, 0.9)
                test.eq(readings.topic.probabilities.technical, 0.1)
            end)

            it("should leave confidence absent when the provider reports none", function()
                local readings, err = typesafe_mapper.map_response({
                    answers = {
                        topic = {
                            type = "choice",
                            choice = "sales",
                            probabilities = { billing = 0.1, technical = 0.1, sales = 0.8 }
                        }
                    }
                }, choice_questions)

                test.is_nil(err)
                assert(readings)
                test.is_nil(readings.topic.confidence)
            end)

            it("should reject a response without answers", function()
                local readings, err = typesafe_mapper.map_response({ model = "jev-1.13.0" }, choice_questions)

                test.is_nil(readings)
                test.contains(tostring(err), "answers")
            end)

            it("should reject a slot with no answer", function()
                local readings, err = typesafe_mapper.map_response({ answers = {} }, choice_questions)

                test.is_nil(readings)
                test.contains(tostring(err), "topic")
            end)

            it("should reject an answer whose type does not match the slot", function()
                local readings, err = typesafe_mapper.map_response({
                    answers = { topic = { type = "noul", noul = 0.5 } }
                }, choice_questions)

                test.is_nil(readings)
                test.contains(tostring(err), "topic")
                test.contains(tostring(err), "choice")
            end)

            it("should reject a choice answer missing a declared option probability", function()
                local readings, err = typesafe_mapper.map_response({
                    answers = {
                        topic = {
                            type = "choice",
                            choice = "billing",
                            probabilities = { billing = 0.9, technical = 0.1 }
                        }
                    }
                }, choice_questions)

                test.is_nil(readings)
                test.contains(tostring(err), "topic")
                test.contains(tostring(err), "sales")
            end)

            it("should reject a choice answer carrying an option outside the domain", function()
                local readings, err = typesafe_mapper.map_response({
                    answers = {
                        topic = {
                            type = "choice",
                            choice = "billing",
                            probabilities = { billing = 0.7, technical = 0.1, sales = 0.1, refunds = 0.1 }
                        }
                    }
                }, choice_questions)

                test.is_nil(readings)
                test.contains(tostring(err), "topic")
                test.contains(tostring(err), "domain")
            end)

            it("should reject a choice outside the declared domain", function()
                local readings, err = typesafe_mapper.map_response({
                    answers = {
                        topic = {
                            type = "choice",
                            choice = "refunds",
                            probabilities = { billing = 0.1, technical = 0.1, sales = 0.8 }
                        }
                    }
                }, choice_questions)

                test.is_nil(readings)
                test.contains(tostring(err), "topic")
                test.contains(tostring(err), "refunds")
            end)

            it("should map a noul answer to a predicate reading", function()
                local readings, err = typesafe_mapper.map_response({
                    answers = { escalate = { type = "noul", noul = 0.92 } }
                }, {
                    escalate = { type = "predicate", instructions = "Escalate?" }
                })

                test.is_nil(err)
                assert(readings)
                test.eq(readings.escalate.type, "predicate")
                test.eq(readings.escalate.probability, 0.92)
            end)

            it("should reject a noul answer without a probability", function()
                local readings, err = typesafe_mapper.map_response({
                    answers = { escalate = { type = "noul" } }
                }, {
                    escalate = { type = "predicate", instructions = "Escalate?" }
                })

                test.is_nil(readings)
                test.contains(tostring(err), "escalate")
            end)

            it("should convert a zero-based score answer to a one-based reading", function()
                local readings, err = typesafe_mapper.map_response({
                    answers = {
                        anger = {
                            type = "score",
                            score = 1.6,
                            legend = { ["0"] = "Calm", ["1"] = "Frustrated", ["2"] = "Very angry" },
                            probabilities = { ["0"] = 0.05, ["1"] = 0.3, ["2"] = 0.65 },
                            confidence = 0.78
                        }
                    }
                }, {
                    anger = {
                        type = "score",
                        instructions = "How angry?",
                        domain = { "Calm", "Frustrated", "Very angry" }
                    }
                })

                test.is_nil(err)
                assert(readings)
                test.eq(readings.anger.type, "score")
                test.eq(readings.anger.score, 2.6)
                test.eq(readings.anger.level, 3)
                test.eq(#readings.anger.probabilities, 3)
                test.eq(readings.anger.probabilities[1], 0.05)
                test.eq(readings.anger.probabilities[2], 0.3)
                test.eq(readings.anger.probabilities[3], 0.65)
                test.eq(readings.anger.confidence, 0.78)
            end)

            it("should award a tied score level to the lowest index", function()
                local readings, err = typesafe_mapper.map_response({
                    answers = {
                        anger = {
                            type = "score",
                            score = 0.5,
                            probabilities = { ["0"] = 0.5, ["1"] = 0.5 }
                        }
                    }
                }, {
                    anger = { type = "score", instructions = "How angry?", domain = { "Calm", "Angry" } }
                })

                test.is_nil(err)
                assert(readings)
                test.eq(readings.anger.level, 1)
                test.eq(readings.anger.score, 1.5)
            end)

            it("should reject a score answer missing a level probability", function()
                local readings, err = typesafe_mapper.map_response({
                    answers = {
                        anger = {
                            type = "score",
                            score = 1.0,
                            probabilities = { ["0"] = 0.4, ["1"] = 0.6 }
                        }
                    }
                }, {
                    anger = {
                        type = "score",
                        instructions = "How angry?",
                        domain = { "Calm", "Frustrated", "Very angry" }
                    }
                })

                test.is_nil(readings)
                test.contains(tostring(err), "anger")
            end)

            it("should reject a score answer carrying a level outside the domain", function()
                local readings, err = typesafe_mapper.map_response({
                    answers = {
                        anger = {
                            type = "score",
                            score = 1.0,
                            probabilities = { ["0"] = 0.3, ["1"] = 0.3, ["2"] = 0.4 }
                        }
                    }
                }, {
                    anger = { type = "score", instructions = "How angry?", domain = { "Calm", "Angry" } }
                })

                test.is_nil(readings)
                test.contains(tostring(err), "anger")
                test.contains(tostring(err), "domain")
            end)

            it("should reject a score answer without a score", function()
                local readings, err = typesafe_mapper.map_response({
                    answers = {
                        anger = { type = "score", probabilities = { ["0"] = 0.4, ["1"] = 0.6 } }
                    }
                }, {
                    anger = { type = "score", instructions = "How angry?", domain = { "Calm", "Angry" } }
                })

                test.is_nil(readings)
                test.contains(tostring(err), "anger")
            end)

            it("should reject answers that no slot declared", function()
                local readings, err = typesafe_mapper.map_response({
                    answers = {
                        escalate = { type = "noul", noul = 0.4 },
                        spurious = { type = "noul", noul = 0.9 }
                    }
                }, {
                    escalate = { type = "predicate", instructions = "Escalate?" }
                })

                test.is_nil(readings)
                test.contains(tostring(err), "undeclared answers")
            end)
        end)

        describe("Token Mapping", function()
            it("should map usage counts and total them", function()
                local tokens = typesafe_mapper.map_tokens({ input_tokens = 312, output_tokens = 48 })

                assert(tokens)
                test.eq(tokens.prompt_tokens, 312)
                test.eq(tokens.completion_tokens, 48)
                test.eq(tokens.total_tokens, 360)
            end)

            it("should count absent fields as zero", function()
                local tokens = typesafe_mapper.map_tokens({ input_tokens = 100 })

                assert(tokens)
                test.eq(tokens.prompt_tokens, 100)
                test.eq(tokens.completion_tokens, 0)
                test.eq(tokens.total_tokens, 100)
            end)

            it("should return nothing without a usage block", function()
                test.is_nil(typesafe_mapper.map_tokens(nil))
            end)
        end)

        describe("Error Classification", function()
            it("should classify authentication failures", function()
                local kind, message, details = typesafe_mapper.classify_error({
                    status_code = 401,
                    message = "Cannot authenticate with the server."
                })

                test.eq(kind, output.ERROR_TYPE.AUTHENTICATION)
                test.eq(message, "Cannot authenticate with the server.")
                assert(details)
                test.eq(details.status_code, 401)
            end)

            it("should classify validation failures", function()
                local kind = typesafe_mapper.classify_error({ status_code = 422, message = "Field required" })
                test.eq(kind, output.ERROR_TYPE.INVALID_REQUEST)
            end)

            it("should classify rate limits", function()
                local kind = typesafe_mapper.classify_error({ status_code = 429, message = "Too many requests" })
                test.eq(kind, output.ERROR_TYPE.RATE_LIMIT)
            end)

            it("should classify request timeouts", function()
                local kind = typesafe_mapper.classify_error({ status_code = 408, message = "Request timeout" })
                test.eq(kind, output.ERROR_TYPE.TIMEOUT)
            end)

            it("should classify a timeout reported without a status", function()
                local kind = typesafe_mapper.classify_error({
                    status_code = 0,
                    message = "Connection failed: request timed out"
                })
                test.eq(kind, output.ERROR_TYPE.TIMEOUT)
            end)

            it("should classify transport failures as network errors", function()
                local kind = typesafe_mapper.classify_error({ status_code = 0, message = "Connection failed" })
                test.eq(kind, output.ERROR_TYPE.NETWORK_ERROR)
            end)

            it("should classify a missing status as a network error", function()
                local kind = typesafe_mapper.classify_error({ message = "no response" })
                test.eq(kind, output.ERROR_TYPE.NETWORK_ERROR)
            end)

            it("should classify overload as a server error", function()
                local kind = typesafe_mapper.classify_error({ status_code = 529, message = "Overloaded" })
                test.eq(kind, output.ERROR_TYPE.SERVER_ERROR)
            end)

            it("should classify server failures", function()
                local kind = typesafe_mapper.classify_error({ status_code = 503, message = "Service unavailable" })
                test.eq(kind, output.ERROR_TYPE.SERVER_ERROR)
            end)

            it("should classify an unknown model as a model error", function()
                local kind = typesafe_mapper.classify_error({ status_code = 404, message = "Model not found" })
                test.eq(kind, output.ERROR_TYPE.MODEL_ERROR)
            end)

            it("should classify forbidden as an authentication error", function()
                local kind = typesafe_mapper.classify_error({ status_code = 403, message = "Forbidden" })
                test.eq(kind, output.ERROR_TYPE.AUTHENTICATION)
            end)

            it("should classify other client errors as invalid requests", function()
                local kind = typesafe_mapper.classify_error({ status_code = 400, message = "Bad request" })
                test.eq(kind, output.ERROR_TYPE.INVALID_REQUEST)
            end)

            it("should carry the request id and error type into details", function()
                local kind, message, details = typesafe_mapper.classify_error({
                    status_code = 401,
                    message = "Cannot authenticate",
                    error_type = "authentication_error",
                    metadata = { request_id = "req_01a0", retry_after = 12 }
                })

                test.eq(kind, output.ERROR_TYPE.AUTHENTICATION)
                test.eq(message, "Cannot authenticate")
                assert(details)
                test.eq(details.request_id, "req_01a0")
                test.eq(details.retry_after, 12)
                test.eq(details.error_type, "authentication_error")
            end)

            it("should classify an absent error as a server error", function()
                local kind, message = typesafe_mapper.classify_error(nil)

                test.eq(kind, output.ERROR_TYPE.SERVER_ERROR)
                test.eq(message, "Unknown TypeSafe error")
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
