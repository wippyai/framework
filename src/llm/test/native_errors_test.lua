local test = require("test")
local llm = require("llm")
local providers = require("providers")
local models = require("models")

local function call(method, options)
    if method == "structured_output" then return llm.structured_output({ type = "object" }, "Question", options) end
    if method == "evaluate" then return llm.evaluate("Question", { answer = { type = "predicate", instructions = "True?" } }, options) end
    if method == "embed" then return llm.embed({ "Question" }, options) end
    if method == "status" then return llm.status(options) end
    return llm.generate("Question", options)
end

return test.run_cases(function()
    describe("LLM native failures", function()
        local saved_models, saved_providers, saved_tracker
        before_each(function()
            saved_models, saved_providers, saved_tracker = llm._models, llm._providers, llm._usage_tracker
            llm._usage_tracker = false
            llm._models = { get_by_name = function()
                return { name = "test-model", capabilities = { "generate", "structured_output", "embed", "evaluate" },
                    providers = { { id = "provider", provider_model = "wire" } } }
            end }
        end)
        after_each(function()
            llm._models, llm._providers, llm._usage_tracker = saved_models, saved_providers, saved_tracker
        end)
        for _, method in ipairs({ "generate", "structured_output", "embed", "evaluate", "status" }) do
            for _, direct in ipairs({ false, true }) do
                it("preserves " .. method .. " failures through " .. (direct and "direct" or "model") .. " routing", function()
                    for _, kind in ipairs({ errors.INVALID, errors.INTERNAL }) do
                        local cause = errors.new({ kind = kind, retryable = kind == errors.INTERNAL,
                            message = "provider refused", details = { operation = method } })
                        llm._providers = {
                            driver_declares_legacy_reasoning_flag = function() return false end,
                            open = function() return { [method] = function() return nil, cause end } end,
                        }
                        local result, err = call(method, { model = "test-model", provider_id = direct and "provider" or nil, fallback = false })
                        test.is_nil(result)
                        test.not_nil(err)
                        test.eq(err:kind(), cause:kind())
                        test.eq(err:retryable(), cause:retryable())
                        test.eq(err:details().operation, method)
                        test.eq(err, cause)
                        test.eq(err:message(), "provider refused")
                        test.eq(tostring(err), "provider refused")
                        test.eq("Failed: " .. err, "Failed: provider refused")
                        test.eq(string.format("Failed: %s", err), "Failed: provider refused")
                    end
                end)
            end
            it("types missing " .. method .. " model input deterministically", function()
                local result, err = call(method, {})
                test.is_nil(result)
                test.eq(err:kind(), errors.INVALID)
                test.is_false(err:retryable())
                test.eq(err:message(), "Model is required in options")
                test.eq(tostring(err), "Model is required in options")
            end)

            for _, direct in ipairs({ false, true }) do
                it("preserves " .. method .. " opening failures through " .. (direct and "direct" or "model") .. " routing", function()
                    local cause = errors.new({ kind = errors.PERMISSION_DENIED, retryable = false,
                        message = "binding denied", details = { operation = "open" } })
                    llm._providers = { open = function() return nil, cause end }
                    local result, err = call(method, { model = "test-model", provider_id = direct and "provider" or nil })
                    test.is_nil(result)
                    test.eq(err:kind(), errors.PERMISSION_DENIED)
                    test.is_false(err:retryable())
                    test.eq(err:details().operation, "open")
                    test.eq(err:message(), "Failed to open provider: binding denied")
                    test.eq(tostring(err), "Failed to open provider: binding denied")
                end)
            end

            for _, lookup in ipairs({
                { model = "class:unconfigured", message = "No models found for class: unconfigured" },
                { model = "unconfigured", message = "Model or class not found: unconfigured" },
            }) do
                it("identifies an unconfigured " .. method .. " model: " .. lookup.model, function()
                    llm._models = {
                        get_by_class = function() return {} end,
                        get_by_name = function() return nil end,
                    }
                    local result, err = call(method, { model = lookup.model })
                    test.is_nil(result)
                    test.eq(err:kind(), errors.NOT_FOUND)
                    test.is_false(err:retryable())
                    test.eq(err:message(), lookup.message)
                    test.eq(err:details().error_type, "model_error")
                    test.eq(err:details().model, lookup.model)
                end)
            end

            it("retains the exact text of untyped " .. method .. " provider failures", function()
                llm._providers = {
                    driver_declares_legacy_reasoning_flag = function() return false end,
                    open = function() return { [method] = function() return nil, "provider refused" end } end,
                }
                local result, err = call(method, { model = "test-model" })
                test.is_nil(result)
                test.eq(err:kind(), errors.UNKNOWN)
                test.eq(err:message(), "provider refused")
                test.eq(tostring(err), "provider refused")
            end)

            it("types missing " .. method .. " provider configuration deterministically", function()
                llm._models = { get_by_name = function() return { name = "test-model", capabilities = { "evaluate" } } end }
                local result, err = call(method, { model = "test-model" })
                test.is_nil(result)
                test.eq(err:kind(), errors.INVALID)
                test.is_false(err:retryable())
                test.eq(err:message(), "Model has no configured providers: test-model")
                test.eq(tostring(err), "Model has no configured providers: test-model")
            end)
        end

        for _, method in ipairs({ "generate", "structured_output" }) do
            it("preserves native " .. method .. " route discovery failures", function()
                local cause = errors.new({ kind = errors.UNAVAILABLE, retryable = true,
                    message = "driver lookup failed", details = { operation = "lookup" } })
                llm._providers = {
                    open = function() return {} end,
                    driver_declares_legacy_reasoning_flag = function() return nil, cause end,
                }
                local result, err = call(method, { model = "test-model" })
                test.is_nil(result)
                test.eq(err, cause)
                test.eq(err:kind(), errors.UNAVAILABLE)
                test.is_true(err:retryable())
                test.eq(err:details().operation, "lookup")
                test.eq(err:message(), "driver lookup failed")
                test.eq(tostring(err), "driver lookup failed")
            end)
        end

        it("keeps invalid prompt messages and classifies the caller input", function()
            for _, direct in ipairs({ false, true }) do
                for _, method in ipairs({ "generate", "structured_output" }) do
                    local options = { model = "test-model", provider_id = direct and "provider" or nil }
                    local result, err
                    if method == "generate" then
                        result, err = llm.generate(false, options)
                    else
                        result, err = llm.structured_output({ type = "object" }, false, options)
                    end
                    test.is_nil(result)
                    test.eq(err:kind(), errors.INVALID)
                    test.is_false(err:retryable())
                    test.eq(err:message(), "Invalid prompt input format")
                    test.eq(tostring(err), "Invalid prompt input format")
                end
            end
        end)

        it("keeps existing class fallback to a larger context model", function()
            llm._models = {get_by_class = function() return {
                {name = "small", max_tokens = 200, providers = {{id = "provider", provider_model = "small"}}},
                {name = "large", max_tokens = 2000, providers = {{id = "provider", provider_model = "large"}}},
            } end}
            llm._providers = {
                driver_declares_legacy_reasoning_flag = function() return false end,
                open = function() return {generate = function(_, args)
                    if args.model == "small" then
                        return nil, errors.new({kind = errors.INVALID, message = "context too large",
                            details = {error_type = "context_length_exceeded"}})
                    end
                    return {result = "ok", tokens = {}, metadata = {}}
                end} end,
            }
            local result, err = llm.generate(string.rep("x", 1600), {model = "class:test", max_tokens = 40})
            test.is_nil(err)
            test.eq(result.metadata.route.model, "large")
        end)

        for _, method in ipairs({ "generate", "structured_output", "embed", "evaluate", "status" }) do
            for _, boundary in ipairs({ "registry", "contract", "binding" }) do
                it("preserves " .. method .. " " .. boundary .. " errors through real discovery", function()
                    local saved_registry, saved_contract = providers._registry, providers._contract
                    local cause = errors.new({ kind = errors.UNAVAILABLE, retryable = true,
                        message = "temporarily unavailable", details = { operation = boundary, nested = { retained = true } } })
                    providers._registry = { get = function()
                        if boundary == "registry" then return nil, cause end
                        return { meta = { type = "llm.provider" }, data = { driver = { id = "test:binding" } } }
                    end }
                    providers._contract = { get = function()
                        if boundary == "contract" then return nil, cause end
                        return {
                            with_context = function(self) return self end,
                            open = function() return nil, cause end,
                        }
                    end }
                    llm._providers = providers
                    local ran, result, err = pcall(call, method, { model = "test-model" })
                    providers._registry, providers._contract = saved_registry, saved_contract
                    test.is_true(ran, tostring(result))
                    test.is_nil(result)
                    test.eq(err:kind(), errors.UNAVAILABLE)
                    test.is_true(err:retryable())
                    test.eq(err:details().operation, boundary)
                    test.is_true(err:details().nested.retained)
                    local prefix = boundary == "registry" and "Registry error: "
                        or boundary == "contract" and "Failed to get provider contract: "
                        or "Failed to open provider binding: "
                    test.eq(tostring(err), "Failed to open provider: " .. prefix .. cause:message())
                end)
            end
        end

        for _, method in ipairs({ "generate", "structured_output" }) do
            it("preserves " .. method .. " driver lookup failures through real discovery", function()
                local saved_registry, saved_contract = providers._registry, providers._contract
                local cause = errors.new({ kind = errors.UNAVAILABLE, retryable = true,
                    message = "driver lookup unavailable", details = { operation = "driver" } })
                providers._registry = { get = function(id)
                    if id == "test:binding" then return nil, cause end
                    return { meta = { type = "llm.provider" }, data = { driver = { id = "test:binding" } } }
                end }
                providers._contract = { get = function() return {
                    with_context = function(self) return self end,
                    open = function() return {} end,
                } end }
                llm._providers = providers
                local ran, result, err = pcall(call, method, { model = "test-model" })
                providers._registry, providers._contract = saved_registry, saved_contract
                test.is_true(ran, tostring(result))
                test.is_nil(result)
                test.eq(err:kind(), errors.UNAVAILABLE)
                test.is_true(err:retryable())
                test.eq(err:details().operation, "driver")
                test.eq(tostring(err), "Registry error: driver lookup unavailable")
            end)
        end

        for _, operation in ipairs({ "name", "class", "bare_class", "available_models", "get_classes" }) do
            it("preserves native registry errors through real model discovery for " .. operation, function()
                local saved_registry = models._registry
                local cause = errors.new({ kind = errors.PERMISSION_DENIED, retryable = false,
                    message = "catalog denied", details = { operation = operation } })
                models._registry = { find = function(query)
                    if operation == "bare_class" and query["meta.name"] then return {} end
                    return nil, cause
                end }
                llm._models = models
                local ran, result, err = pcall(function()
                    if operation == "name" then return llm.resolve_model("test-model") end
                    if operation == "class" then return llm.resolve_model("class:test") end
                    if operation == "bare_class" then return llm.resolve_model("test-class") end
                    return llm[operation]()
                end)
                models._registry = saved_registry
                test.is_true(ran, tostring(result))
                test.is_nil(result)
                test.eq(err:kind(), errors.PERMISSION_DENIED)
                test.is_false(err:retryable())
                test.eq(err:details().operation, operation)
                test.eq(tostring(err), "Registry error: catalog denied")
            end)
        end

        it("types provider opening failures without a native cause", function()
            for _, cause in ipairs({ "binding missing", false }) do
                llm._providers = { open = function() return nil, cause or nil end }
                local result, err = llm.embed("Question", { model = "test-model" })
                local message = "Failed to open provider: " .. (cause or "unknown error")
                test.is_nil(result)
                test.eq(err:kind(), errors.INTERNAL)
                test.is_false(err:retryable())
                test.eq(err:message(), message)
                test.eq(tostring(err), message)
            end
        end)

        for _, operation in ipairs({ "resolve_model", "available_models", "get_classes" }) do
            for _, typed in ipairs({ false, true }) do
                it("retains " .. (typed and "native" or "string") .. " " .. operation .. " discovery failures", function()
                    local cause = typed and errors.new({ kind = errors.UNAVAILABLE, retryable = true,
                        message = "catalog read failed", details = { operation = operation } }) or "catalog read failed"
                    local function fail() return nil, cause end
                    llm._models = { get_by_class = fail, get_all = fail, get_all_classes = fail }
                    local result, err = llm[operation]("class:missing")
                    test.is_nil(result)
                    test.eq(err:message(), "catalog read failed")
                    test.eq(tostring(err), "catalog read failed")
                    if typed then
                        test.eq(err, cause)
                        test.eq(err:kind(), errors.UNAVAILABLE)
                        test.is_true(err:retryable())
                        test.eq(err:details().operation, operation)
                    else
                        test.eq(err:kind(), errors.INTERNAL)
                        test.is_false(err:retryable())
                    end
                end)
            end
        end

        it("preserves the last native failure with the exact route summary", function()
            llm._models = { get_by_name = function()
                return { name = "test-model", providers = {
                    { id = "first", provider_model = "wire" },
                    { id = "second", provider_model = "wire" },
                } }
            end }
            llm._providers = {
                driver_declares_legacy_reasoning_flag = function() return false end,
                open = function(id)
                    return { generate = function()
                        return nil, errors.new({ kind = errors.RATE_LIMITED, retryable = true,
                            message = id .. " refused", details = { error_type = "rate_limit_exceeded",
                                provider = id, nested = { values = { "kept", 2 } } } })
                    end }
                end,
            }
            local result, err = llm.generate("Question", { model = "test-model" })
            local message = "second refused (fallback: test-model via first: rate_limit_exceeded; "
                .. "test-model via second: rate_limit_exceeded)"
            test.is_nil(result)
            test.eq(err:kind(), errors.RATE_LIMITED)
            test.is_true(err:retryable())
            test.eq(err:details().provider, "second")
            test.eq(err:details().nested.values[1], "kept")
            test.eq(err:details().nested.values[2], 2)
            test.eq(#err:details().nested.values, 2)
            test.eq(err:message(), message)
            test.eq(tostring(err), message)
        end)

        for _, direct in ipairs({ false, true }) do
            it("types invalid responses as internal failures", function()
                llm._providers = { open = function() return { embed = function() return nil end } end }
                local result, err = llm.embed("Question", { model = "test-model",
                    provider_id = direct and "provider" or nil })
                test.is_nil(result)
                test.eq(err:kind(), errors.INTERNAL)
                test.is_false(err:retryable())
                test.eq(err:message(), "Failed to normalize provider response")
                test.eq(tostring(err), "Failed to normalize provider response")
            end)
        end
    end)
end)
