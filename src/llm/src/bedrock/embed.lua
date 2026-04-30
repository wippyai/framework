local bedrock_client = require("bedrock_client")
local mapper = require("mapper")
local output = require("output")
local embed_titan = require("embed_titan")
local embed_cohere = require("embed_cohere")

local embed_handler = {
    _client = bedrock_client,
    _titan = embed_titan,
    _cohere = embed_cohere
}

local function detect_model_family(model_id)
    -- Cross-region inference profiles have a prefix like "us.", "global.", "eu."
    -- Match the family anywhere in the ID after optional prefix
    if model_id:match("amazon%.titan%-embed") or model_id:match("amazon%.nova.*embed") then
        return "titan"
    elseif model_id:match("cohere%.embed") then
        return "cohere"
    end
    return nil
end

local function embed_with_titan(client, model_id, input, options)
    local texts
    if type(input) == "table" then texts = input else texts = { input } end
    local all_embeddings = {}
    local total_tokens = 0

    for _, text in ipairs(texts) do
        local payload = embed_titan.build_payload(text, options)
        local response, err = client.invoke(model_id, payload, { timeout = options and options.timeout })

        if err then
            return nil, err
        end

        local embedding, token_count, parse_err = embed_titan.parse_response(response)
        if parse_err then
            return nil, { status_code = 500, message = parse_err }
        end

        table.insert(all_embeddings, embedding)
        total_tokens = total_tokens + token_count
    end

    return {
        embeddings = all_embeddings,
        tokens = { prompt_tokens = total_tokens, total_tokens = total_tokens }
    }
end

local function embed_with_cohere(client, model_id, input, options)
    local texts
    if type(input) == "table" then texts = input else texts = { input } end
    local payload = embed_cohere.build_payload(texts, options)
    local response, err = client.invoke(model_id, payload, { timeout = options and options.timeout })

    if err then
        return nil, err
    end

    local embeddings, token_count, parse_err = embed_cohere.parse_response(response)
    if parse_err then
        return nil, { status_code = 500, message = parse_err }
    end

    return {
        embeddings = embeddings,
        tokens = { prompt_tokens = token_count, total_tokens = token_count }
    }
end

function embed_handler.handler(contract_args)
    local err_b = output.errors.embed(contract_args):classifier(mapper.classify_error)

    if not contract_args.model then
        return nil, err_b:kind(output.ERROR_TYPE.INVALID_REQUEST):message("Model is required"):build()
    end

    if not contract_args.input then
        return nil, err_b:kind(output.ERROR_TYPE.INVALID_REQUEST):message("Input is required"):build()
    end

    local family = detect_model_family(contract_args.model)
    if not family then
        return nil, err_b
            :kind(output.ERROR_TYPE.MODEL_ERROR)
            :message("Unsupported embedding model family: " .. contract_args.model)
            :build()
    end

    local model_id = contract_args.model
    local input = contract_args.input
    local options = contract_args.options or {}
    local result, err

    if family == "titan" then
        result, err = embed_with_titan(embed_handler._client, model_id, input, options)
    elseif family == "cohere" then
        result, err = embed_with_cohere(embed_handler._client, model_id, input, options)
    end

    if err then
        return nil, err_b
            :from(err)
            :details({ family = family })
            :build()
    end

    return {
        success = true,
        result = {
            embeddings = result.embeddings
        },
        tokens = result.tokens,
        metadata = {}
    }
end

return embed_handler
