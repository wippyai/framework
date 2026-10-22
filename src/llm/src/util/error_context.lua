local error_context = {}

-- Legacy discovery callers still receive strings. Native failures keep their
-- machine-readable cause when a discovery boundary adds context to the message.
function error_context.prefix(err: string | error, prefix: string): string | error
    local message = prefix .. tostring(err)
    if type(err) == "string" then return message end
    return errors.new({
        kind = err:kind(),
        retryable = err:retryable(),
        details = err:details(),
        message = message,
    })
end

return error_context
