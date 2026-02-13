local providers = require("providers")
local test = require("test")

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

                test.is_nil(err)
                test.not_nil(all_providers)
                test.eq(#all_providers, 2)

                -- Check if providers are sorted by name (anthropic comes before openai)
                test.eq(all_providers[1].name, "anthropic")
                test.eq(all_providers[2].name, "openai")

                -- Check first provider details
                local anthropic = all_providers[1]
                test.eq(anthropic.id, "wippy.llm.provider:anthropic")
                test.eq(anthropic.title, "Anthropic")
                test.eq(anthropic.description, "Anthropic API provider for Claude models")
                test.eq(anthropic.driver_id, "wippy.llm.binding:anthropic_driver")

                -- Check second provider details
                local openai = all_providers[2]
                test.eq(openai.id, "wippy.llm.provider:openai")
                test.eq(openai.title, "OpenAI")
                test.eq(openai.description, "OpenAI API provider for GPT models")
                test.eq(openai.driver_id, "wippy.llm.binding:openai_driver")
            end)

            it("should handle registry error", function()
                -- Mock registry error
                providers._registry = {
                    find = function(query)
                        return nil, "Registry connection failed"
                    end
                }

                local all_providers, err = providers.get_all()

                test.is_nil(all_providers)
                test.not_nil(err)
                test.not_nil(err:match("Registry error"))
            end)

            it("should return empty array when no providers exist", function()
                -- Mock registry with no providers
                providers._registry = {
                    find = function(query)
                        return {}, nil
                    end
                }

                local all_providers, err = providers.get_all()

                test.is_nil(err)
                test.not_nil(all_providers)
                test.eq(#all_providers, 0)
            end)
        end)

        describe("open", function()
            it("should open a provider by ID", function()
                local instance, err = providers.open("wippy.llm.provider:openai")

                test.is_nil(err)
                assert(instance)
                test.eq(instance._binding_id, "wippy.llm.binding:openai_driver")

                -- Test that the provider instance has the status method
                local status_result = (instance :: any):status()
                test.is_true(status_result.success)
                test.eq(status_result.status, "healthy")
            end)

            it("should open provider with context overrides", function()
                local context_overrides = {
                    custom_option = "test_value",
                    timeout = 60
                }

                local instance, err = providers.open("wippy.llm.provider:anthropic", context_overrides)

                test.is_nil(err)
                assert(instance)
                test.eq(instance._binding_id, "wippy.llm.binding:anthropic_driver")

                -- Verify context was merged
                assert(instance._context)
                test.eq(instance._context.custom_option, "test_value")
                test.eq(instance._context.timeout, 60)
                test.eq(instance._context.api_key_env, "ANTHROPIC_API_KEY")
                test.eq(instance._context.base_url, "https://api.anthropic.com/v1")
            end)

            it("should return error when provider ID is nil", function()
                local instance, err = providers.open(nil)

                test.is_nil(instance)
                test.not_nil(err)
                test.eq(err, "Provider ID is required")
            end)

            it("should return error when provider not found", function()
                local instance, err = providers.open("wippy.llm.provider:nonexistent")

                test.is_nil(instance)
                test.not_nil(err)
                test.not_nil(err:match("Entry not found"))
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

                test.is_nil(instance)
                test.not_nil(err)
                test.not_nil(err:match("Entry is not a provider"))
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

                test.is_nil(instance)
                test.not_nil(err)
                test.not_nil(err:match("Provider missing driver configuration"))
            end)

            it("should handle contract get failure", function()
                providers._contract = {
                    get = function(contract_id)
                        return nil, "Contract system unavailable"
                    end
                }

                local instance, err = providers.open("wippy.llm.provider:openai")

                test.is_nil(instance)
                test.not_nil(err)
                test.not_nil(err:match("Failed to get provider contract"))
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

                test.is_nil(instance)
                test.not_nil(err)
                test.not_nil(err:match("Failed to open provider binding"))
            end)
        end)
    end)
end

return require("test").run_cases(define_tests)
