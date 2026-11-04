local function define_tests()
    describe("Agent checkpoint runtime", function()
        local checkpoint_runtime
        local compiler
        local calls
        local behaviors

        before_each(function()
            checkpoint_runtime = require("checkpoint_runtime")
            compiler = require("compiler")
            calls = {}
            behaviors = {}

            checkpoint_runtime._contract = {
                get = function(contract_id)
                    if contract_id ~= "wippy.agent:checkpoint" then
                        return nil, "unexpected contract: " .. tostring(contract_id)
                    end

                    local function opener_for(binding_context)
                        return {
                            open = function(_, binding_id)
                                return {
                                    create = function(_, payload)
                                        calls[#calls + 1] = {
                                            contract_id = contract_id,
                                            method = "create",
                                            binding = binding_id,
                                            context = binding_context or {},
                                            payload = payload,
                                        }
                                        local behavior = behaviors[binding_id]
                                        if behavior then
                                            return behavior(payload, binding_context or {})
                                        end
                                        return { memory = "checkpoint memory" }, nil
                                    end,
                                }, nil
                            end
                        }
                    end

                    return {
                        with_context = function(_, binding_context)
                            return opener_for(binding_context)
                        end,
                        open = function(_, binding_id)
                            return opener_for({}):open(binding_id)
                        end,
                    }, nil
                end
            }
        end)

        after_each(function()
            compiler._traits = nil
            compiler = nil
            checkpoint_runtime._contract = nil
            checkpoint_runtime = nil
            calls = nil
            behaviors = nil
        end)

        local function payload()
            return {
                host = {
                    kind = "session",
                    session_id = "s1"
                },
                agent = {
                    id = "agent1",
                    model = "model1"
                },
                reason = "token_threshold_exceeded",
                selector = {
                    mode = "since_checkpoint"
                },
                run_context = {
                    contract = "wippy.agent:run_context",
                    binding = "host.run_context:binding"
                }
            }
        end

        local summarizer_keys = {
            "model", "temperature", "max_tool_result_chars", "max_conversation_chars",
            "max_tool_results", "max_tool_results_chars", "max_row_chars",
        }
        local shared_keys = {
            "enabled", "function_id", "max_memory_chars", "max_tokens", "strict", "token_threshold",
        }

        local function compile_checkpoints(defaults)
            local checkpoint_behaviors: {[string]: any} = {
                a = {
                    handles = { "checkpoint" },
                    handlers = { checkpoint = "a" },
                    checkpoint = {
                        model = "model-a", temperature = 0.1, max_tool_result_chars = 100,
                        max_conversation_chars = 10000, max_tool_results = 10,
                        max_tool_results_chars = 1000, max_row_chars = 200,
                        enabled = false, function_id = "summary:a", max_memory_chars = 300,
                        max_tokens = 400, strict = true, token_threshold = 500,
                    },
                },
                z = {
                    handles = { "checkpoint" },
                    handlers = { checkpoint = "z" },
                    checkpoint = {
                        model = "model-b", temperature = 0.2, max_tool_result_chars = 200,
                        max_conversation_chars = 20000, max_tool_results = 20,
                        max_tool_results_chars = 2000, max_row_chars = 400,
                        enabled = true, function_id = "summary:z", max_memory_chars = 600,
                        max_tokens = 800, strict = false, token_threshold = 1000,
                    },
                },
            }
            if defaults then
                checkpoint_behaviors.compaction = { handles = { "checkpoint" }, checkpoint = defaults }
            end
            compiler._traits = {
                get_by_id = function()
                    return { id = "test:checkpoints", behaviors = checkpoint_behaviors }
                end,
            }
            local compiled, err = compiler.compile({ id = "test:agent", traits = { "test:checkpoints" } })
            test.is_nil(err)
            test.eq(#compiled.bindings.checkpoint, 2)
            return compiled, checkpoint_behaviors
        end

        for _, fail_first in ipairs({ false, true }) do
            it("keeps compiled summarizer options local " .. (fail_first and "through non-strict fallback" or "on the first binding"), function()
                local compiled, definitions = compile_checkpoints()
                if fail_first then
                    behaviors.a = function()
                        return nil, "temporary failure"
                    end
                end
                local input = payload()
                input.options = checkpoint_runtime.resolve_options(compiled.agent_options.checkpoint, nil)
                local result, err = checkpoint_runtime.create(compiled.bindings, input)
                test.is_nil(err)
                test.eq(result.applied, 1)
                test.eq(#calls, fail_first and 2 or 1)
                test.eq(#result.errors, fail_first and 1 or 0)
                if fail_first then
                    test.eq(result.errors[1].binding_id, "a")
                    test.is_false(result.errors[1].strict)
                    test.eq(result.errors[1].error, "temporary failure")
                end
                test.eq(calls[1].binding, "a")
                if fail_first then
                    test.eq(calls[2].binding, "z")
                end
                for _, call in ipairs(calls) do
                    for _, key in ipairs(summarizer_keys) do
                        test.eq(call.payload.options[key], definitions[call.binding].checkpoint[key],
                            call.binding .. " checkpoint." .. key .. " stays binding-local")
                    end
                    for _, key in ipairs(shared_keys) do
                        test.eq(call.payload.options[key], definitions.z.checkpoint[key],
                            "checkpoint." .. key .. " keeps shared precedence")
                    end
                end
                for _, binding in ipairs(compiled.bindings.checkpoint) do
                    for _, key in ipairs(summarizer_keys) do
                        test.eq(binding.options[key], definitions[binding.binding].checkpoint[key])
                        test.eq(binding.context.options[key], definitions[binding.binding].checkpoint[key])
                        test.is_nil(compiled.agent_options.checkpoint[key])
                    end
                end
                for _, key in ipairs(shared_keys) do
                    test.eq(compiled.agent_options.checkpoint[key], definitions.z.checkpoint[key])
                end
            end)
        end

        it("promotes no-handler summarizer defaults above binding-local options", function()
            local defaults = {
                model = "default-model", temperature = 0, max_tool_result_chars = 300,
                max_conversation_chars = 30000, max_tool_results = 30,
                max_tool_results_chars = 3000, max_row_chars = 600,
            }
            local compiled, definitions = compile_checkpoints(defaults)
            for _, key in ipairs(summarizer_keys) do
                test.eq(compiled.agent_options.checkpoint[key], defaults[key],
                    "no-handler checkpoint." .. key .. " reaches agent options")
            end
            local input = payload()
            input.options = checkpoint_runtime.resolve_options(compiled.agent_options.checkpoint, nil)
            local result, err = checkpoint_runtime.create(compiled.bindings, input)
            test.is_nil(err)
            test.eq(result.applied, 1)
            test.eq(#calls, 1)
            test.eq(calls[1].binding, "a")
            for _, key in ipairs(summarizer_keys) do
                test.eq(calls[1].payload.options[key], defaults[key])
                test.eq(compiled.bindings.checkpoint[1].options[key], definitions.a.checkpoint[key])
            end
        end)

        it("is a no-op when no checkpoint bindings are configured", function()
            local result, err = checkpoint_runtime.create(nil, payload())

            test.is_nil(err)
            test.eq(result.applied, 0)
            test.eq(result.skipped, 0)
            test.eq(#calls, 0)
            test.is_nil(result.result)
        end)

        it("resolves host overrides last without mutating agent defaults", function()
            local agent = {
                token_threshold = 12000,
                enabled = true,
                function_id = "agent:summary",
                provider = { model = "agent-model", max_tokens = 3000 },
            }
            local host = {
                token_threshold = 50000,
                enabled = false,
                function_id = "host:summary",
                provider = { max_tokens = 1000 },
            }
            local resolved = checkpoint_runtime.resolve_options(agent, host)
            test.eq(resolved.token_threshold, 50000)
            test.is_false(resolved.enabled)
            test.eq(resolved.function_id, "host:summary")
            test.eq(resolved.provider.model, "agent-model")
            test.eq(resolved.provider.max_tokens, 1000)
            resolved.provider.model = "changed"
            test.eq(agent.provider.model, "agent-model")
            test.eq(agent.token_threshold, 12000)
            test.eq(host.provider.max_tokens, 1000)
        end)

        it("preserves explicit zero and empty overrides and never enables absent configuration", function()
            test.is_nil(checkpoint_runtime.resolve_options(nil, nil))
            local resolved = checkpoint_runtime.resolve_options({
                token_threshold = 12000,
                function_id = "agent:summary",
            }, { token_threshold = 0, function_id = "" })
            test.eq(resolved.token_threshold, 0)
            test.eq(resolved.function_id, "")
        end)

        it("passes effective agent and host options above binding defaults", function()
            local input = payload()
            input.options = { token_threshold = 50000, model = "host-model" }
            local binding = {
                binding = "memory",
                options = { token_threshold = 12000, model = "trait-model", max_tokens = 3000 },
            }
            local _, err = checkpoint_runtime.create({ binding }, input)
            test.is_nil(err)
            test.eq(calls[1].payload.options.token_threshold, 50000)
            test.eq(calls[1].payload.options.model, "host-model")
            test.eq(calls[1].payload.options.max_tokens, 3000)
            calls[1].payload.options.model = "mutated-by-provider"
            test.eq(input.options.model, "host-model")
            test.eq(binding.options.model, "trait-model")
        end)

        it("replaces option lists, including an explicit empty list", function()
            local defaults = { namespaces = { "project", "user" }, provider = { tags = { "agent" } } }
            local host = { namespaces = {}, provider = { tags = { "host" } } }
            local resolved = checkpoint_runtime.resolve_options(defaults, host)
            test.eq(#resolved.namespaces, 0)
            test.eq(#resolved.provider.tags, 1)
            test.eq(resolved.provider.tags[1], "host")
            resolved.provider.tags[1] = "mutated"
            test.eq(host.provider.tags[1], "host")
            test.eq(defaults.provider.tags[1], "agent")
            test.eq(#defaults.namespaces, 2)
        end)

        it("does not let a failed provider mutate the next provider's options", function()
            behaviors.bad = function(input)
                input.options.provider.max_tokens = 999999
                return nil, "failed"
            end
            local input = payload()
            input.options = { provider = { max_tokens = 1000 } }
            local _, err = checkpoint_runtime.create({
                { binding = "bad", priority = 1 },
                { binding = "good", priority = 2 },
            }, input)
            test.is_nil(err)
            test.eq(#calls, 2)
            test.eq(calls[2].payload.options.provider.max_tokens, 1000)
            test.eq(input.options.provider.max_tokens, 1000)
        end)

        it("calls the highest-priority checkpoint binding with context and options", function()
            behaviors.early = function(in_payload, binding_context)
                return {
                    memory = "trait checkpoint",
                    metadata = {
                        namespace = binding_context.namespace,
                        max_items = in_payload.options.max_items,
                        run_context = in_payload.run_context.binding,
                    }
                }, nil
            end

            local result, err = checkpoint_runtime.create({
                {
                    id = "late",
                    binding = "late",
                    priority = 50,
                },
                {
                    id = "early",
                    trait_id = "trait.memory",
                    binding = "early",
                    priority = 10,
                    context = {
                        namespace = "ops"
                    },
                    options = {
                        max_items = 5
                    }
                }
            }, payload())

            test.is_nil(err)
            test.eq(result.applied, 1)
            test.eq(#calls, 1)
            test.eq(calls[1].binding, "early")
            test.eq(calls[1].method, "create")
            test.eq(calls[1].context.namespace, "ops")
            test.eq(calls[1].payload.options.max_items, 5)
            test.eq(calls[1].payload.context.namespace, "ops")
            test.eq(result.result.memory, "trait checkpoint")
            test.eq(result.metadata[1].trait_id, "trait.memory")
        end)

        it("falls through non-strict errors and uses the next binding", function()
            behaviors.bad = function()
                return nil, "temporary failure"
            end
            behaviors.good = function()
                return { summary = "fallback summary" }, nil
            end

            local result, err = checkpoint_runtime.create({
                {
                    id = "bad",
                    binding = "bad",
                    priority = 1,
                },
                {
                    id = "good",
                    binding = "good",
                    priority = 2,
                },
            }, payload())

            test.is_nil(err)
            test.eq(result.applied, 1)
            test.eq(#result.errors, 1)
            test.eq(result.errors[1].binding_id, "bad")
            test.eq(result.result.summary, "fallback summary")
            test.eq(#calls, 2)
        end)

        it("fails on strict checkpoint errors", function()
            behaviors.strict_bad = function()
                return nil, "strict failure"
            end

            local result, err = checkpoint_runtime.create({
                {
                    id = "strict_bad",
                    binding = "strict_bad",
                    strict = true,
                }
            }, payload())

            test.eq(err, "strict failure")
            test.eq(result.applied, 0)
            test.eq(#result.errors, 1)
            test.eq(result.errors[1].strict, true)
        end)

        it("rejects non-checkpoint contracts instead of aliasing unrelated vocabulary", function()
            local result, err = checkpoint_runtime.create({
                {
                    id = "wrong",
                    contract = "wippy.agent:memory",
                    binding = "wrong",
                }
            }, payload())

            test.is_nil(err)
            test.eq(result.applied, 0)
            test.eq(#result.errors, 1)
            test.contains(result.errors[1].error, "unsupported checkpoint contract")
            test.eq(#calls, 0)
        end)

        it("rejects configured handlers when the host ref is missing", function()
            local result, err = checkpoint_runtime.create({
                {
                    id = "handler",
                    binding = "handler",
                }
            }, {})

            test.eq(err, "checkpoint host is required")
            test.eq(result.applied, 0)
            test.eq(#calls, 0)
        end)
    end)
end

return {
    run_tests = require("test").run_cases(define_tests)
}
