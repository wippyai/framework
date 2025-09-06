local ctx = require("ctx")

local function run(iteration_result)
    local config = ctx.all() or {}

    if config.should_fail then
        return nil, "Test failure in compress_item"
    end

    local compressed = {
        compressed_by = "compress_item",
        original_data = iteration_result
    }

    if config.extract_only and type(iteration_result) == "table" then
        compressed.data = iteration_result.value or iteration_result.result
    else
        compressed.data = iteration_result
    end

    return compressed
end

return { run = run }