-- Retention owner for token usage records. A host that discovers functions typed
-- kickside.retention.owner calls it on its retention schedule; elsewhere it is inert.
local time = require("time")
local token_usage_repo = require("token_usage_repo")
local retention_policy = require("retention_policy")

local function run()
    local policy, policy_err = retention_policy.policy()
    if policy_err then
        return { success = false, error = policy_err }
    end

    local now_ms = math.floor(time.now():unix_nano() / 1000000)
    local cutoff = math.floor((now_ms - policy.token_usage_ms) / 1000)
    local progress, prune_err = token_usage_repo.prune(cutoff, policy.batch_token_usage)
    if prune_err then
        return { success = false, error = errors.new({ message = prune_err, kind = errors.UNAVAILABLE, retryable = true }) }
    end

    local deadline_ms = nil
    if not progress.needs_continue and progress.oldest then
        deadline_ms = progress.oldest * 1000 + policy.token_usage_ms
    end
    return {
        success = true,
        deleted = progress.deleted,
        needs_continue = progress.needs_continue,
        deadline_ms = deadline_ms,
    }
end

return { run = run }
