local embed_titan = {}

-- Build InvokeModel payload for Amazon Titan Embed Text models
-- Titan accepts a single text per request, returns a single embedding vector
function embed_titan.build_payload(text, options)
    local opts = options or {}
    local payload: {[string]: any} = {
        inputText = text
    }

    if opts.dimensions then
        payload.dimensions = opts.dimensions
    end

    if opts.normalize ~= nil then
        payload.normalize = opts.normalize
    end

    return payload
end

-- Parse InvokeModel response from Titan Embed
-- Returns: embedding vector, token count
function embed_titan.parse_response(response)
    if not response or not response.embedding then
        return nil, 0, "Missing embedding in Titan response"
    end

    return response.embedding, response.inputTextTokenCount or 0, nil
end

return embed_titan
