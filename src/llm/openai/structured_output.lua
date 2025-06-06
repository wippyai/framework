local openai_client = require("openai_client")
local output = require("output")
local json = require("json")
local hash = require("hash")

-- Create module table for exports
local structured_output = {}

-- Generate a unique name for a schema based on its structure
function structured_output.generate_schema_name(schema)
    -- Serialize the schema to a string
    local schema_str = json.encode(schema)

    -- Calculate SHA-256 hash of the schema
    local digest, err = hash.sha256(schema_str)
    if err then
        -- Fallback to a simple hash if sha256 fails
        return "schema_" .. os.time()
    end

    -- Use first 16 characters of hash as the schema name
    -- This keeps the name reasonably short while still being unique
    return "schema_" .. string.sub(digest, 1, 16)
end

-- Validate schema meets OpenAI requirements for Structured Outputs
function structured_output.validate_schema(schema)
    local errors = {}

    -- Check if root is an object
    if schema.type ~= "object" then
        table.insert(errors, "Root schema must be an object type")
    end

    -- Check if additionalProperties is false
    if schema.additionalProperties ~= false then
        table.insert(errors, "Root schema must have additionalProperties: false")
    end

    -- Check if all properties are marked as required
    if schema.properties then
        local properties = {}
        for prop_name, _ in pairs(schema.properties) do
            table.insert(properties, prop_name)
        end

        -- Check if required array exists and contains all properties
        if not schema.required then
            table.insert(errors, "Schema must have a required array listing all properties")
        else
            -- Check if all properties are in required array
            local missing_required = {}
            for _, prop_name in ipairs(properties) do
                local found = false
                for _, req_prop in ipairs(schema.required) do
                    if req_prop == prop_name then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(missing_required, prop_name)
                end
            end

            if #missing_required > 0 then
                table.insert(errors,
                    "The following properties must be marked as required: " .. table.concat(missing_required, ", "))
            end
        end
    end

    -- More detailed validation could be added here:
    -- - Count total properties (max 100)
    -- - Check nesting depth (max 5)
    -- - Count enum values (max 500)
    -- - Check string lengths
    -- - Validate supported types only

    return #errors == 0, errors
end

-- Main handler for OpenAI Structured Output
function structured_output.handler(args)
    -- Validate required arguments
    if not args.model then
        return {
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Model is required"
        }
    end

    -- Format messages from various input formats
    local messages = args.messages or {}

    if #messages == 0 then
        return {
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "No messages provided"
        }
    end

    -- Check for schema
    if not args.schema then
        return {
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Schema is required for structured output"
        }
    end

    -- Validate the schema
    local schema_valid, schema_errors = structured_output.validate_schema(args.schema)
    if not schema_valid then
        return {
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Invalid schema: " .. table.concat(schema_errors, "; ")
        }
    end

    -- Configure options objects for easier management
    local options = args.options or {}

    -- Check if this is an o* model (OpenAI o-series models)
    local is_o_model = args.model:match("^o%d") ~= nil

    -- Generate a schema name if not provided
    local schema_name = args.schema_name
    if not schema_name then
        schema_name = structured_output.generate_schema_name(args.schema)
    end

    -- Configure request payload
    local payload = {
        model = args.model,
        messages = messages,
        top_p = options.top_p,
        top_k = options.top_k,
        presence_penalty = options.presence_penalty,
        frequency_penalty = options.frequency_penalty,
        logit_bias = options.logit_bias,
        user = options.user,
        seed = options.seed,
        response_format = {
            type = "json_schema",
            json_schema = {
                name = schema_name,
                schema = args.schema,
                strict = true
            }
        }
    }

    -- Handle max tokens parameter differently based on model type
    if options.max_tokens then
        if is_o_model then
            payload.max_completion_tokens = options.max_tokens
            -- Remove max_tokens for o* models as it's not supported
            payload.max_tokens = nil
        else
            payload.max_tokens = options.max_tokens
        end
    end

    -- Always apply max_completion_tokens if explicitly provided
    if options.max_completion_tokens then
        payload.max_completion_tokens = options.max_completion_tokens
        -- For consistency, remove max_tokens if max_completion_tokens is specified
        payload.max_tokens = nil
    end

    -- Add temperature based on model type
    if options.temperature ~= nil then
        payload.temperature = options.temperature
    end

    -- Add stop sequences if provided
    if options.stop_sequences then
        payload.stop = options.stop_sequences
    elseif options.stop then
        payload.stop = options.stop
    end

    -- Add thinking effort mapping - using the utility in openai client
    if args.thinking_effort and args.thinking_effort > 0 then
        payload.reasoning_effort = openai_client.map_thinking_effort(args.thinking_effort)
    end

    -- Remove temperature for o* models
    if is_o_model then
        payload.temperature = nil
    end

    -- Make the request
    local request_options = {
        api_key = args.api_key,
        organization = args.organization,
        timeout = args.timeout or 120,
        base_url = args.endpoint
    }

    -- Perform the request to OpenAI
    local response, err = openai_client.request(
        openai_client.DEFAULT_CHAT_ENDPOINT,
        payload,
        request_options
    )

    -- Handle request errors
    if err then
        return openai_client.map_error(err)
    end

    -- Check response validity
    if not response or not response.choices or #response.choices == 0 then
        return {
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Invalid response structure from OpenAI"
        }
    end

    -- Extract the first choice
    local first_choice = response.choices[1]
    if not first_choice or not first_choice.message then
        return {
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Invalid choice structure in OpenAI response"
        }
    end

    -- Extract token usage information
    local tokens = nil
    if response.usage then
        local extracted_usage = openai_client.extract_usage(response)
        if extracted_usage then
            tokens = output.usage(
                extracted_usage.prompt_tokens,
                extracted_usage.completion_tokens,
                extracted_usage.thinking_tokens,
                extracted_usage.cache_write_tokens,
                extracted_usage.cache_read_tokens
            )
        end
    end

    -- Handle response
    local result = nil

    -- Check for refusal
    if first_choice.message.refusal then
        return {
            result = nil,
            refusal = first_choice.message.refusal,
            tokens = tokens,
            metadata = response.metadata,
            finish_reason = openai_client.FINISH_REASON_MAP[first_choice.finish_reason] or first_choice.finish_reason,
            provider = "openai",
            model = args.model
        }
    elseif first_choice.message.content then
        -- Decode JSON content
        local parsed_content, decode_err = json.decode(first_choice.message.content)

        -- If decoding fails, return the raw content
        if decode_err then
            result = first_choice.message.content
        else
            result = parsed_content
        end
    else
        return {
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "No content in OpenAI response"
        }
    end

    -- Return successful response with standardized finish reason
    return {
        result = result,
        tokens = tokens,
        metadata = response.metadata,
        finish_reason = openai_client.FINISH_REASON_MAP[first_choice.finish_reason] or first_choice.finish_reason,
        provider = "openai",
        model = args.model
    }
end

-- Return the module
return structured_output
