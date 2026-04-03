local embed_cohere = {}

-- Build InvokeModel payload for Cohere Embed models
-- Cohere supports batch (up to 96 texts) and requires input_type
function embed_cohere.build_payload(texts, options)
    local opts = options or {}
    local payload: {[string]: any} = {
        texts = texts,
        input_type = opts.input_type or "search_document",
        embedding_types = { "float" }
    }

    if opts.dimensions then
        payload.output_dimension = opts.dimensions
    end

    if opts.truncate then
        payload.truncate = opts.truncate
    end

    return payload
end

-- Parse InvokeModel response from Cohere Embed
-- Returns: array of embedding vectors, total token count (0 since Cohere doesn't report tokens)
function embed_cohere.parse_response(response)
    if not response then
        return nil, 0, "Empty Cohere response"
    end

    local embeddings = nil

    -- Single embedding type: embeddings is array of arrays
    -- Multiple types: embeddings is {float: [[...]], int8: [[...]]}
    if response.response_type == "embeddings_by_type" then
        if type(response.embeddings) == "table" and response.embeddings.float then
            embeddings = response.embeddings.float
        end
    else
        -- Default: embeddings_floats or direct array
        if type(response.embeddings) == "table" then
            embeddings = response.embeddings
        end
    end

    if not embeddings then
        return nil, 0, "Missing embeddings in Cohere response"
    end

    return embeddings, 0, nil
end

return embed_cohere
