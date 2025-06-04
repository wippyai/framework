local openai_client = require("openai_client")
local output = require("output")

-- OpenAI Embeddings Handler
local function handler(args)
    -- Validate required arguments
    if not args.model then
        return {
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Model is required"
        }
    end

    if not args.input then
        return {
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Input text is required"
        }
    end

    -- Configure request payload
    local payload = {
        model = args.model,
        input = args.input,
        encoding_format = "float", -- Default to float encoding
        dimensions = args.dimensions
    }

    -- Add user if provided
    if args.options and args.options.user then
        payload.user = args.options.user
    end

    -- Configure request options
    local request_options = {
        api_key = args.api_key,
        organization = args.organization,
        timeout = args.timeout or 60,
        base_url = args.endpoint
    }

    -- Make the request to the OpenAI API
    local response, err = openai_client.request(
        openai_client.DEFAULT_EMBEDDING_ENDPOINT,
        payload,
        request_options
    )

    -- Handle errors
    if err then
        local mapped_error = openai_client.map_error(err)
        return mapped_error
    end

    -- Validate response structure
    if not response or not response.data or #response.data == 0 then
        return {
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Invalid or empty response from OpenAI embeddings API"
        }
    end

    -- Format successful response according to spec
    local result = {}

    -- For single input: result is a flat array of floats
    -- For multiple inputs: result is an array of arrays
    if #response.data == 1 then
        -- Single input case - flat array
        result = response.data[1].embedding
    else
        -- Multiple inputs case - array of arrays
        for _, item in ipairs(response.data) do
            table.insert(result, item.embedding)
        end
    end

    -- Extract token usage information
    local tokens = nil
    if response.usage then
        tokens = {
            prompt_tokens = response.usage.prompt_tokens or 0,
            total_tokens = response.usage.total_tokens or response.usage.prompt_tokens or 0
        }
    end

    -- Return according to spec format
    return {
        result = result,
        tokens = tokens,
        metadata = response.metadata,
        provider = "openai",
        model = args.model
    }
end

return { handler = handler }
