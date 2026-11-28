local llm = require("llm")

-- track answers how llm tracks usage under the caller's security context.
local function track()
    llm._usage_tracker = nil
    local usage_id, err = llm.track_usage({ tokens = { prompt_tokens = 1, completion_tokens = 1 } }, "fixture-model", {})
    if err then
        local e = err :: error
        return { kind = e:kind(), retryable = e:retryable(), message = e:message() }
    end
    return { usage_id = usage_id }
end

return { track = track }
