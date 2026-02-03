local llm = require("llm")
local embedding_repo = require("embedding_repo")

local MAX_TOKENS_PER_REQUEST = 8000 -- 8k token limit
local EMBEDDING_MODEL = "text-embedding-3-small"
local EMBEDDING_DIMENSIONS = 512
local DEFAULT_SEARCH_LIMIT = 10

local embeddings = {}

-- Helper function to estimate tokens in text
local function estimate_tokens(text)
    -- Rough estimation: 1 token ≈ 4 characters for English text
    return math.ceil(#text / 4)
end

-- Helper function to estimate batch tokens
local function estimate_batch_tokens(texts)
    local total_tokens = 0
    for _, text in ipairs(texts) do
        total_tokens = total_tokens + estimate_tokens(text)
    end
    return total_tokens
end

-- Helper function to split batch based on token limits
local function split_batch_by_tokens(batch, max_tokens)
    local batches = {}
    local current_batch = {}
    local current_tokens = 0

    for i, item in ipairs(batch) do
        local item_tokens = estimate_tokens(item.content)

        -- If adding this item would exceed the token limit, create a new batch
        if current_tokens + item_tokens > max_tokens and #current_batch > 0 then
            table.insert(batches, current_batch)
            current_batch = {}
            current_tokens = 0
        end

        -- Add the item to the current batch
        table.insert(current_batch, item)
        current_tokens = current_tokens + item_tokens
    end

    -- Add the last batch if it's not empty
    if #current_batch > 0 then
        table.insert(batches, current_batch)
    end

    return batches
end

-- Generate embedding for a single text
local function generate_embedding(text)
    if not text or text == "" then
        return nil, "Empty text cannot be embedded"
    end

    -- Use text-embedding model for embeddings
    local response = llm.embed(text, {
        model = EMBEDDING_MODEL,
        dimensions = EMBEDDING_DIMENSIONS
    })

    if not response or response.error then
        return nil, "Failed to generate embedding: " .. (response and response.error_message or "Unknown error")
    end

    return response.result
end

-- Generate embeddings for multiple texts
local function generate_batch_embeddings(texts)
    if not texts or #texts == 0 then
        return nil, "No texts provided for batch embedding"
    end

    -- Check for empty texts
    for i, text in ipairs(texts) do
        if not text or text == "" then
            return nil, "Text at index " .. i .. " is empty and cannot be embedded"
        end
    end

    -- Estimate total tokens
    local total_tokens = estimate_batch_tokens(texts)

    -- If exceeding token limit, return error
    if total_tokens > MAX_TOKENS_PER_REQUEST then
        return nil, "Total tokens exceed maximum of " .. MAX_TOKENS_PER_REQUEST
    end

    -- Use text-embedding model for embeddings in batch
    local response = llm.embed(texts, {
        model = EMBEDDING_MODEL,
        dimensions = EMBEDDING_DIMENSIONS
    })

    if not response or response.error then
        return nil, "Failed to generate batch embeddings: " .. (response and response.error_message or "Unknown error")
    end

    return response.result
end

-- Add a new embedding
function embeddings.add(content, content_type, origin_id, context_id, meta)
    if not content or content == "" then
        return nil, "Content is required"
    end

    if not content_type or content_type == "" then
        return nil, "Content type is required"
    end

    if not origin_id or origin_id == "" then
        return nil, "Origin ID is required"
    end

    -- Generate embedding
    local embedding, err = generate_embedding(content)
    if err then
        return nil, err
    end

    -- Persist to repository
    local result, err = embedding_repo.add(content, content_type, origin_id, context_id, meta, embedding)
    if err then
        return nil, err
    end

    return result
end

-- Add multiple embeddings
function embeddings.add_batch(batch)
    if not batch or #batch == 0 then
        return nil, "Batch is empty"
    end

    -- Validate batch items
    local texts = {}
    local valid_items = {}

    for i, item in ipairs(batch) do
        -- Validate item fields
        if not item.content or item.content == "" then
            return nil, "Item " .. i .. ": Content is required"
        end

        if not item.content_type or item.content_type == "" then
            return nil, "Item " .. i .. ": Content type is required"
        end

        if not item.origin_id or item.origin_id == "" then
            return nil, "Item " .. i .. ": Origin ID is required"
        end

        -- Add valid content to texts array for batch embedding
        table.insert(texts, item.content)
        table.insert(valid_items, item)
    end

    -- Split batch if needed to respect token limits
    local estimated_tokens = estimate_batch_tokens(texts)

    -- If batch can be processed in one go
    if estimated_tokens <= MAX_TOKENS_PER_REQUEST then
        -- Generate embeddings in batch
        local embeddings_result, err = generate_batch_embeddings(texts)
        if err then
            return nil, err
        end

        -- Prepare batch for repository with generated embeddings
        local repo_batch = {}
        for i, item in ipairs(valid_items) do
            table.insert(repo_batch, {
                content = item.content,
                content_type = item.content_type,
                origin_id = item.origin_id,
                context_id = item.context_id,
                meta = item.meta,
                embedding = type(embeddings_result[i]) == "table" and embeddings_result[i] or { embeddings_result[i] }
            })
        end

        -- Store in repository
        return embedding_repo.add_batch(repo_batch)
    else
        -- Split into smaller batches
        local batches = split_batch_by_tokens(valid_items, MAX_TOKENS_PER_REQUEST)

        -- Process each batch
        local results = {
            count = 0,
            items = {}
        }

        for _, sub_batch in ipairs(batches) do
            -- Extract texts for this sub-batch
            local sub_texts = {}
            for _, item in ipairs(sub_batch) do
                table.insert(sub_texts, item.content)
            end

            -- Generate embeddings for this sub-batch
            local sub_embeddings, err = generate_batch_embeddings(sub_texts)
            if err then
                return nil, err
            end

            -- Prepare sub-batch for repository
            local repo_sub_batch = {}
            for i, item in ipairs(sub_batch) do
                table.insert(repo_sub_batch, {
                    content = item.content,
                    content_type = item.content_type,
                    origin_id = item.origin_id,
                    context_id = item.context_id,
                    meta = item.meta,
                    embedding = sub_embeddings[i]
                })
            end

            -- Store sub-batch
            local sub_result, err = embedding_repo.add_batch(repo_sub_batch)
            if err then
                return nil, err
            end

            -- Accumulate results
            results.count = results.count + sub_result.count
            for _, item in ipairs(sub_result.items) do
                table.insert(results.items, item)
            end
        end

        return results
    end
end

-- Search for similar embeddings with filtering
function embeddings.search(query_text, options)
    if not query_text or query_text == "" then
        return nil, "Query text is required"
    end

    options = options or {}

    -- Generate embedding for query
    local embedding, err = generate_embedding(query_text)
    if err then
        return nil, err
    end

    -- Call repository search with the generated embedding
    return embedding_repo.search_by_embedding(embedding[1], {
        content_type = options.content_type,
        origin_id = options.origin_id,
        context_id = options.context_id,
        limit = options.limit or DEFAULT_SEARCH_LIMIT
    })
end

-- Find content by type across multiple documents
function embeddings.find_by_type(query, content_type, options)
    if not query or query == "" then
        return nil, "Query is required"
    end

    if not content_type or content_type == "" then
        return nil, "Content type is required"
    end

    options = options or {}

    -- Search with the specified content type
    return embeddings.search(query, {
        content_type = content_type,
        limit = options.limit or 10
    })
end

-- Find relevant content by origin ID
function embeddings.find_by_origin(query, origin_id, options)
    if not query or query == "" then
        return nil, "Query is required"
    end

    if not origin_id or origin_id == "" then
        return nil, "Origin ID is required"
    end

    options = options or {}

    -- Search within the specified origin
    return embeddings.search(query, {
        origin_id = origin_id,
        content_type = options.content_type,
        context_id = options.context_id,
        limit = options.limit or 5
    })
end

return embeddings