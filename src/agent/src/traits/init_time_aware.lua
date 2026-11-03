local ctx = require("ctx")

type TimeAwareResult = {
    agent_options: {
        turn_context: {
            time: { timezone: string, format: string? },
        },
    },
}

-- Declares the per-turn time context; hosts render it with
-- wippy.agent:turn_context and persist it with each user turn.
local function execute(base_prompt: string?): (TimeAwareResult?, string?)
    if ctx.get("time_interval") ~= nil then
        return nil, "time_aware no longer rounds the time: remove time_interval; hosts render the exact minute "
            .. "from agent_options.turn_context with wippy.agent:turn_context"
    end
    -- The trait context merges with the agent context, so the layout key is
    -- namespaced: a generic "format" there belongs to someone else.
    local format = ctx.get("time_format")
    return {
        agent_options = {
            turn_context = {
                time = {
                    timezone = tostring(ctx.get("timezone") or "UTC"),
                    format = type(format) == "string" and format or nil,
                },
            },
        },
    }, nil
end

return { execute = execute }
