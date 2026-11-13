local test = require("test")
local llm = require("llm")

return test.run_cases(function()
    describe("Per-candidate generation request preparation", function()
        local saved, cards, sent
        before_each(function()
            saved = {llm._models, llm._providers, llm._usage_tracker, llm._model_resolver}
            cards = {
                first = {name = "first", output_tokens = 128, max_tokens = 2048,
                    capabilities = {"generate"}, providers = {{id = "provider", provider_model = "first-wire"}},
                    fallback = {"second"}},
                second = {name = "second", output_tokens = 64, max_tokens = 2048,
                    capabilities = {"generate"}, providers = {{id = "provider", provider_model = "second-wire"}}},
            }
            sent = {}
            llm._model_resolver = false
            llm._usage_tracker = false
            llm._models = {
                get_by_name = function(name) return cards[name] end,
                get_by_class = function() return {cards.first, cards.second} end,
            }
            llm._providers = {
                driver_declares_legacy_reasoning_flag = function() return false end,
                driver_output_policy = function() return nil end,
                open = function() return {generate = function(_, args)
                    sent[#sent + 1] = args
                    if args.model == "first-wire" then
                        return nil, errors.new({kind = errors.INTERNAL, retryable = true,
                            message = "unavailable", details = {error_type = "server_error"}})
                    end
                    return {result = "done", tokens = {}}, nil
                end} end,
            }
        end)
        after_each(function()
            llm._models, llm._providers, llm._usage_tracker, llm._model_resolver =
                saved[1], saved[2], saved[3], saved[4]
        end)

        for _, selector in ipairs({"first", "class:vision"}) do
            it("prepares and caps each attempted model for " .. selector, function()
                local prepared = {}
                local options = {model = selector, max_tokens = 16,
                    prepare_request = function(context)
                        prepared[#prepared + 1] = context.model.name
                        test.eq(context.provider_id, "provider")
                        return {messages = {{role = "user", content = {{type = "text", text = context.model.name}}}},
                            max_tokens = 512}
                    end}
                local result, err = llm.generate("original", options)
                test.is_nil(err, tostring(err))
                test.eq(result.result, "done")
                test.eq(#prepared, 2)
                test.eq(#sent, 2)
                for i, name in ipairs({"first", "second"}) do
                    test.eq(prepared[i], name)
                    test.eq(sent[i].messages[1].content[1].text, name)
                    test.eq(sent[i].options.max_tokens, cards[name].output_tokens)
                    test.is_nil(sent[i].options.prepare_request)
                end
                test.eq(options.max_tokens, 16)
            end)
        end

        it("keeps the existing request when no preparation is supplied", function()
            local result, err = llm.generate("original", {model = "first", max_tokens = 32})
            test.is_nil(err, tostring(err))
            test.eq(result.result, "done")
            test.eq(#sent, 2)
            for _, args in ipairs(sent) do
                test.eq(args.messages[1].content[1].text, "original")
                test.eq(args.options.max_tokens, 32)
            end
        end)

        it("preserves a native preparation error before a provider request", function()
            local cause = errors.new({kind = errors.INVALID, retryable = false, message = "invalid profile"})
            local result, err = llm.generate("original", {model = "first",
                prepare_request = function() return nil, cause end})
            test.is_nil(result)
            test.eq(err, cause)
            test.eq(#sent, 0)
        end)

        it("admits the prepared messages against the candidate context window", function()
            local result, err = llm.generate("original", {model = "first", fallback = false,
                prepare_request = function()
                    return {messages = {{role = "user", content = {{type = "text", text = string.rep("x", 20000)}}}},
                        max_tokens = 16}
                end})
            test.is_nil(result)
            test.eq(err:details().error_type, "context_window")
            test.eq(#sent, 0)
        end)

        it("rejects invalid preparation results before calling a provider", function()
            for _, prepare in ipairs({
                false,
                function() return nil end,
                function() return {} end,
                function() return {messages = "question", max_tokens = 0} end,
                function() return {messages = "question", max_tokens = math.huge} end,
                function() return {messages = "question", max_tokens = 1.5} end,
            }) do
                local result, err = llm.generate("original", {model = "first", prepare_request = prepare})
                test.is_nil(result)
                test.eq(err:kind(), errors.INVALID)
                test.is_false(err:retryable())
                test.eq(#sent, 0)
            end
        end)

        it("supplies no model card for a direct provider call", function()
            local result, err = llm.generate("original", {model = "second-wire", provider_id = "provider",
                prepare_request = function(context)
                    test.is_nil(context.model)
                    test.eq(context.provider_model, "second-wire")
                    return {messages = {{role = "user", content = {{type = "text", text = "direct"}}}}}
                end})
            test.is_nil(err, tostring(err))
            test.eq(result.result, "done")
            test.eq(sent[1].messages[1].content[1].text, "direct")
        end)
    end)
end)
