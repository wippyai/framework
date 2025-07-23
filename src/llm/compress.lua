local text = require("text")
local models = require("models")
local llm = require("llm")

-- Compression library
local compress = {}

-- Allow for dependency injection for testing
compress._models = nil
compress._llm = nil
compress._text = nil

-- Get dependencies - use injected or require them
local function get_models()
    return compress._models or models
end

local function get_llm()
    return compress._llm or llm
end

local function get_text()
    return compress._text or text
end

---------------------------
-- Constants
---------------------------

-- Default options
local DEFAULT_OPTIONS = {
    temperature = 0.2,          -- Focused but not rigid
    chunk_overlap = 200,        -- Overlap for map-reduce
    safety_margin = 0.1,        -- 10% safety margin for context
    max_attempts = 2            -- Max refinement attempts
}

---------------------------
-- Utility Functions
---------------------------

-- Estimate character count from token count (rough approximation)
local function tokens_to_chars(tokens)
    return math.floor(tokens * 4)  -- Roughly 1 token = 4 characters
end

-- Estimate token count from character count (rough approximation)
local function chars_to_tokens(chars)
    return math.floor(chars / 4)  -- Roughly 4 characters = 1 token
end

-- Get model context information
local function get_model_info(model_name)
    local models_module = get_models()
    local model_card, err = models_module.get_by_name(model_name)
    if not model_card then
        return nil, "Model not found: " .. (err or "unknown error")
    end

    -- Calculate usable context (leaving room for prompt + response)
    local max_tokens = model_card.max_tokens or 8000
    local output_tokens = model_card.output_tokens or 1000
    local usable_tokens = max_tokens - output_tokens - 500  -- 500 token buffer for prompt
    local usable_chars = tokens_to_chars(usable_tokens)

    return {
        model_card = model_card,
        max_tokens = max_tokens,
        output_tokens = output_tokens,
        usable_chars = usable_chars,
        usable_tokens = usable_tokens
    }, nil
end

-- Validate target size
local function validate_target_size(target_chars, model_info)
    if not target_chars or target_chars <= 0 then
        return nil, "Target size must be a positive number"
    end

    local max_reasonable = math.floor(model_info.usable_chars * 0.8)  -- 80% of usable context
    if target_chars > max_reasonable then
        return nil, string.format(
            "Target size %d is too large for model (max reasonable: %d characters)",
            target_chars, max_reasonable
        )
    end

    return true, nil
end

---------------------------
-- Core Compression Functions
---------------------------

-- Direct compression for content that fits in model context
local function compress_direct(content, target_chars, model_name, options)
    local llm_module = get_llm()

    -- If content is already smaller than target, return as-is
    if #content <= target_chars then
        return content, nil
    end

    local prompt = string.format([[You are a professional text summarizer. Create a comprehensive summary of the provided content.

TARGET LENGTH: Exactly %d characters

INSTRUCTIONS:
- Summarize the content below in exactly %d characters
- Capture all key information, main points, and important details
- Maintain logical flow and professional tone
- Include numbers, conclusions, and critical facts
- Do NOT ask for content or return error messages
- Do NOT say "you haven't provided" or similar phrases
- ONLY return the summary text, nothing else

CONTENT TO SUMMARIZE:
%s

SUMMARY:]], target_chars, target_chars, content)

    local response, err = llm_module.generate(prompt, {
        model = model_name,
        temperature = options.temperature or DEFAULT_OPTIONS.temperature,
        max_tokens = chars_to_tokens(target_chars) + 200  -- Larger buffer for safety
    })

    if err then
        return nil, "Direct compression failed: " .. err
    end

    local result = response.result
    if not result or result == "" then
        return nil, "Model returned empty response"
    end

    -- Check for error responses from model
    local lower_result = result:lower()
    if lower_result:find("haven't provided") or
       lower_result:find("please share") or
       lower_result:find("could you please") or
       lower_result:find("source text") then
        return nil, "Model returned error message instead of summary"
    end

    return result, nil
end

-- Map-reduce compression for large content
local function compress_map_reduce(content, target_chars, model_name, model_info, options)
    local text_module = get_text()
    local llm_module = get_llm()

    -- Step 1: Split content into manageable chunks
    local chunk_size = math.floor(model_info.usable_chars * 0.6)  -- 60% of usable context
    local splitter, err = text_module.splitter.recursive({
        chunk_size = chunk_size,
        chunk_overlap = options.chunk_overlap or DEFAULT_OPTIONS.chunk_overlap
    })

    if err then
        return nil, "Failed to create text splitter: " .. err
    end

    local chunks, err = splitter:split_text(content)
    if err then
        return nil, "Failed to split content: " .. err
    end

    if #chunks == 0 then
        return nil, "No chunks created from content"
    end

    -- Step 2: Compress each chunk
    local chunk_summaries = {}
    local chars_per_chunk = math.floor(target_chars / #chunks)

    -- Ensure each chunk gets at least some reasonable space
    if chars_per_chunk < 50 then
        chars_per_chunk = 50
    end

    for i, chunk in ipairs(chunks) do
        local chunk_prompt = string.format([[Summarize this section in approximately %d characters, preserving all important information.

Do NOT ask for content or return error messages. ONLY return the summary.

Section content:
%s

Summary:]], chars_per_chunk, chunk)

        local response, err = llm_module.generate(chunk_prompt, {
            model = model_name,
            temperature = options.temperature or DEFAULT_OPTIONS.temperature
        })

        if err then
            return nil, string.format("Failed to compress chunk %d: %s", i, err)
        end

        if not response.result or response.result == "" then
            return nil, string.format("Empty response for chunk %d", i)
        end

        table.insert(chunk_summaries, response.result)
    end

    -- Step 3: Final synthesis
    local combined_summaries = table.concat(chunk_summaries, "\n\n")

    local synthesis_prompt = string.format([[Create a final comprehensive summary from these section summaries.

TARGET LENGTH: Exactly %d characters

INSTRUCTIONS:
- Synthesize into one cohesive summary of exactly %d characters
- Remove redundancy between sections
- Maintain all key information
- Write in clear, flowing prose
- Do NOT ask for content or return error messages
- ONLY return the final summary

Section summaries:
%s

FINAL SUMMARY:]], target_chars, target_chars, combined_summaries)

    local final_response, err = llm_module.generate(synthesis_prompt, {
        model = model_name,
        temperature = 0.1,  -- Very focused for synthesis
        max_tokens = chars_to_tokens(target_chars) + 200
    })

    if err then
        return nil, "Failed to synthesize final summary: " .. err
    end

    if not final_response.result or final_response.result == "" then
        return nil, "Empty response from synthesis step"
    end

    return final_response.result, nil
end

-- Refine result length if needed
local function refine_length(result, target_chars, model_name, options, attempts)
    local llm_module = get_llm()

    attempts = attempts or 1
    local max_attempts = options.max_attempts or DEFAULT_OPTIONS.max_attempts

    if attempts > max_attempts then
        return result, nil  -- Give up after max attempts
    end

    local actual_chars = #result
    local tolerance = math.max(10, math.floor(target_chars * 0.05))  -- 5% tolerance, minimum 10 chars

    if math.abs(actual_chars - target_chars) <= tolerance then
        return result, nil  -- Close enough
    end

    -- Need refinement
    local adjustment_type = actual_chars > target_chars and "shorten" or "expand"
    local difference = math.abs(actual_chars - target_chars)

    local refinement_prompt = string.format([[Adjust this text to be exactly %d characters while maintaining all key information.

CURRENT TEXT (%d characters):
%s

TASK: %s the text by %d characters to reach exactly %d characters.
- Maintain all critical information and natural flow
- Do NOT ask questions or return error messages
- ONLY return the adjusted text

ADJUSTED TEXT:]],
        target_chars, actual_chars, result, adjustment_type, difference, target_chars)

    local refined_response, err = llm_module.generate(refinement_prompt, {
        model = model_name,
        temperature = 0.1
    })

    if err then
        return result, nil  -- Return original if refinement fails
    end

    if not refined_response.result or refined_response.result == "" then
        return result, nil  -- Return original if empty response
    end

    -- Check for error responses
    local lower_refined = refined_response.result:lower()
    if lower_refined:find("haven't provided") or
       lower_refined:find("please share") or
       lower_refined:find("could you please") then
        return result, nil  -- Return original if model returned error
    end

    -- Recursively refine if still not close enough
    return refine_length(refined_response.result, target_chars, model_name, options, attempts + 1)
end

---------------------------
-- Public API
---------------------------

-- Main compression function
function compress.to_size(model_name, content, target_chars, options)
    options = options or {}

    -- Validate inputs
    if not model_name or model_name == "" then
        return nil, "Model name is required"
    end

    if not content or content == "" then
        return nil, "Content is required"
    end

    if not target_chars or type(target_chars) ~= "number" or target_chars <= 0 then
        return nil, "Target size must be a positive number"
    end

    -- If content is already smaller than or equal to target, return as-is
    if #content <= target_chars then
        return content, nil
    end

    -- Get model information
    local model_info, err = get_model_info(model_name)
    if err then
        return nil, err
    end

    -- Validate target size is reasonable for this model
    local valid, err = validate_target_size(target_chars, model_info)
    if err then
        return nil, err
    end

    -- Choose compression strategy
    local result, err
    if #content <= model_info.usable_chars then
        -- Direct compression - content fits in model context
        result, err = compress_direct(content, target_chars, model_name, options)
    else
        -- Map-reduce compression - content too large
        result, err = compress_map_reduce(content, target_chars, model_name, model_info, options)
    end

    if err then
        return nil, err
    end

    if not result or result == "" then
        return nil, "Model returned empty result"
    end

    -- Refine length if requested and not close enough
    if not options.skip_refinement then
        result, err = refine_length(result, target_chars, model_name, options)
        if err then
            return nil, err
        end
    end

    return result, nil
end

-- Get compression statistics
function compress.get_stats(model_name, content, target_chars)
    -- Get model information
    local model_info, err = get_model_info(model_name)
    if err then
        return nil, err
    end

    local content_chars = #content
    local compression_ratio = content_chars / target_chars
    local strategy = content_chars <= model_info.usable_chars and "direct" or "map_reduce"

    return {
        content_chars = content_chars,
        target_chars = target_chars,
        compression_ratio = compression_ratio,
        strategy = strategy,
        model_max_tokens = model_info.max_tokens,
        model_usable_chars = model_info.usable_chars,
        fits_in_context = content_chars <= model_info.usable_chars,
        needs_compression = content_chars > target_chars
    }, nil
end

-- Check if compression is feasible
function compress.can_compress(model_name, content, target_chars)
    local stats, err = compress.get_stats(model_name, content, target_chars)
    if err then
        return false, err
    end

    -- If content is already smaller, no compression needed
    if not stats.needs_compression then
        return true, nil
    end

    -- Check if target is reasonable (not too small, not too large)
    local min_reasonable = 50  -- Minimum meaningful summary
    local max_reasonable = math.floor(stats.model_usable_chars * 0.8)

    if target_chars < min_reasonable then
        return false, string.format("Target size %d is too small (minimum: %d)", target_chars, min_reasonable)
    end

    if target_chars > max_reasonable then
        return false, string.format("Target size %d is too large for model (maximum: %d)", target_chars, max_reasonable)
    end

    -- Check if compression ratio is reasonable (not asking to expand too much)
    if stats.compression_ratio < 0.1 then
        return false, "Cannot expand content by more than 10x"
    end

    return true, nil
end

-- Dependency injection for testing
function compress.set_dependencies(models_module, llm_module, text_module)
    compress._models = models_module
    compress._llm = llm_module
    compress._text = text_module
    return compress
end

return compress