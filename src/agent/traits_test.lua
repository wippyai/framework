local traits = require("traits")

local function define_tests()
    describe("Traits Library", function()
        -- Sample trait registry entries for testing
        local trait_entries = {
            ["wippy.agents:conversational"] = {
                id = "wippy.agents:conversational",
                kind = "registry.entry",
                meta = {
                    type = "agent.trait",
                    name = "Conversational",
                    comment = "Trait that makes agents conversational and friendly."
                },
                data = {
                    prompt =
                    "You are a friendly, conversational assistant.\nAlways respond in a natural, engaging way.\nAsk follow-up questions to keep the conversation flowing.\nUse a warm, approachable tone."
                }
            },
            ["wippy.agents:thinking_tag_user"] = {
                id = "wippy.agents:thinking_tag_user",
                kind = "registry.entry",
                meta = {
                    type = "agent.trait",
                    name = "Thinking Tag (User)",
                    comment = "Trait that adds structured thinking tags for user visibility."
                },
                data = {
                    prompt = "When tackling complex problems, use <thinking> tags to show your reasoning process."
                }
            },
            ["wippy.agents:non_trait_entry"] = {
                id = "wippy.agents:non_trait_entry",
                kind = "registry.entry",
                meta = {
                    type = "something.else",
                    name = "Not A Trait",
                    comment = "This is not a trait entry."
                },
                data = {
                    some_field = "some value"
                }
            }
        }

        local mock_registry

        before_each(function()
            -- Create mock registry for testing
            mock_registry = {
                get = function(id)
                    return trait_entries[id]
                end,
                find = function(query)
                    local results = {}

                    for _, entry in pairs(trait_entries) do
                        local matches = true

                        -- Match on kind
                        if query[".kind"] and entry.kind ~= query[".kind"] then
                            matches = false
                        end

                        -- Match on meta.type
                        if query["meta.type"] and entry.meta.type ~= query["meta.type"] then
                            matches = false
                        end

                        -- Match on meta.name
                        if query["meta.name"] and entry.meta.name ~= query["meta.name"] then
                            matches = false
                        end

                        if matches then
                            table.insert(results, entry)
                        end
                    end

                    return results
                end
            }

            -- Inject mock registry
            traits._registry = mock_registry
        end)

        after_each(function()
            -- Reset the injected registry
            traits._registry = nil
        end)

        it("should get a trait by ID", function()
            local trait, err = traits.get_by_id("wippy.agents:conversational")

            expect(err).to_be_nil()
            expect(trait).not_to_be_nil()
            expect(trait.id).to_equal("wippy.agents:conversational")
            expect(trait.name).to_equal("Conversational")
            expect(trait.description).to_equal("Trait that makes agents conversational and friendly.")
            expect(trait.prompt).to_contain("You are a friendly, conversational assistant")
        end)

        it("should handle trait not found by ID", function()
            local trait, err = traits.get_by_id("nonexistent")

            expect(trait).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err:match("No trait found")).not_to_be_nil()
        end)

        it("should validate entry is a trait when getting by ID", function()
            local trait, err = traits.get_by_id("wippy.agents:non_trait_entry")

            expect(trait).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err:match("Entry is not a trait")).not_to_be_nil()
        end)

        it("should get a trait by name", function()
            local trait, err = traits.get_by_name("Conversational")

            expect(err).to_be_nil()
            expect(trait).not_to_be_nil()
            expect(trait.name).to_equal("Conversational")
            expect(trait.id).to_equal("wippy.agents:conversational")
        end)

        it("should handle trait not found by name", function()
            local trait, err = traits.get_by_name("NonexistentTrait")

            expect(trait).to_be_nil()
            expect(err).not_to_be_nil()
            expect(err:match("No trait found with name")).not_to_be_nil()
        end)

        it("should get all available traits", function()
            local all_traits = traits.get_all()

            -- Only entries with type "agent.trait" should be returned
            expect(#all_traits).to_equal(2)

            -- Verify traits are present in the results
            local found_conversational = false
            local found_thinking = false

            for _, trait in ipairs(all_traits) do
                if trait.id == "wippy.agents:conversational" then
                    found_conversational = true
                    expect(trait.name).to_equal("Conversational")
                elseif trait.id == "wippy.agents:thinking_tag_user" then
                    found_thinking = true
                    expect(trait.name).to_equal("Thinking Tag (User)")
                end
            end

            expect(found_conversational).to_be_true()
            expect(found_thinking).to_be_true()
        end)

        it("should handle empty result when getting all traits", function()
            -- Create a mock registry that returns empty results
            traits._registry = {
                find = function(query)
                    return {}
                end
            }

            local all_traits = traits.get_all()
            expect(#all_traits).to_equal(0)
        end)

        it("should require parameter for get_by_id", function()
            local trait, err = traits.get_by_id(nil)

            expect(trait).to_be_nil()
            expect(err).to_equal("Trait ID is required")
        end)

        it("should require parameter for get_by_name", function()
            local trait, err = traits.get_by_name(nil)

            expect(trait).to_be_nil()
            expect(err).to_equal("Trait name is required")
        end)
    end)
end

return require("test").run_cases(define_tests)
