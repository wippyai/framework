local test = require("test")
local thinking = require("thinking")

local function define_tests()
    describe("Thinking binding helpers", function()
        it("binds adaptive and enabled thinking objects with drop_block", function()
            for _, config in ipairs({ { type = "adaptive" }, { type = "enabled", budget_tokens = 2048 } }) do
                thinking.bind_replayed_blocks(config)
                test.eq(config.block_binding.prefix_mismatch_behavior, "drop_block")
                test.is_true(thinking.is_bound(config))
            end
        end)

        it("leaves thinking objects that take no binding unchanged", function()
            for _, config in ipairs({ { type = "between_tools" }, { type = "disabled" } }) do
                thinking.bind_replayed_blocks(config)
                test.is_nil(config.block_binding)
                test.is_false(thinking.is_bound(config))
            end
        end)

        it("accepts a missing or non-table thinking object", function()
            thinking.bind_replayed_blocks(nil)
            thinking.bind_replayed_blocks("adaptive" :: any)
            test.is_false(thinking.is_bound(nil))
            test.is_false(thinking.is_bound("adaptive" :: any))
        end)

        it("keeps a block_binding the thinking object already carries", function()
            local config = { type = "adaptive", block_binding = { prefix_mismatch_behavior = "error" } }
            thinking.bind_replayed_blocks(config)
            test.eq(config.block_binding.prefix_mismatch_behavior, "error")
            test.is_true(thinking.is_bound(config))
        end)

        it("names the binding beta", function()
            test.eq(thinking.BINDING_BETA, "thinking-binding-controls-2026-08-01")
        end)
    end)
end

return require("test").run_cases(define_tests)
