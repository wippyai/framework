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
local function execute(base_prompt: string?): TimeAwareResult
    local format = ctx.get("format")
    return {
        agent_options = {
            turn_context = {
                time = {
                    timezone = tostring(ctx.get("timezone") or "UTC"),
                    format = type(format) == "string" and format or nil,
                },
            },
        },
    }
end

return { execute = execute }
