local providers = require("providers")

local function define_tests()
    describe("Providers Discovery Library", function()
        -- Sample provider registry entries for testing (using entry.data structure)
        local provider_entries = {
            {
                id = "wippy.llm.provider:openai",
                kind = "registry.entry",
                meta = {
                    type = "llm.provider",
                    name = "openai",
                    title = "OpenAI",
                    comment = "OpenAI API provider for GPT models"
                },
                data = {
                    driver = {
                        id = "wippy.llm.binding:openai_driver",
                        options = {
                            api_key_env = "OPENAI_API_KEY",
                            base_url = "https://api.openai.com/v1"
                        }
                    }
                }
            },
            {
                id = "wippy.llm.provider:anthropic",
                kind = "registry.entry",
                meta = {
                    type = "llm.provider",
                    name = "anthropic",
                    title = "Anthropic",
                    comment = "Anthropic API provider for Claude models"
                },
                data = {
                    driver = {
                        id = "wippy.llm.binding:anthropic_driver",
                        options = {
                            api_key_env = "ANTHROPIC_API_KEY",
                            base_url = "https://api.anthropic.com/v1"
                        }
                    }
                }
            }
        }

        local mock_registry
        local mock_contract

        before_each(function()
            -- Create mock registry for testing
            mock_registry = {
                find = function(query)
                    local results = table.create(#provider_entries, 0)
                    local count = 0

                    -- Filter entries based on query criteria
                    for _, entry in ipairs(provider_entries) do
                        local matches = true

                        -- Match on kind
                        if query[".kind"] and entry.kind ~= query[".kind"] then
                            matches = false
                        end

                        -- Match on meta.type
                        if query["meta.type"] and (not entry.meta or entry.meta.type ~= query["meta.type"]) then
                            matches = false
                        end

                        if matches then
                            count = count + 1
                            results[count] = entry
                        end
                    end

                    return results, nil
                end,

                get = function(id)
                    for _, entry in ipairs(provider_entries) do
                        if entry.id == id then
                            return entry, nil
                        end
                    end
                    return nil, "Entry not found: " .. id
                end
            }

            -- Create mock contract for testing
            mock_contract = {
                get = function(contract_id)
                    if contract_id == "wippy.llm:provider" then
                        return {
                            with_context = function(self, context)
                                self._context = context
                                return self
                            end,
                            open = function(self, binding_id)
                                if binding_id == "wippy.llm.binding:openai_driver" or
                                   binding_id == "wippy.llm.binding:anthropic_driver" then
                                    -- Return mock instance with status method
                                    return {
                                        status = function()
                                            return {
                                                success = true,
                                                status = "healthy",
                                                message = "Provider is responding normally"
                                            }
                                        end,
                                        _binding_id = binding_id,
                                        _context = self._context
                                    }, nil
                                else
                                    return nil, "Unknown binding: " .. binding_id
                                end
                            end
                        }, nil
                    else
                        return nil, "Unknown contract: " .. contract_id
                    end
                end
            }

            -- Inject the mock dependencies
            providers._registry = mock_registry
            providers._contract = mock_contract
        end)

        after_each(function()
            -- Reset the dependencies after each test
            providers._registry = require("registry")
            providers._contract = require("contract")
        end)

        describe("get_all", function()
            it("should get all providers", function()
                local all_providers, err = providers.get_all()

                expect(err).to_be_nil()
                expect(all_providers).not_to_be_nil()
                expect(#all_providers).to_equal(2)

                -- Check if providers are sorted by name (anthropic comes before openai)
                expect(all_providers[1].name).to_equal("anthropic")
                expect(all_providers[2].name).to_equal("openai")

                -- Check first provider details
                local anthropic = all_providers[1]
                expect(anthropic.id).to_equal("wippy.llm.provider:anthropic")
                expect(anthropic.title).to_equal("Anthropic")
                expect(anthropic.description).to_equal("Anthropic API provider for Claude models")
                expect(anthropic.driver_id).to_equal("wippy.llm.binding:anthropic_driver")

                -- Check second provider details
                local openai = all_providers[2]
                expect(openai.id).to_equal("wippy.llm.provider:openai")
                expect(openai.title).to_equal("OpenAI")
                expect(openai.description).to_equal("OpenAI API provider for GPT models")
                expect(openai.driver_id).to_equal("wippy.llm.binding:openai_driver")
            end)

            it("should handle registry error", function()
                -- Mock registry error
                providers._registry = {
                    find = function(query)
                        return nil, "Registry connection failed"
                    end
                }

                local all_providers, err = providers.get_all()

                expect(all_providers).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err:match("Registry error")).not_to_be_nil()
            end)

            it("should return empty array when no providers exist", function()
                -- Mock registry with no providers
                providers._registry = {
                    find = function(query)
                        return {}, nil
                    end
                }

                local all_providers, err = providers.get_all()

                expect(err).to_be_nil()
                expect(all_providers).not_to_be_nil()
                expect(#all_providers).to_equal(0)
            end)
        end)

        describe("open", function()
            it("should open a provider by ID", function()
                local instance, err = providers.open("wippy.llm.provider:openai")

                expect(err).to_be_nil()
                expect(instance).not_to_be_nil()
                expect(instance._binding_id).to_equal("wippy.llm.binding:openai_driver")

                -- Test that the provider instance has the status method
                local status_result = instance:status()
                expect(status_result.success).to_be_true()
                expect(status_result.status).to_equal("healthy")
            end)

            it("should open provider with context overrides", function()
                local context_overrides = {
                    custom_option = "test_value",
                    timeout = 60
                }

                local instance, err = providers.open("wippy.llm.provider:anthropic", context_overrides)

                expect(err).to_be_nil()
                expect(instance).not_to_be_nil()
                expect(instance._binding_id).to_equal("wippy.llm.binding:anthropic_driver")

                -- Verify context was merged
                expect(instance._context).not_to_be_nil()
                expect(instance._context.custom_option).to_equal("test_value")
                expect(instance._context.timeout).to_equal(60)
                expect(instance._context.api_key_env).to_equal("ANTHROPIC_API_KEY")
                expect(instance._context.base_url).to_equal("https://api.anthropic.com/v1")
            end)

            it("should return error when provider ID is nil", function()
                local instance, err = providers.open(nil)

                expect(instance).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err).to_equal("Provider ID is required")
            end)

            it("should return error when provider not found", function()
                local instance, err = providers.open("wippy.llm.provider:nonexistent")

                expect(instance).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err:match("Entry not found")).not_to_be_nil()
            end)

            it("should return error for non-provider entry", function()
                -- Add a non-provider entry to test data
                local non_provider_entry = {
                    id = "wippy.llm.model:test",
                    kind = "registry.entry",
                    meta = {
                        type = "llm.model",
                        name = "test"
                    },
                    data = {}
                }

                -- Mock registry to return non-provider entry
                providers._registry = {
                    get = function(id)
                        if id == "wippy.llm.model:test" then
                            return non_provider_entry, nil
                        end
                        return nil, "Entry not found: " .. id
                    end
                }

                local instance, err = providers.open("wippy.llm.model:test")

                expect(instance).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err:match("Entry is not a provider")).not_to_be_nil()
            end)

            it("should return error when provider missing driver config", function()
                -- Mock provider with missing driver
                local broken_provider = {
                    id = "wippy.llm.provider:broken",
                    kind = "registry.entry",
                    meta = {
                        type = "llm.provider",
                        name = "broken"
                    },
                    data = {}  -- Missing driver config
                }

                providers._registry = {
                    get = function(id)
                        if id == "wippy.llm.provider:broken" then
                            return broken_provider, nil
                        end
                        return nil, "Entry not found: " .. id
                    end
                }

                local instance, err = providers.open("wippy.llm.provider:broken")

                expect(instance).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err:match("Provider missing driver configuration")).not_to_be_nil()
            end)

            it("should handle contract get failure", function()
                providers._contract = {
                    get = function(contract_id)
                        return nil, "Contract system unavailable"
                    end
                }

                local instance, err = providers.open("wippy.llm.provider:openai")

                expect(instance).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err:match("Failed to get provider contract")).not_to_be_nil()
            end)

            it("should handle binding open failure", function()
                providers._contract = {
                    get = function(contract_id)
                        return {
                            with_context = function(self, context)
                                return self
                            end,
                            open = function(self, binding_id)
                                return nil, "Binding initialization failed"
                            end
                        }, nil
                    end
                }

                local instance, err = providers.open("wippy.llm.provider:openai")

                expect(instance).to_be_nil()
                expect(err).not_to_be_nil()
                expect(err:match("Failed to open provider binding")).not_to_be_nil()
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)