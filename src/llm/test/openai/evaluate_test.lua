local handler = require("evaluate_handler")
local json = require("json")
local test = require("test")

local function args()
    return { model = "gpt-6-luna", state = "broken screen", _provider_id = "wippy.llm.openai:provider", questions = {
        damaged = { type = "predicate", instructions = "Is it broken?" }
    } }
end

local function body()
    return { model = "gpt-6-luna-2026-10-01", answers = { { type = "predicate", name = "q1", probability = 0.95 } },
        usage = { input_tokens = 42, output_tokens = 0, total_tokens = 42 }, metadata = { request_id = "req_decision" } }
end

local function define_tests()
    describe("OpenAI Decisions Evaluation Handler", function()
        local original_client = handler._client
        after_each(function() handler._client = original_client end)

        it("dispatches Decisions with transport options and returns readings, reported model and usage", function()
            local seen_path, seen_payload, seen_options
            local response_body: any = body()
            handler._client = { request = function(path, payload, options)
                seen_path, seen_payload, seen_options = path, payload, options
                return response_body
            end }
            local request = args()
            request.timeout = 7
            request.retry = { attempts = 2 }
            local response, err = handler.handler(request)
            test.is_nil(err)
            assert(response)
            test.eq(seen_path, "/decisions")
            test.eq(seen_payload.input, "broken screen")
            test.eq(seen_options.timeout, 7)
            test.eq(seen_options.retry.attempts, 2)
            test.is_true(response.success)
            test.eq(response.result.readings.damaged.probability, 0.95)
            test.eq(response.tokens.prompt_tokens, 42)
            test.eq(response.tokens.completion_tokens, 0)
            test.eq(response.metadata.model, "gpt-6-luna-2026-10-01")
            test.eq(response.metadata.request_id, "req_decision")
            test.eq(response.metadata.usage.input_tokens, 42)
            test.is_nil(response_body.metadata.model)
        end)

        it("validates before sending any HTTP request", function()
            handler._client = { request = function() error("must not call HTTP") end }
            local request = args()
            request.options = { temperature = 0.5 }
            local response, err = handler.handler(request)
            test.is_nil(response)
            test.eq(err:kind(), errors.INVALID)
            test.is_false(err:retryable())
            test.contains(err:message(), "temperature")
            response, err = handler.handler(nil)
            test.is_nil(response)
            test.eq(err:kind(), errors.INVALID)
        end)

        it("returns a nonretryable error for refusals without partial readings", function()
            local response_body = body()
            response_body.answers[1] = { type = "refusal", name = "q1" }
            handler._client = { request = function() return response_body end }
            local response, err = handler.handler(args())
            test.is_nil(response)
            test.eq(err:kind(), errors.INVALID)
            test.is_false(err:retryable())
            test.contains(err:message(), "refused")
            test.eq(err:details().request_id, "req_decision")
            test.eq(err:details().operation, "evaluate")
        end)

        it("returns model errors for malformed answers and usage", function()
            local response_body = body()
            response_body.answers[1].probability = "invalid"
            handler._client = { request = function() return response_body end }
            local response, err = handler.handler(args())
            test.is_nil(response)
            test.eq(err:kind(), errors.NOT_FOUND)
            test.eq(err:details().request_id, "req_decision")
            response_body = body()
            response_body.usage = { input_tokens = "invalid" }
            response, err = handler.handler(args())
            test.is_nil(response)
            test.eq(err:kind(), errors.NOT_FOUND)
            test.contains(err:message(), "usage")
        end)

        it("reuses OpenAI error classification for rate limits, auth and transient failures", function()
            for _, item in ipairs({ { status = 401, kind = errors.PERMISSION_DENIED, retryable = false },
                { status = 429, kind = errors.RATE_LIMITED, retryable = true },
                { status = 503, kind = errors.UNAVAILABLE, retryable = true } }) do
                handler._client = { request = function()
                    return nil, { status_code = item.status, message = "provider error", metadata = { request_id = "req_error" } }
                end }
                local response, err = handler.handler(args())
                test.is_nil(response)
                test.eq(err:kind(), item.kind)
                test.eq(err:retryable(), item.retryable)
                test.eq(err:details().request_id, "req_error")
                test.eq(err:details().provider, "wippy.llm.openai:provider")
            end
        end)

        it("uses the existing authenticated HTTP client and retries transient errors", function()
            local client = original_client
            local saved_ctx, saved_env, saved_http = client._ctx, client._env, client._http_client
            local calls = 0
            client._ctx = { all = function() return { api_key = "test-key", base_url = "https://example.test/v1" } end }
            client._env = { get = function() return nil end }
            client._http_client = { post = function(url, options)
                calls = calls + 1
                test.eq(url, "https://example.test/v1/decisions")
                test.eq(options.headers.Authorization, "Bearer test-key")
                test.eq(options.timeout, 7)
                test.eq(json.decode(options.body).questions[1].type, "predicate")
                if calls == 1 then return { status_code = 503, body = json.encode({ error = { message = "unavailable" } }), headers = {} } end
                return { status_code = 200, body = json.encode(body()), headers = { ["X-Request-Id"] = "req_http" } }
            end }
            handler._client = client
            local request = args()
            request.timeout = 7
            request.retry = { attempts = 2, backoff_ms = 0 }
            local ok, response, err = pcall(handler.handler, request)
            client._ctx, client._env, client._http_client = saved_ctx, saved_env, saved_http
            test.is_true(ok)
            test.is_nil(err)
            assert(response)
            test.eq(calls, 2)
            test.eq(response.metadata.request_id, "req_http")
        end)
    end)
end

return require("test").run_cases(define_tests)
