local openai_client = require("openai_client")
local openai_mapper = require("openai_mapper")
local output = require("output")

local embeddings_handler = {
    _client = openai_client,
    _mapper = openai_mapper
}

---@param contract_args table Contract arguments for embeddings
---@return table Contract-compliant response
function embeddings_handler.handler(contract_args)
    -- Validate required arguments
    if not contract_args.model then
        return {
            success = false,
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Model is required",
            metadata = {}
        }
    end

    if not contract_args.input then
        return {
            success = false,
            error = output.ERROR_TYPE.INVALID_REQUEST,
            error_message = "Input is required",
            metadata = {}
        }
    end

    -- Build OpenAI embeddings request payload
    local openai_payload = {
        model = contract_args.model,
        input = contract_args.input,
        encoding_format = "float"
    }

    -- Add dimensions if specified
    if contract_args.options and contract_args.options.dimensions then
        openai_payload.dimensions = contract_args.options.dimensions
    end

    -- Add user if specified
    if contract_args.options and contract_args.options.user then
        openai_payload.user = contract_args.options.user
    end

    -- Make API request using our client
    local openai_response, err = embeddings_handler._client.request("/embeddings", openai_payload, {
        timeout = contract_args.timeout
    })

    if err then
        return embeddings_handler._mapper.map_error_response(err)
    end

    -- Validate response structure
    if not openai_response or not openai_response.data or #openai_response.data == 0 then
        return {
            success = false,
            error = output.ERROR_TYPE.SERVER_ERROR,
            error_message = "Invalid or empty response from OpenAI embeddings API",
            metadata = openai_response and openai_response.metadata or {}
        }
    end

    -- Extract embeddings from response - always return array of arrays per contract
    local embeddings = table.create(#openai_response.data, 0)
    for i, item in ipairs(openai_response.data) do
        embeddings[i] = item.embedding
    end

    -- Build contract-compliant success response
    local contract_response = {
        success = true,
        result = {
            embeddings = embeddings
        },
        metadata = openai_response.metadata or {}
    }

    -- Enhanced token usage mapping
    if openai_response.usage then
        contract_response.tokens = {
            prompt_tokens = openai_response.usage.prompt_tokens or 0,
            total_tokens = openai_response.usage.total_tokens or openai_response.usage.prompt_tokens or 0
        }
    end

    return contract_response
end

return embeddings_handler
