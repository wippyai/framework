local token_usage_repo = require("token_usage_repo")
local security = require("security")
local ctx = require("ctx")
local logger = require("logger"):named("usage")

local usage_tracker = {
    _repo = token_usage_repo
}

local function breakdown_problem(by_ttl, cache_write_tokens)
    if type(by_ttl) ~= "table" then
        return "breakdown must be a table of cache lifetime to token count"
    end
    local total = 0
    for ttl, tokens in pairs(by_ttl) do
        if type(ttl) ~= "string" or ttl == "" then
            return "breakdown keys must be non-empty cache lifetimes"
        end
        if type(tokens) ~= "number" or tokens < 0 or tokens % 1 ~= 0 then
            return "breakdown counts must be non-negative integers"
        end
        total = total + tokens
    end
    if total > cache_write_tokens then
        return "breakdown exceeds cache write tokens"
    end
    return nil
end

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

    local cache_write_by_ttl = options.cache_write_by_ttl
    if cache_write_by_ttl ~= nil then
        local problem = breakdown_problem(cache_write_by_ttl, cache_write_tokens)
        if problem then
            logger:warn("cache write breakdown dropped", {
                model_id = model_id,
                cache_write_tokens = cache_write_tokens,
                reason = problem
            })
            cache_write_by_ttl = nil
        end
    end

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
        cache_write_tokens = cache_write_tokens,
        cache_write_by_ttl = cache_write_by_ttl
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