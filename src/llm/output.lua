-- Output Library - For standardized LLM output formatting
local output = {}

---------------------------
-- Chunk Types
---------------------------

-- Result type identifiers
output.TYPE = {
    CONTENT = "chunk",       -- Regular text content
    TOOL_CALL = "tool_call", -- Tool call request
    ERROR = "error",         -- Error
    THINKING = "thinking"    -- Thinking process
}

-- Error type constants
output.ERROR_TYPE = {
    INVALID_REQUEST = "invalid_request",
    AUTHENTICATION = "authentication_error",
    RATE_LIMIT = "rate_limit_exceeded",
    SERVER_ERROR = "server_error",
    CONTEXT_LENGTH = "context_length_exceeded",
    CONTENT_FILTER = "content_filter",
    TIMEOUT = "timeout_error",
    MODEL_ERROR = "model_error" -- Added new error type for invalid model
}

-- Finish/stop reason constants
output.FINISH_REASON = {
    STOP = "stop",               -- Normal completion
    LENGTH = "length",           -- Reached max tokens
    CONTENT_FILTER = "filtered", -- Content filtered
    TOOL_CALL = "tool_call",     -- Tool/function call
    ERROR = "error"              -- Other error
}

---------------------------
-- Core Formatting Functions
---------------------------

-- Format an error object
function output.error(type, message, code)
    return {
        type = output.TYPE.ERROR,
        error = {
            type = type or output.ERROR_TYPE.SERVER_ERROR,
            message = message or "Unknown error",
            code = code
        }
    }
end

-- Format a content response
function output.content(text)
    return {
        type = output.TYPE.CONTENT,
        content = text
    }
end

-- Format a thinking response
function output.thinking(content)
    return {
        type = output.TYPE.THINKING,
        content = content
    }
end

-- Format a tool call response
function output.tool_call(name, arguments, id)
    return {
        type = output.TYPE.TOOL_CALL,
        name = name,
        arguments = arguments,
        id = id
    }
end

-- Create usage information
function output.usage(prompt_tokens, completion_tokens, thinking_tokens, cache_write_tokens, cache_read_tokens)
    return {
        prompt_tokens = prompt_tokens or 0,
        completion_tokens = completion_tokens or 0,
        thinking_tokens = thinking_tokens or 0,
        cache_write_tokens = cache_write_tokens or 0,
        cache_read_tokens = cache_read_tokens or 0,
        total_tokens = (prompt_tokens or 0) + (completion_tokens or 0) + (thinking_tokens or 0)
    }
end

-- Wrap an LLM result
function output.wrap(result_type, content, usage_info)
    local wrapped = {
        type = result_type
    }

    if result_type == output.TYPE.CONTENT then
        wrapped.content = content
    elseif result_type == output.TYPE.TOOL_CALL then
        if type(content) == "table" then
            wrapped.name = content.name
            wrapped.arguments = content.arguments
            wrapped.id = content.id
        else
            wrapped.name = "unknown"
            wrapped.arguments = content
        end
    elseif result_type == output.TYPE.ERROR then
        wrapped.error = content
    elseif result_type == output.TYPE.THINKING then
        wrapped.content = content
    end

    if usage_info then
        wrapped.usage = usage_info
    end

    return wrapped
end

---------------------------
-- Streaming Functions
---------------------------

-- Create a new streamer for a specific PID
function output.streamer(pid, topic, buffer_size)
    if not pid then
        return nil, "PID is required for streamer"
    end

    local streamer = {
        pid = pid,
        topic = topic or "llm_response",
        buffer = "",
        buffer_size = buffer_size or 10 -- Default buffer size
    }

    -- Send content chunk
    streamer.send_content = function(self, text)
        return process.send(self.pid, self.topic, output.content(text))
    end

    -- Send thinking chunk
    streamer.send_thinking = function(self, text)
        return process.send(self.pid, self.topic, output.thinking(text))
    end

    -- Send tool call chunk
    streamer.send_tool_call = function(self, name, arguments, id)
        return process.send(self.pid, self.topic, output.tool_call(name, arguments, id))
    end

    -- Send error chunk
    streamer.send_error = function(self, type, message, code)
        return process.send(self.pid, self.topic, output.error(type, message, code))
    end

    -- Send done chunk
    streamer.send_done = function(self, meta)
        return process.send(self.pid, self.topic, output.done(meta))
    end

    -- Buffer content and send when a natural break is detected
    streamer.buffer_content = function(self, text)
        self.buffer = self.buffer .. (text or "")

        -- Stream chunks when buffer is larger than buffer_size or sentence appears complete
        if self.buffer_size > 0 and (#self.buffer >= self.buffer_size or self.buffer:match("[%.%!%?]%s*$")) then
            self:send_content(self.buffer)
            self.buffer = ""
            return true
        end

        return false
    end

    -- Flush any remaining buffered content
    streamer.flush = function(self)
        if #self.buffer > 0 then
            self:send_content(self.buffer)
            self.buffer = ""
            return true -- Return true regardless of what send_content returns
        end
        return false
    end

    return streamer
end

return output
