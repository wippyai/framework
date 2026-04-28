local logger = require("logger"):named("llm")

local output = {}

---------------------------
-- Type Aliases
---------------------------

type ErrorInfo = {
    type: string,
    message: string,
    code: any?,
}

type OutputChunk = {
    type: string,
    content: string?,
    error: ErrorInfo?,
    name: string?,
    arguments: string?,
    id: string?,
    meta: table?,
    usage: UsageInfo?,
}

type UsageInfo = {
    prompt_tokens: number,
    completion_tokens: number,
    thinking_tokens: number,
    cache_write_tokens: number,
    cache_read_tokens: number,
    total_tokens: number,
}

type DoneMeta = {
    finish_reason: string?,
    model: string?,
}

type Streamer = {
    pid: string,
    topic: string,
    buffer: string,
    buffer_size: number,
    send_content: (self: Streamer, text: string) -> boolean,
    send_thinking: (self: Streamer, text: string) -> boolean,
    send_tool_call: (self: Streamer, name: string, arguments: string, id: string?) -> boolean,
    send_error: (self: Streamer, type: string, message: string, code: any?) -> boolean,
    send_done: (self: Streamer, meta: DoneMeta?) -> boolean,
    buffer_content: (self: Streamer, text: string?) -> boolean,
    flush: (self: Streamer) -> boolean,
}

---------------------------
-- Chunk Types
---------------------------

-- Result type identifiers
output.TYPE = {
    CONTENT = "chunk",       -- Regular text content
    TOOL_CALL = "tool_call", -- Tool call request
    ERROR = "error",         -- Error
    THINKING = "thinking",   -- Thinking process
    DONE = "done"           -- Completion marker
}

-- Error type constants
output.ERROR_TYPE = {
    INVALID_REQUEST = "invalid_request",
    AUTHENTICATION = "authentication_error",
    RATE_LIMIT = "rate_limit_exceeded",
    SERVER_ERROR = "server_error",
    CONTEXT_LENGTH = "context_length_exceeded",
    CONTENT_FILTER = "content_filtered",
    TIMEOUT = "timeout_error",
    MODEL_ERROR = "model_error",
    NETWORK_ERROR = "network_error"
}

-- Map LLM error types to structured error kinds and retryable flags
output.ERROR_KIND_MAP = {
    [output.ERROR_TYPE.RATE_LIMIT]      = { kind = errors.RATE_LIMITED,     retryable = true },
    [output.ERROR_TYPE.SERVER_ERROR]    = { kind = errors.UNAVAILABLE,      retryable = true },
    [output.ERROR_TYPE.TIMEOUT]         = { kind = errors.TIMEOUT,          retryable = true },
    [output.ERROR_TYPE.NETWORK_ERROR]   = { kind = errors.UNAVAILABLE,      retryable = true },
    [output.ERROR_TYPE.INVALID_REQUEST] = { kind = errors.INVALID,          retryable = false },
    [output.ERROR_TYPE.AUTHENTICATION]  = { kind = errors.PERMISSION_DENIED, retryable = false },
    [output.ERROR_TYPE.MODEL_ERROR]     = { kind = errors.NOT_FOUND,        retryable = false },
    [output.ERROR_TYPE.CONTEXT_LENGTH]  = { kind = errors.INVALID,          retryable = false },
    [output.ERROR_TYPE.CONTENT_FILTER]  = { kind = errors.INVALID,          retryable = false },
}

-- Internal: turn (kind, message, details) into a stdlib `errors` value
-- and log at the single observability point.
local function build_error(kind_type, message, details)
    local mapping = output.ERROR_KIND_MAP[kind_type] or
        { kind = errors.UNKNOWN, retryable = false }

    details = details or {}

    local err = errors.new({
        message = message or "LLM error",
        kind = mapping.kind,
        retryable = mapping.retryable,
        details = details
    })

    logger:error("llm provider error", {
        kind = mapping.kind,
        retryable = mapping.retryable,
        provider = details.provider,
        operation = details.operation,
        model = details.model,
        message = message,
        details = details
    })

    return err
end

local ErrorBuilder = {}
ErrorBuilder.__index = ErrorBuilder

function ErrorBuilder:with_contract(contract_args)
    self._contract = contract_args
    return self
end

function ErrorBuilder:classifier(fn)
    self._classifier = fn
    return self
end

function ErrorBuilder:kind(k)
    self._kind = k
    return self
end

function ErrorBuilder:message(m)
    self._message = m
    return self
end

function ErrorBuilder:details(d)
    self._details = d
    return self
end

function ErrorBuilder:from(http_err)
    self._http_err = http_err
    return self
end

function ErrorBuilder:build()
    -- Snapshot per-call state, then reset so the builder is reusable.
    local kind_type = self._kind
    local message   = self._message
    local details   = self._details
    local http_err  = self._http_err

    self._kind     = nil
    self._message  = nil
    self._details  = nil
    self._http_err = nil

    local merged_details = {}

    -- 1. Provider-specific classifier on HTTP / transport error if given.
    if http_err and self._classifier then
        local c_kind, c_message, c_details = self._classifier(http_err)
        kind_type = kind_type or c_kind
        message   = message   or c_message
        if c_details then
            for k, v in pairs(c_details) do merged_details[k] = v end
        end
    end

    -- 2. Provider-specific overrides on top.
    if details then
        for k, v in pairs(details) do merged_details[k] = v end
    end

    -- 3. Builder-level context (provider / operation / model from contract).
    merged_details.provider  = self._provider
    merged_details.operation = self._operation
    if self._contract and self._contract.model then
        merged_details.model = self._contract.model
    end

    return build_error(kind_type or output.ERROR_TYPE.SERVER_ERROR, message, merged_details)
end

local function builder_factory(operation)
    return function(arg)
        local self = {
            _operation = operation,
            _provider = provider,
            _contract = arg._provider_id,
            _classifier = nil,
            _kind = nil,
            _message = nil,
            _details = nil,
            _http_err = nil
        }
        return setmetatable(self, ErrorBuilder)
    end
end

output.errors = {
    generate = builder_factory("generate"),
    structured_output = builder_factory("structured_output"),
    embed = builder_factory("embed"),
    status = builder_factory("status")
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
function output.error(err_type: string, message: string, code: any?): OutputChunk
    return {
        type = output.TYPE.ERROR,
        error = {
            type = err_type or output.ERROR_TYPE.SERVER_ERROR,
            message = message or "Unknown error",
            code = code
        }
    }
end

-- Format a content response
function output.content(text: string): OutputChunk
    return {
        type = output.TYPE.CONTENT,
        content = text
    }
end

-- Format a thinking response
function output.thinking(content: string): OutputChunk
    return {
        type = output.TYPE.THINKING,
        content = content
    }
end

-- Format a tool call response
function output.tool_call(name: string, arguments: string, id: string?): OutputChunk
    return {
        type = output.TYPE.TOOL_CALL,
        name = name,
        arguments = arguments,
        id = id
    }
end

-- Format a done/completion response
function output.done(meta: DoneMeta?): OutputChunk
    return {
        type = output.TYPE.DONE,
        meta = meta or {}
    }
end

-- Create usage information
function output.usage(prompt_tokens: number?, completion_tokens: number?, thinking_tokens: number?, cache_write_tokens: number?, cache_read_tokens: number?): UsageInfo
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
function output.wrap(result_type: string, content: any, usage_info: UsageInfo?): OutputChunk
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
    elseif result_type == output.TYPE.DONE then
        wrapped.meta = content
    end

    if usage_info then
        wrapped.usage = usage_info
    end

    return wrapped :: OutputChunk
end

---------------------------
-- Streaming Functions
---------------------------

-- Create a new streamer for a specific PID
function output.streamer(pid: string?, topic: string?, buffer_size: number?): (Streamer?, string?)
    if not pid then
        return nil, "PID is required for streamer"
    end

    local streamer = {
        pid = pid,
        topic = topic or "llm_response",
        buffer = "",
        buffer_size = buffer_size or 10 -- Default buffer size
    }

    local target_pid = tostring(pid)
    local target_topic = tostring(topic or "llm_response")

    -- Send content chunk
    streamer.send_content = function(self: Streamer, text: string): boolean
        return process.send(target_pid, target_topic, output.content(text))
    end

    -- Send thinking chunk
    streamer.send_thinking = function(self: Streamer, text: string): boolean
        return process.send(target_pid, target_topic, output.thinking(text))
    end

    -- Send tool call chunk
    streamer.send_tool_call = function(self: Streamer, name: string, arguments: string, id: string?): boolean
        return process.send(target_pid, target_topic, output.tool_call(name, arguments, id))
    end

    -- Send error chunk
    streamer.send_error = function(self: Streamer, err_type: string, message: string, code: any?): boolean
        return process.send(target_pid, target_topic, output.error(err_type, message, code))
    end

    -- Send done chunk
    streamer.send_done = function(self: Streamer, meta: DoneMeta?): boolean
        return process.send(target_pid, target_topic, output.done(meta))
    end

    -- Buffer content and send when a natural break is detected
    streamer.buffer_content = function(self: Streamer, text: string?): boolean
        self.buffer = self.buffer .. (text or "")

        -- Stream chunks when buffer is larger than buffer_size or sentence appears complete
        if self.buffer_size > 0 and (#self.buffer >= self.buffer_size or self.buffer:match("[%.%!%?]%s*$")) then
            process.send(target_pid, target_topic, output.content(self.buffer))
            self.buffer = ""
            return true
        end

        return false
    end

    -- Flush any remaining buffered content
    streamer.flush = function(self: Streamer): boolean
        if #self.buffer > 0 then
            process.send(target_pid, target_topic, output.content(self.buffer))
            self.buffer = ""
            return true
        end
        return false
    end

    return streamer :: Streamer
end

-- Message injected into conversation when LLM output is truncated mid-tool-call
output.TRUNCATION_MSG = "Your previous response was truncated because it exceeded the maximum token limit. The tool calls you attempted were incomplete and have been discarded. Please retry with a shorter response. Break your work into smaller steps if needed."

-- Detect truncated LLM responses that contain incomplete tool calls
function output.detect_truncation(result)
    if not result then return false end
    if result.finish_reason ~= output.FINISH_REASON.LENGTH then return false end
    if not result.tool_calls or #result.tool_calls == 0 then return false end
    return true
end

return output
