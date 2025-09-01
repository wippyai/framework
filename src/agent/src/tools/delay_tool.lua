local time = require("time")
local ctx = require("ctx")

local function delayed_echo(args)
    local message = args.message or "Hello"
    local delay_ms = args.delay_ms

    -- If delay_ms not provided in args, check context for default_delay
    if not delay_ms then
        local all_context, ctx_err = ctx.all()
        if not ctx_err and all_context and all_context.default_delay then
            delay_ms = all_context.default_delay
        else
            delay_ms = 100  -- Final fallback
        end
    end

    -- Simulate work with sleep
    local duration_str = tostring(delay_ms) .. "ms"
    time.sleep(duration_str)

    -- Get ALL context information that was passed to the tool
    local all_context, ctx_err = ctx.all()
    local context_info = all_context or {}

    -- Return the message with timestamp and context info
    local now = time.now()
    return {
        message = message,
        delay_applied = delay_ms,
        timestamp = now:format_rfc3339(),
        unix_time = now:unix(),
        context_received = context_info,
        context_error = ctx_err
    }
end

return { delayed_echo = delayed_echo }