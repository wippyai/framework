local openai_client = require("openai_client")
local openai_mapper = require("openai_mapper")
local output = require("output")

local embeddings_handler = {
    _client = openai_client,
    _mapper = openai_mapper
}

function embeddings_handler.handler(contract_args)
    local err = output.errors.embed(contract_args)
        :classifier(embeddings_handler._mapper.classify_error)

    if not contract_args.model then
        return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message("Model is required"):build()
    end

    if not contract_args.input then
        return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message("Input is required"):build()
    end

    local openai_payload = {
        model = contract_args.model,
        input = contract_args.input,
        encoding_format = "float"
    }

    if contract_args.options and contract_args.options.dimensions then
        openai_payload.dimensions = contract_args.options.dimensions
    end

    local opts = contract_args.options :: any
    if opts and opts.user then
        openai_payload.user = opts.user
    end

    local openai_response, req_err = embeddings_handler._client.request("/embeddings", openai_payload, {
        timeout = contract_args.timeout,
        retry = contract_args.retry,
    })

    if req_err then
        return nil, err:from(req_err):build()
    end

    if not openai_response or not openai_response.data or #openai_response.data == 0 then
        return nil, err
            :kind(output.ERROR_TYPE.SERVER_ERROR)
            :message("Invalid or empty response from OpenAI embeddings API")
            :details(openai_response and openai_response.metadata or nil)
            :build()
    end

    local embeddings = table.create(#openai_response.data, 0)
    for i, item in ipairs(openai_response.data) do
        embeddings[i] = item.embedding
    end

    local contract_response = {
        success = true,
        result = {
            embeddings = embeddings
        },
        metadata = openai_response.metadata or {}
    }

    if openai_response.usage then
        contract_response.tokens = {
            prompt_tokens = openai_response.usage.prompt_tokens or 0,
            total_tokens = openai_response.usage.total_tokens or openai_response.usage.prompt_tokens or 0
        }
    end

    return contract_response
end

return embeddings_handler
