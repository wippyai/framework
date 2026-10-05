local test = require("test")
local uuid = require("uuid")
local embeddings = require("embeddings")

local function define_tests()
    test.describe("Embeddings library", function()
        test.it("reports the provider error when embedding generation fails", function()
            -- The test application declares no llm.model entry, so llm.embed
            -- fails and the failure must reach the caller verbatim.
            local result, err = embeddings.add(
                "Document used to exercise the embedding failure path.",
                "embeddings_test_document",
                uuid.v4(),
                "embeddings_test_context",
                {}
            )

            test.is_nil(result)
            test.not_nil(err)
            test.is_true(
                tostring(err):find("Model or class not found", 1, true) ~= nil,
                "expected the llm.embed error in the message, got: " .. tostring(err)
            )
            test.is_true(
                tostring(err):find("Unknown error", 1, true) == nil,
                "underlying error was replaced by a placeholder: " .. tostring(err)
            )
        end)
    end)
end

return test.run_cases(define_tests)
