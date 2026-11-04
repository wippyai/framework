local hash = require("hash")

local tool_id = {}

-- The tool call ids Claude and Bedrock accept. A provider's id format can leave
-- another provider's ids outside it after a handoff.
tool_id.NATIVE_PATTERN = "^[a-zA-Z0-9_-]+$"

local function fit(base: string, suffix: string, max_length: number?): string
    if max_length and #base + #suffix > max_length then
        base = base:sub(1, max_length - #suffix)
    end
    return base .. suffix
end

-- A function mapping a conversation's tool call ids to ids a provider accepts, under
-- `limits`: { pattern?, max_length? }. Ids within the limits pass unchanged. Others
-- get a translation derived from a digest of the id, the same on every request because
-- it is part of the prefix, shared by calls and results, and collision-checked against
-- all ids in the conversation: character replacement or truncation alone would merge
-- distinct identities.
function tool_id.mapper(messages: {any}, limits: table): (id: any) -> string
    local used, translated = {}, {}
    local reserved = false
    local function reserve_ids()
        -- Normal native ids need no extra history scan or hashing. Reserve all
        -- ids only if a foreign-provider id actually needs translation.
        if reserved then return end
        reserved = true
        local function reserve(id)
            if type(id) == "string" then used[id] = id end
        end
        for _, msg in ipairs(messages) do
            reserve(msg.function_call_id)
            if msg.function_call then reserve(msg.function_call.id) end
            if type(msg.content) == "table" then
                for _, part in ipairs(msg.content) do
                    if part.type == "function_call" or part.type == "tool_use" then reserve(part.id) end
                end
            end
        end
    end
    return function(id)
        if type(id) ~= "string" or id == "" then error("Tool call ID is required") end
        local fits_pattern = not limits.pattern or id:match(limits.pattern)
        local fits_length = not limits.max_length or #id <= limits.max_length
        if fits_pattern and fits_length then return id end
        if translated[id] then return translated[id] end
        reserve_ids()
        local digest, err = hash.sha256(id)
        if err then error(err) end
        local base = "tool-" .. digest
        local candidate, suffix = fit(base, "", limits.max_length), 0
        while used[candidate] and used[candidate] ~= id do
            suffix = suffix + 1
            candidate = fit(base, "-" .. suffix, limits.max_length)
        end
        used[candidate], translated[id] = id, candidate
        return candidate
    end
end

return tool_id
