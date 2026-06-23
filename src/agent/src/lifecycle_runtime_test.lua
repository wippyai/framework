local function define_tests()
    describe("Agent lifecycle runtime", function()
        local lifecycle_runtime
        local calls
        local behaviors

        before_each(function()
            lifecycle_runtime = require("lifecycle_runtime")
            calls = {}
            behaviors = {}

            lifecycle_runtime._contract = {
                get = function(contract_id)
                    if contract_id ~= "wippy.agent:lifecycle" then
                        return nil, "unexpected contract: " .. tostring(contract_id)
                    end

                    local function opener_for(binding_context)
                        return {
                            open = function(_, binding_id)
                                return {
                                    apply = function(_, payload)
                                        calls[#calls + 1] = {
                                            binding = binding_id,
                                            context = binding_context or {},
                                            payload = payload,
                                        }

                                        local behavior = behaviors[binding_id]
                                        if behavior then
                                            return behavior(payload, binding_context or {})
                                        end
                                        return {}, nil
                                    end
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
            lifecycle_runtime._contract = nil
            lifecycle_runtime = nil
            calls = nil
            behaviors = nil
        end)

        local function payload(phase)
            return {
                phase = phase,
                host = {
                    kind = "session",
                    session_id = "s1"
                },
                agent = {
                    id = "agent1",
                    model = "model1"
                },
                run_context = {
                    contract = "wippy.agent:run_context",
                    binding = "host.run_context:binding",
                    host = {
                        kind = "session",
                        session_id = "s1"
                    }
                }
            }
        end

        it("is a no-op when no lifecycle bindings are configured", function()
            local result, err = lifecycle_runtime.apply(nil, payload("activate"))

            test.is_nil(err)
            test.eq(result.applied, 0)
            test.eq(result.skipped, 0)
            test.eq(#calls, 0)
        end)

        it("filters handlers by phase and keeps priority order", function()
            local bindings = {
                {
                    id = "late",
                    binding = "late",
                    phases = { "activate" },
                    priority = 20,
                },
                {
                    id = "skip",
                    binding = "skip",
                    phases = { "deactivate" },
                    priority = 1,
                },
                {
                    id = "early",
                    binding = "early",
                    phases = { "activate" },
                    priority = 5,
                },
            }

            local result, err = lifecycle_runtime.apply(bindings, payload("activate"))

            test.is_nil(err)
            test.eq(result.applied, 2)
            test.eq(result.skipped, 1)
            test.eq(#calls, 2)
            test.eq(calls[1].binding, "early")
            test.eq(calls[2].binding, "late")
        end)

        it("treats an empty phase list as all lifecycle phases", function()
            local result, err = lifecycle_runtime.apply({
                {
                    id = "generic",
                    binding = "generic",
                    phases = {},
                }
            }, payload("after_step"))

            test.is_nil(err)
            test.eq(result.applied, 1)
            test.eq(#calls, 1)
            test.eq(calls[1].payload.phase, "after_step")
        end)

        it("passes binding context, options, host, agent and run_context to handlers", function()
            behaviors.inspect = function(in_payload, binding_context)
                return {
                    context = {
                        phase_seen = in_payload.phase,
                        namespace = binding_context.namespace,
                        max_items = in_payload.options.max_items,
                    },
                    observations = {
                        {
                            level = "info",
                            code = "seen",
                            content = in_payload.run_context.binding,
                        }
                    },
                    metadata = {
                        host_kind = in_payload.host.kind,
                        agent_id = in_payload.agent.id,
                    },
                    messages = {
                        {
                            role = "developer",
                            content = "memory activated"
                        }
                    }
                }, nil
            end

            local result, err = lifecycle_runtime.apply({
                {
                    id = "inspect",
                    trait_id = "trait.memory",
                    binding = "inspect",
                    context = {
                        namespace = "ops"
                    },
                    options = {
                        max_items = 5
                    },
                }
            }, payload("activate"))

            test.is_nil(err)
            test.eq(result.applied, 1)
            test.eq(calls[1].context.namespace, "ops")
            test.eq(calls[1].payload.options.max_items, 5)
            test.eq(result.context.phase_seen, "activate")
            test.eq(result.context.namespace, "ops")
            test.eq(result.context.max_items, 5)
            test.eq(result.observations[1].content, "host.run_context:binding")
            test.eq(result.metadata[1].trait_id, "trait.memory")
            test.eq(result.metadata[1].metadata.agent_id, "agent1")
            test.eq(result.messages[1].content, "memory activated")
        end)

        it("records non-strict handler errors and continues", function()
            behaviors.bad = function()
                return nil, "temporary failure"
            end
            behaviors.good = function()
                return {
                    metadata = {
                        ok = true
                    }
                }, nil
            end

            local result, err = lifecycle_runtime.apply({
                {
                    id = "bad",
                    binding = "bad",
                },
                {
                    id = "good",
                    binding = "good",
                },
            }, payload("before_step"))

            test.is_nil(err)
            test.eq(result.applied, 1)
            test.eq(#result.errors, 1)
            test.eq(result.errors[1].binding_id, "bad")
            test.eq(result.errors[1].strict, false)
            test.eq(result.metadata[1].metadata.ok, true)
        end)

        it("fails on strict handler errors", function()
            behaviors.strict_bad = function()
                return nil, "strict failure"
            end

            local result, err = lifecycle_runtime.apply({
                {
                    id = "strict_bad",
                    binding = "strict_bad",
                    strict = true,
                }
            }, payload("deactivate"))

            test.eq(err, "strict failure")
            test.eq(result.applied, 0)
            test.eq(#result.errors, 1)
            test.eq(result.errors[1].strict, true)
        end)

        it("rejects configured handlers when the host ref is missing", function()
            local result, err = lifecycle_runtime.apply({
                {
                    id = "handler",
                    binding = "handler",
                }
            }, {
                phase = "activate"
            })

            test.eq(err, "lifecycle host is required")
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
