local bedrock_client = require("bedrock_client")
local output = require("output")
local embed_titan = require("embed_titan")
local embed_cohere = require("embed_cohere")

local embed_handler = {
    _client = bedrock_client,
    _titan = embed_titan,
    _cohere = embed_cohere
}

local function detect_model_family(model_id)
    if model_id:match("^amazon%.titan%-embed") or model_id:match("^amazon%.nova.*embed") then
        return "titan"
    elseif model_id:match("^cohere%.embed") then
        return "cohere"
    end
    return nil
end

local function embed_with_titan(client, model_id, input, options)
    local texts = type(input) == "table" and input or { input }
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
    local texts = type(input) == "table" and input or { input }
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

    local family = detect_model_family(contract_args.model)
    if not family then
        return {
            success = false,
            error = output.ERROR_TYPE.MODEL_ERROR,
            error_message = "Unsupported embedding model family: " .. contract_args.model,
            metadata = {}
        }
    end

    local options = contract_args.options or {}
    local result, err

    if family == "titan" then
        result, err = embed_with_titan(
            embed_handler._client, contract_args.model, contract_args.input, options)
    elseif family == "cohere" then
        result, err = embed_with_cohere(
            embed_handler._client, contract_args.model, contract_args.input, options)
    end

    if err then
        local error_type = output.ERROR_TYPE.SERVER_ERROR
        if err.status_code then
            if err.status_code == 401 or err.status_code == 403 then
                error_type = output.ERROR_TYPE.AUTHENTICATION
            elseif err.status_code == 404 then
                error_type = output.ERROR_TYPE.MODEL_ERROR
            elseif err.status_code == 429 then
                error_type = output.ERROR_TYPE.RATE_LIMIT
            elseif err.status_code == 400 then
                error_type = output.ERROR_TYPE.INVALID_REQUEST
            end
        end

        return {
            success = false,
            error = error_type,
            error_message = err.message or "Embedding request failed",
            metadata = err.metadata or {}
        }
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
