local token_usage_repo = require("token_usage_repo")
local security = require("security")
local ctx = require("ctx")

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

    local user_id = "system"
    local actor = security.actor()
    if actor then
        local actor_id = actor:id()
        if actor_id and actor_id ~= "" then
            user_id = actor_id
        end
    end

    local context_id = options.context_id
    if not context_id then
        context_id, _ = ctx.get("context_id")
    end

    local create_options = {
        context_id = context_id,
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