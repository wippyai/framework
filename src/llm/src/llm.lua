local models = require("models")
local providers = require("providers")
local contract = require("contract")
local uuid = require("uuid")
local security = require("security")
local json = require("json")

local llm = {}

-- Contract constants
local USAGE_TRACKER_CONTRACT = "wippy.llm:usage_tracker"

-- Dependency injection fields
llm._models = nil
llm._providers = nil
llm._usage_tracker = nil

---------------------------
-- Internal Helper Functions
---------------------------

-- Smart model resolution: name → class → error, plus "class:abc" syntax
local function resolve_model(model_identifier)
    local models_module = llm._models or models

    -- Check for explicit class syntax "class:abc"
    local class_name = model_identifier:match("^class:(.+)")
    if class_name then
        local class_models, err = models_module.get_by_class(class_name)
        if err then
            return nil, err
        end
        if class_models and #class_models > 0 then
            return class_models[1] -- First model (highest priority)
        end
        return nil, "No models found for class: " .. class_name
    end

    -- Try as model name first
    local model_card, err = models_module.get_by_name(model_identifier)
    if model_card then
        return model_card
    end

    -- Try as class name
    local class_models, class_err = models_module.get_by_class(model_identifier)
    if not class_err and class_models and #class_models > 0 then
        return class_models[1] -- First model (highest priority)
    end

    return nil, "Model or class not found: " .. model_identifier
end

-- Convert prompt input to messages array in contract format
local function prepare_messages(prompt_input)
    if type(prompt_input) == "table" and prompt_input.build and type(prompt_input.build) == "function" then
        local prompt_result = prompt_input:build()
        return prompt_result.messages
    elseif type(prompt_input) == "table" and prompt_input.messages then
        return prompt_input.messages
    elseif type(prompt_input) == "table" and prompt_input.get_messages and type(prompt_input.get_messages) == "function" then
        return prompt_input:get_messages()
    elseif type(prompt_input) == "table" and #prompt_input > 0 then
        return prompt_input
    elseif type(prompt_input) == "string" then
        return {
            {
                role = "user",
                content = { { type = "text", text = prompt_input } }
            }
        }
    else
        return nil, "Invalid prompt input format"
    end
end

-- Normalize contract response to LLM format
local function normalize_response(raw_result)
    if not raw_result then
        return nil
    end

    local normalized = {
        tokens = raw_result.tokens or {},
        finish_reason = raw_result.finish_reason,
        metadata = raw_result.metadata or {}
    }

    -- Handle different response types based on contract
    if raw_result.success == false then
        -- Error response
        return nil, raw_result.error_message or raw_result.error or "Unknown error"
    elseif raw_result.result then
        if type(raw_result.result) == "table" then
            if raw_result.result.content ~= nil then
                -- Generation response with content + tool_calls
                normalized.result = raw_result.result.content  -- Use 'result' not 'content'
                normalized.tool_calls = raw_result.result.tool_calls or {}
            elseif raw_result.result.data then
                -- Structured output response
                normalized.result = raw_result.result.data  -- Use 'result' not 'content'
            elseif raw_result.result.embeddings then
                -- Embeddings response
                normalized.result = raw_result.result.embeddings
            else
                normalized.result = raw_result.result
            end
        else
            normalized.result = raw_result.result
        end
    elseif raw_result.content then
        -- Direct content field (fallback)
        normalized.result = raw_result.content
        normalized.tool_calls = raw_result.tool_calls or {}
    elseif raw_result.data then
        -- Direct data field (fallback)
        normalized.result = raw_result.data
    elseif raw_result.embeddings then
        -- Direct embeddings field (fallback)
        normalized.result = raw_result.embeddings
    end

    return normalized
end

-- Get usage tracker contract (cache it when opened)
local function get_usage_tracker()
    if llm._usage_tracker then
        return llm._usage_tracker
    end

    -- Try to get usage tracker contract if available
    local tracker_contract, err = contract.get(USAGE_TRACKER_CONTRACT)
    if not err and tracker_contract then
        local instance, open_err = tracker_contract:open()
        if not open_err then
            llm._usage_tracker = instance
            return instance
        end
    end

    return nil -- No usage tracking available
end

-- Merge provider options into contract arguments
local function merge_provider_options(contract_args, provider_info)
    if provider_info and provider_info.options then
        for k, v in pairs(provider_info.options) do
            if k == "tools" or k == "tool_choice" or k == "stream" then
                contract_args[k] = v
            else
                contract_args.options[k] = v
            end
        end
    end
end

-- Merge user options into contract arguments
local function merge_user_options(contract_args, user_options, exclude_keys)
    exclude_keys = exclude_keys or {}

    for k, v in pairs(user_options) do
        local should_exclude = false
        for _, exclude_key in ipairs(exclude_keys) do
            if k == exclude_key then
                should_exclude = true
                break
            end
        end

        if not should_exclude then
            if k == "tools" or k == "tool_choice" or k == "stream" then
                contract_args[k] = v
            else
                contract_args.options[k] = v
            end
        end
    end
end

---------------------------
-- Constants (Backward Compatibility)
---------------------------

llm.CAPABILITY = {
    GENERATE = "generate",
    TOOL_USE = "tool_use",
    STRUCTURED_OUTPUT = "structured_output",
    EMBED = "embed",
    THINKING = "thinking",
    VISION = "vision",
    CACHING = "caching"
}

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

---------------------------
-- Public API Methods
---------------------------

function llm.generate(prompt_input, options)
    if not options or not options.model then
        return nil, "Model is required in options"
    end

    local model_card, provider_info

    local actor = security.actor()
    if actor then
        options.user = actor:id()
    end

    -- Check if provider_id is specified for direct provider call
    if options.provider_id then
        -- Direct provider call - skip model resolution
        provider_info = {
            id = options.provider_id
        }

        -- Open provider instance
        local providers_module = llm._providers or providers
        local provider_instance, err = providers_module.open(provider_info.id, {})
        if not provider_instance then
            return nil, "Failed to open provider: " .. (err or "unknown error")
        end

        -- Prepare messages
        local messages, err = prepare_messages(prompt_input)
        if not messages then
            return nil, err
        end

        -- Build standard contract arguments
        local contract_args = {
            messages = messages,
            model = options.model,
            options = {}
        }

        -- Copy user options to contract options (no provider options in direct mode)
        merge_user_options(contract_args, options, {"model", "provider_id"})

        -- Call provider contract directly with standard format
        local raw_result, err = provider_instance:generate(contract_args)
        if err then
            return nil, err
        end

        -- Normalize response
        local normalized, norm_err = normalize_response(raw_result)
        if norm_err then
            return nil, norm_err
        end
        if not normalized then
            return nil, "Failed to normalize provider response"
        end

        -- Track usage if available
        local usage_id, usage_err = llm.track_usage(normalized, options.model, options)
        if usage_id then
            normalized.usage_record = { usage_id = usage_id }
        end

        return normalized
    else
        -- Smart model resolution path
        local err
        model_card, err = resolve_model(options.model)
        if not model_card then
            return nil, err
        end

        -- Get first provider (highest priority)
        if not model_card.providers or #model_card.providers == 0 then
            return nil, "Model has no configured providers: " .. options.model
        end
        provider_info = model_card.providers[1]

        -- Open provider instance
        local providers_module = llm._providers or providers
        local provider_instance, err = providers_module.open(provider_info.id, provider_info.options or {})
        if not provider_instance then
            return nil, "Failed to open provider: " .. (err or "unknown error")
        end

        -- Prepare messages
        local messages, err = prepare_messages(prompt_input)
        if not messages then
            return nil, err
        end

        -- Build contract arguments
        local contract_args = {
            messages = messages,
            model = provider_info.provider_model,
            options = {}
        }

        -- Merge provider options first (from model YAML)
        merge_provider_options(contract_args, provider_info)

        -- Merge user options (can override provider defaults)
        merge_user_options(contract_args, options, {"model"})

        -- Call provider contract
        local raw_result, err = provider_instance:generate(contract_args)
        if err then
            return nil, err
        end

        -- Normalize response
        local normalized, norm_err = normalize_response(raw_result)
        if norm_err then
            return nil, norm_err
        end
        if not normalized then
            return nil, "Failed to normalize provider response"
        end

        -- Track usage
        local usage_id, usage_err = llm.track_usage(normalized, options.model, options)
        if usage_id then
            normalized.usage_record = { usage_id = usage_id }
        end

        return normalized
    end
end

function llm.structured_output(schema, prompt_input, options)
    if not options or not options.model then
        return nil, "Model is required in options"
    end

    if not schema then
        return nil, "Schema is required"
    end

    local model_card, provider_info

    local actor = security.actor()
    if actor then
        options.user = actor:id()
    end

    -- Check if provider_id is specified for direct provider call
    if options.provider_id then
        -- Direct provider call - skip model resolution
        provider_info = {
            id = options.provider_id
        }

        -- Open provider instance
        local providers_module = llm._providers or providers
        local provider_instance, err = providers_module.open(provider_info.id, {})
        if not provider_instance then
            return nil, "Failed to open provider: " .. (err or "unknown error")
        end

        -- Prepare messages
        local messages, err = prepare_messages(prompt_input)
        if not messages then
            return nil, err
        end

        -- Build standard contract arguments
        local contract_args = {
            messages = messages,
            model = options.model,
            schema = schema,
            options = {}
        }

        -- Copy user options to contract options (no provider options in direct mode)
        merge_user_options(contract_args, options, {"model", "provider_id", "schema"})

        -- Call provider contract directly with standard format
        local raw_result, err = provider_instance:structured_output(contract_args)
        if err then
            return nil, err
        end

        -- Normalize response
        local normalized, norm_err = normalize_response(raw_result)
        if norm_err then
            return nil, norm_err
        end
        if not normalized then
            return nil, "Failed to normalize provider response"
        end

        -- Track usage if available
        local usage_id, usage_err = llm.track_usage(normalized, options.model, options)
        if usage_id then
            normalized.usage_record = { usage_id = usage_id }
        end

        return normalized
    else
        -- Smart model resolution path
        local err
        model_card, err = resolve_model(options.model)
        if not model_card then
            return nil, err
        end

        -- Get first provider (highest priority)
        if not model_card.providers or #model_card.providers == 0 then
            return nil, "Model has no configured providers: " .. options.model
        end
        provider_info = model_card.providers[1]

        -- Open provider instance
        local providers_module = llm._providers or providers
        local provider_instance, err = providers_module.open(provider_info.id, provider_info.options or {})
        if not provider_instance then
            return nil, "Failed to open provider: " .. (err or "unknown error")
        end

        -- Prepare messages
        local messages, err = prepare_messages(prompt_input)
        if not messages then
            return nil, err
        end

        -- Build contract arguments
        local contract_args = {
            messages = messages,
            model = provider_info.provider_model,
            schema = schema,
            options = {}
        }

        -- Merge provider options first (from model YAML)
        merge_provider_options(contract_args, provider_info)

        -- Merge user options (can override provider defaults)
        merge_user_options(contract_args, options, {"model", "schema"})

        -- Call provider contract
        local raw_result, err = provider_instance:structured_output(contract_args)
        if err then
            return nil, err
        end

        -- Normalize response
        local normalized, norm_err = normalize_response(raw_result)
        if norm_err then
            return nil, norm_err
        end
        if not normalized then
            return nil, "Failed to normalize provider response"
        end

        -- Track usage
        local usage_id, usage_err = llm.track_usage(normalized, options.model, options)
        if usage_id then
            normalized.usage_record = { usage_id = usage_id }
        end

        return normalized
    end
end

function llm.embed(text, options)
    if not options or not options.model then
        return nil, "Model is required in options"
    end

    local model_card, provider_info

    local actor = security.actor()
    if actor then
        options.user = actor:id()
    end

    -- Check if provider_id is specified for direct provider call
    if options.provider_id then
        -- Direct provider call - skip model resolution
        provider_info = {
            id = options.provider_id
        }

        -- Open provider instance
        local providers_module = llm._providers or providers
        local provider_instance, err = providers_module.open(provider_info.id, {})
        if not provider_instance then
            return nil, "Failed to open provider: " .. (err or "unknown error")
        end

        -- Build standard contract arguments
        local contract_args = {
            input = text,
            model = options.model,
            options = {}
        }

        -- Copy user options to contract options (no provider options in direct mode)
        merge_user_options(contract_args, options, {"model", "provider_id"})

        -- Call provider contract directly with standard format
        local raw_result, err = provider_instance:embed(contract_args)
        if err then
            return nil, err
        end

        -- Normalize response
        local normalized, norm_err = normalize_response(raw_result)
        if norm_err then
            return nil, norm_err
        end
        if not normalized then
            return nil, "Failed to normalize provider response"
        end

        -- Track usage if available
        local usage_id, usage_err = llm.track_usage(normalized, options.model, options)
        if usage_id then
            normalized.usage_record = { usage_id = usage_id }
        end

        return normalized
    else
        -- Smart model resolution path
        local err
        model_card, err = resolve_model(options.model)
        if not model_card then
            return nil, err
        end

        -- Get first provider (highest priority)
        if not model_card.providers or #model_card.providers == 0 then
            return nil, "Model has no configured providers: " .. options.model
        end
        provider_info = model_card.providers[1]

        -- Open provider instance
        local providers_module = llm._providers or providers
        local provider_instance, err = providers_module.open(provider_info.id, provider_info.options or {})
        if not provider_instance then
            return nil, "Failed to open provider: " .. (err or "unknown error")
        end

        -- Build contract arguments
        local contract_args = {
            input = text,
            model = provider_info.provider_model,
            options = {}
        }

        -- Add dimensions from options or model card
        if options.dimensions then
            contract_args.options.dimensions = options.dimensions
        elseif model_card.dimensions then
            contract_args.options.dimensions = model_card.dimensions
        end

        -- Merge provider options first (from model YAML)
        merge_provider_options(contract_args, provider_info)

        -- Merge user options (can override provider defaults)
        merge_user_options(contract_args, options, {"model", "dimensions"})

        -- Call provider contract
        local raw_result, err = provider_instance:embed(contract_args)
        if err then
            return nil, err
        end

        -- Normalize response
        local normalized, norm_err = normalize_response(raw_result, options.model)
        if norm_err then
            return nil, norm_err
        end
        if not normalized then
            return nil, "Failed to normalize provider response"
        end

        -- Track usage
        local usage_id, usage_err = llm.track_usage(normalized, options.model, options)
        if usage_id then
            normalized.usage_record = { usage_id = usage_id }
        end

        return normalized
    end
end

function llm.available_models(capability)
    local models_module = llm._models or models
    local all_models, err = models_module.get_all()
    if not all_models then
        return nil, err
    end

    if not capability then
        return all_models
    end

    -- Filter by capability
    local filtered = {}
    for _, model in ipairs(all_models) do
        if model.capabilities then
            for _, cap in ipairs(model.capabilities) do
                if cap == capability then
                    table.insert(filtered, model)
                    break
                end
            end
        end
    end

    return filtered
end

function llm.get_classes()
    local models_module = llm._models or models
    return models_module.get_all_classes()
end

function llm.track_usage(response, model_id, options)
    local tracker = get_usage_tracker()
    if not tracker then
        -- No usage tracking available
        return nil, nil
    end

    options = options or {}

    -- Extract token information from response
    local prompt_tokens = 0
    local completion_tokens = 0
    local thinking_tokens = 0
    local cache_read_tokens = 0
    local cache_write_tokens = 0

    if response and response.tokens then
        prompt_tokens = response.tokens.prompt_tokens or 0
        completion_tokens = response.tokens.completion_tokens or 0
        thinking_tokens = response.tokens.thinking_tokens or 0
        cache_read_tokens = response.tokens.cache_read_input_tokens or response.tokens.cache_read_tokens or 0
        cache_write_tokens = response.tokens.cache_creation_input_tokens or response.tokens.cache_write_tokens or 0
    end

    -- Prepare tracking options
    local tracking_options = {}

    if options.timestamp then
        tracking_options.timestamp = options.timestamp
    end

    if options.metadata then
        tracking_options.metadata = options.metadata
    end

    -- Call usage tracker contract
    local usage_id, err = tracker:track_usage(
        model_id,
        prompt_tokens,
        completion_tokens,
        thinking_tokens,
        cache_read_tokens,
        cache_write_tokens,
        tracking_options
    )

    return usage_id, err
end

return llm