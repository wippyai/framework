local function define_tests()
    describe("Agent checkpoint runtime", function()
        local checkpoint_runtime
        local calls
        local behaviors

        before_each(function()
            checkpoint_runtime = require("checkpoint_runtime")
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

        it("is a no-op when no checkpoint bindings are configured", function()
            local result, err = checkpoint_runtime.create(nil, payload())

            test.is_nil(err)
            test.eq(result.applied, 0)
            test.eq(result.skipped, 0)
            test.eq(#calls, 0)
            test.is_nil(result.result)
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
    run_tests = function()
        return require("test").run_cases(define_tests)
    end
}
