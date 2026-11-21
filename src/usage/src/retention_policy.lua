local registry = require("registry")

local ENTRY = "wippy.usage:policy"
local DAY_MS = 86400000
local MAX_DAYS = 3650
local MAX_BATCH = 500

local retention_policy = {}

local function invalid(message)
    return errors.new({ message = ENTRY .. ": " .. message, kind = errors.INVALID, retryable = false })
end

-- Validates the retention section of the policy entry metadata.
function retention_policy.resolve(meta)
    local retention = type(meta) == "table" and meta.retention or nil
    if type(retention) ~= "table" then
        return nil, invalid("retention section is required")
    end
    local raw = retention.token_usage
    local digits = type(raw) == "string" and string.match(raw, "^(%d+)d$") or nil
    local days = digits and tonumber(digits) or nil
    if not days or days < 1 or days > MAX_DAYS then
        return nil, invalid("retention.token_usage must be a duration in days from 1d to " .. MAX_DAYS .. "d")
    end
    local batch = retention.batch_token_usage
    if type(batch) ~= "number" or batch ~= math.floor(batch) or batch < 1 or batch > MAX_BATCH then
        return nil, invalid("retention.batch_token_usage must be an integer in [1," .. MAX_BATCH .. "]")
    end
    return { token_usage_ms = days * DAY_MS, batch_token_usage = batch }
end

-- Reads and validates the declared policy entry.
function retention_policy.policy()
    local entry, err = registry.get(ENTRY)
    if err or type(entry) ~= "table" then
        return nil, errors.new({ message = ENTRY .. " is unavailable: " .. tostring(err),
            kind = errors.UNAVAILABLE, retryable = true })
    end
    return retention_policy.resolve(entry.meta)
end

return retention_policy
