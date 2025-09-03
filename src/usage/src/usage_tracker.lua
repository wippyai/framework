local token_usage_repo = require("token_usage_repo")
local security = require("security")

local usage_tracker = {
    _repo = token_usage_repo
}

function usage_tracker.track_usage(model_id, prompt_tokens, completion_tokens, thinking_tokens, cache_read_tokens, cache_write_tokens, options)
    if not model_id or model_id == "" then
        return nil, "Model ID is required"
    end

    if type(prompt_tokens) ~= "number" or prompt_tokens < 0 then
        return nil, "Prompt tokens must be a non-negative number"
    end

    if type(completion_tokens) ~= "number" or completion_tokens < 0 then
        return nil, "Completion tokens must be a non-negative number"
    end

    if type(thinking_tokens) ~= "number" or thinking_tokens < 0 then
        return nil, "Thinking tokens must be a non-negative number"
    end

    if type(cache_read_tokens) ~= "number" or cache_read_tokens < 0 then
        return nil, "Cache read tokens must be a non-negative number"
    end

    if type(cache_write_tokens) ~= "number" or cache_write_tokens < 0 then
        return nil, "Cache write tokens must be a non-negative number"
    end

    options = options or {}

    local actor = security.actor()
    if not actor then
        return nil, "No security actor available"
    end

    local user_id = actor:id()
    if not user_id then
        return nil, "Invalid security actor"
    end

    local create_options = {
        context_id = options.context_id,
        timestamp = options.timestamp,
        metadata = options.metadata,
        thinking_tokens = thinking_tokens,
        cache_read_tokens = cache_read_tokens,
        cache_write_tokens = cache_write_tokens
    }

    local record, err = usage_tracker._repo.create(
        user_id,
        model_id,
        prompt_tokens,
        completion_tokens,
        create_options
    )

    if err then
        return nil, err
    end

    return record.usage_id
end

return usage_tracker