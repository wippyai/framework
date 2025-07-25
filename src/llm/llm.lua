local models = require("models")
local funcs = require("funcs")
local token_usage_repo = require("token_usage_repo")
local uuid = require("uuid")
local security = require("security")
local json = require("json")

local llm = {}

llm._models = nil
llm._executor = nil

local function get_models()
    return llm._models or models
end

local function get_executor(provider_options)
    local executor = llm._executor or funcs.new()
    if provider_options then
        executor = executor:with_context({
            provider_options = provider_options
        })
    end

    return executor
end

llm.CAPABILITY = models.CAPABILITY

llm.ERROR_TYPE = {
    INVALID_REQUEST = "invalid_request",
    AUTHENTICATION = "authentication_error",
    RATE_LIMIT = "rate_limit_exceeded",
    SERVER_ERROR = "server_error",
    CONTEXT_LENGTH = "context_length_exceeded",
    CONTENT_FILTER = "content_filter",
    TIMEOUT = "timeout_error",
    MODEL_ERROR = "model_error"
}

llm.FINISH_REASON = {
    STOP = "stop",
    LENGTH = "length",
    CONTENT_FILTER = "filtered",
    TOOL_CALL = "tool_call",
    ERROR = "error"
}

function llm.set_executor(executor)
    llm._executor = executor
    return llm
end

function llm.set_models(models_module)
    llm._models = models_module
    if models_module and models_module.CAPABILITY then
        llm.CAPABILITY = models_module.CAPABILITY
    end
    return llm
end

function llm._filter_options(options, model_card)
    if not options or not model_card then return {} end

    local filtered = {}
    for k, v in pairs(options) do
        filtered[k] = v
    end

    local capabilities = {}
    for _, cap in ipairs(model_card.capabilities or {}) do
        capabilities[cap] = true
    end

    if filtered.thinking_effort and not capabilities[llm.CAPABILITY.THINKING] then
        filtered.thinking_effort = nil
    end

    if not capabilities[llm.CAPABILITY.TOOL_USE] then
        filtered.tool_ids = nil
        filtered.tool_schemas = nil
        filtered.tool_call = nil
    end

    return filtered
end

function llm.track_usage(response, model_id, options)
    options = options or {}

    local user_id = "default_user_id"
    local actor = security.actor()
    local actor_meta = actor and actor:meta() or {}

    if options.user_id then
        user_id = options.user_id
    elseif actor then
        if tostring(actor:id()) ~= "" then
            user_id = actor:id()
        end
    end

    local context_id = "default_context_id"
    if options.context_id then
        context_id = options.context_id
    elseif options.stream and options.stream.topic then
        context_id = options.stream.topic
    elseif actor_meta and actor_meta.context_id then
        context_id = actor_meta.context_id
    end

    local prompt_tokens = 0
    local completion_tokens = 0
    local thinking_tokens = 0
    local cache_read_tokens = 0
    local cache_write_tokens = 0

    if response and response.tokens then
        prompt_tokens = response.tokens.prompt_tokens or 0
        completion_tokens = response.tokens.completion_tokens or 0
        thinking_tokens = response.tokens.thinking_tokens or 0
        cache_read_tokens = response.tokens.cache_read_tokens or 0
        cache_write_tokens = response.tokens.cache_write_tokens or 0
    end

    local usage_id = options.usage_id
    if not usage_id then
        local id, err = uuid.v4()
        if err then
            print("Error generating UUID: " .. err)
            usage_id = "error_generating_uuid"
        else
            usage_id = id
        end
    end

    local meta = options.meta or {}

    local usage_record, err = token_usage_repo.create(
        user_id,
        model_id,
        prompt_tokens,
        completion_tokens,
        {
            context_id = context_id,
            meta = meta,
            timestamp = options.timestamp,
            thinking_tokens = thinking_tokens,
            cache_read_tokens = cache_read_tokens,
            cache_write_tokens = cache_write_tokens
        }
    )
    if err then
        print("Error recording token usage: " .. err)
    end

    local wrapped_response = response

    if usage_record then
        wrapped_response.usage_record = usage_record
    end

    return wrapped_response
end

function llm.generate(prompt_input, options)
    if not options or not options.model then
        return nil, "Model is required in options"
    end

    local capability = llm.CAPABILITY.GENERATE
    if options.tool_ids or options.tool_schemas or options.tools then
        capability = llm.CAPABILITY.TOOL_USE
    end

    local models_module = get_models()
    local model_card, err = models_module.get_by_name(options.model)
    if not model_card then
        return nil, "Model not found: " .. (err or "unknown error")
    end

    local handler_id = nil
    if capability == llm.CAPABILITY.GENERATE then
        handler_id = model_card.handlers.generate
    elseif capability == llm.CAPABILITY.TOOL_USE then
        handler_id = model_card.handlers.call_tools
    end

    if not handler_id then
        return nil, "Model does not support " .. capability
    end

    local messages = {}

    if type(prompt_input) == "table" and prompt_input.build and type(prompt_input.build) == "function" then
        local prompt_result = prompt_input:build()
        messages = prompt_result.messages
    elseif type(prompt_input) == "table" and prompt_input.messages then
        messages = prompt_input.messages
    elseif type(prompt_input) == "table" and prompt_input.get_messages and type(prompt_input.get_messages) == "function" then
        messages = prompt_input:get_messages()
    elseif type(prompt_input) == "table" and #prompt_input > 0 then
        messages = prompt_input
    elseif type(prompt_input) == "string" then
        table.insert(messages, {
            role = "user",
            content = prompt_input
        })
    else
        return nil, "Invalid prompt input format"
    end

    local filtered_options = llm._filter_options(options, model_card)

    local request = {
        model = model_card.provider_model,
        messages = messages,
        options = filtered_options
    }

    if options.stream then
        request.stream = options.stream
    end

    if capability == llm.CAPABILITY.TOOL_USE then
        if options.tool_ids then
            request.tool_ids = options.tool_ids
        end

        if options.tool_schemas then
            request.tool_schemas = options.tool_schemas
        end

        if options.tools then
            request.tools = options.tools
        end

        if options.tool_call then
            request.tool_call = options.tool_call
        end
    end

    local executor = get_executor(model_card.provider_options)

    local result, err = executor:call(handler_id, request)
    if err then
        return nil, err
    end

    if result.error then
        return nil, result.error_message or result.error
    end

    if type(result.result) == "table" then
        result.tool_calls = result.result.tool_calls or {}
        result.result = result.result.content or ""
    end

    return llm.track_usage(result, options.model, options)
end

function llm.structured_output(schema, prompt_input, options)
    if not options or not options.model then
        return nil, "Model is required in options"
    end

    if not schema then
        return nil, "Schema is required"
    end

    local models_module = get_models()
    local model_card, err = models_module.get_by_name(options.model)
    if not model_card then
        return nil, "Model not found: " .. (err or "unknown error")
    end

    local handler_id = model_card.handlers.structured_output
    if not handler_id then
        return nil, "Model does not support structured output"
    end

    local messages = {}

    if type(prompt_input) == "table" and prompt_input.build and type(prompt_input.build) == "function" then
        local prompt_result = prompt_input:build()
        messages = prompt_result.messages
    elseif type(prompt_input) == "table" and prompt_input.messages then
        messages = prompt_input.messages
    elseif type(prompt_input) == "table" and prompt_input.get_messages and type(prompt_input.get_messages) == "function" then
        messages = prompt_input:get_messages()
    elseif type(prompt_input) == "table" and #prompt_input > 0 then
        messages = prompt_input
    elseif type(prompt_input) == "string" then
        table.insert(messages, {
            role = "user",
            content = prompt_input
        })
    else
        return nil, "Invalid prompt input format"
    end

    local filtered_options = llm._filter_options(options, model_card)

    local request = {
        model = model_card.provider_model,
        schema = schema,
        messages = messages,
        options = filtered_options
    }

    local executor = get_executor(model_card.provider_options)
    local result, err = executor:call(handler_id, request)

    if result.error then
        return nil, result.error_message or result.error
    end

    if err then
        return nil, err
    end

    return llm.track_usage(result, options.model, options)
end

function llm.embed(text, options)
    if not options or not options.model then
        return nil, "Model is required in options"
    end

    local models_module = get_models()
    local model_card, err = models_module.get_by_name(options.model)
    if not model_card then
        return nil, "Model not found: " .. (err or "unknown error")
    end

    local handler_id = model_card.handlers.embeddings
    if not handler_id then
        return nil, "Model does not support embeddings"
    end

    local request = {
        model = model_card.provider_model,
        input = text,
        dimensions = options.dimensions or model_card.dimensions,
        options = llm._filter_options(options, model_card)
    }

    local executor = get_executor(model_card.provider_options)
    local result, err = executor:call(handler_id, request)

    if err then
        return nil, err
    end

    if result and result.error then
        return nil, result.error_message or result.error or "Unknown error"
    end

    return llm.track_usage(result, options.model, options)
end

function llm.available_models(capability)
    local models_module = get_models()
    local all_models = models_module.get_all()

    if not capability then
        return all_models
    end

    local filtered = {}
    for _, model in ipairs(all_models) do
        local has_capability = false
        if model.capabilities then
            for _, cap in ipairs(model.capabilities) do
                if cap == capability then
                    has_capability = true
                    break
                end
            end
        end

        local has_handler = false
        if capability == llm.CAPABILITY.GENERATE and model.handlers and model.handlers.generate then
            has_handler = true
        elseif capability == llm.CAPABILITY.TOOL_USE and model.handlers and model.handlers.call_tools then
            has_handler = true
        elseif capability == llm.CAPABILITY.STRUCTURED_OUTPUT and model.handlers and model.handlers.structured_output then
            has_handler = true
        elseif capability == llm.CAPABILITY.EMBED and model.handlers and model.handlers.embeddings then
            has_handler = true
        elseif capability == llm.CAPABILITY.THINKING and model.handlers and model.handlers.generate then
            has_handler = true
        end

        if has_capability and has_handler then
            table.insert(filtered, model)
        end
    end

    return filtered
end

function llm.models_by_provider(capability)
    local models_module = get_models()
    local providers = models_module.get_by_provider()

    if not capability then
        return providers
    end

    for provider_name, provider in pairs(providers) do
        local filtered_models = {}

        for _, model in ipairs(provider.models) do
            local has_capability = false
            if model.capabilities then
                for _, cap in ipairs(model.capabilities) do
                    if cap == capability then
                        has_capability = true
                        break
                    end
                end
            end

            local has_handler = false
            if capability == llm.CAPABILITY.GENERATE and model.handlers and model.handlers.generate then
                has_handler = true
            elseif capability == llm.CAPABILITY.TOOL_USE and model.handlers and model.handlers.call_tools then
                has_handler = true
            elseif capability == llm.CAPABILITY.STRUCTURED_OUTPUT and model.handlers and model.handlers.structured_output then
                has_handler = true
            elseif capability == llm.CAPABILITY.EMBED and model.handlers and model.handlers.embeddings then
                has_handler = true
            end

            if has_capability and has_handler then
                table.insert(filtered_models, model)
            end
        end

        provider.models = filtered_models
    end

    return providers
end

return llm
