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
    -- The trait context merges with the agent context, so the layout key is
    -- namespaced: a generic "format" there belongs to someone else.
    local format = ctx.get("time_format")
    if format ~= nil and (type(format) ~= "string" or format == "") then
        return nil, "time_aware time_format must be a non-empty Go time layout string"
    end
    return {
        agent_options = {
            turn_context = {
                time = {
                    timezone = tostring(ctx.get("timezone") or "UTC"),
                    format = format,
                },
            },
        },
    }, nil
end

return { execute = execute }
