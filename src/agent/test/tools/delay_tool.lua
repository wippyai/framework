local time = require("time")
local ctx = require("ctx")

type DelayToolArgs = {
    message: string?,
    delay_ms: number?,
}

type DelayToolResult = {
    message: string,
    delay_applied: number,
    timestamp: string,
    unix_time: number,
    context_received: {[string]: any},
    context_error: string?,
}

local function delayed_echo(args: DelayToolArgs): DelayToolResult
    local message = args.message or "Hello"
    local delay_ms = args.delay_ms

    if not delay_ms then
        local all_context, ctx_err = ctx.all()
        if not ctx_err and all_context and all_context.default_delay then
            delay_ms = all_context.default_delay
        else
            delay_ms = 100
        end
    end

    local duration_str = tostring(delay_ms) .. "ms"
    time.sleep(duration_str)

    local all_context, ctx_err = ctx.all()
    local context_info = all_context or {}

    local now = time.now()
    return {
        message = message,
        delay_applied = delay_ms,
        timestamp = now:format_rfc3339(),
        unix_time = now:unix(),
        context_received = context_info,
        context_error = ctx_err
    } :: DelayToolResult
end

return { delayed_echo = delayed_echo }
