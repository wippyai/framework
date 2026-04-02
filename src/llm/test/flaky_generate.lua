local output = require("output")
local store = require("store")

local function handler(contract_args)
    local s, serr = store.get("app:test_store")
    if serr then return nil, errors.new({ message = "store error: " .. serr, kind = "Internal" }) end

    local count = (s:get("flaky_generate_count") or 0) + 1
    s:set("flaky_generate_count", count)

    if count < 3 then
        return nil, errors.new({
            message = "Temporary failure (attempt " .. count .. ")",
            kind = "Unavailable",
            retryable = true,
        })
    end

    return {
        success = true,
        result = {
            content = "Generated after " .. count .. " attempts",
            tool_calls = {},
        },
        tokens = {
            prompt_tokens = 10,
            completion_tokens = 5,
            total_tokens = 15,
        },
        finish_reason = "stop",
        metadata = { attempts = count },
    }
end

return { handler = handler }
