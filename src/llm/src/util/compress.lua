local text = require("text")
local models = require("models")
local llm = require("llm")

---@class compress
local compress = {
    _models = models,
    _llm = llm,
    _text = text
}

---------------------------
-- PROMPT CONSTANTS
---------------------------

local PROMPTS = {
    DIRECT_COMPRESS = [[You are a professional text summarizer. Create a comprehensive summary of the provided content.

TARGET LENGTH: Exactly %d characters

INSTRUCTIONS:
- Summarize the content below in exactly %d characters
- Capture all key information, main points, and important details
- Maintain logical flow and professional tone
- Include numbers, conclusions, and critical facts
- Return only the summary text, nothing else

CONTENT TO SUMMARIZE:
%s

SUMMARY:]],

    CHUNK_COMPRESS = [[Summarize this section in approximately %d characters, preserving all important information.

Section content:
%s

Summary:]],

    SYNTHESIS = [[Create a final comprehensive summary from these section summaries.

TARGET LENGTH: Exactly %d characters

INSTRUCTIONS:
- Synthesize into one cohesive summary of exactly %d characters
- Remove redundancy between sections
- Maintain all key information
- Write in clear, flowing prose
- Return only the final summary

Section summaries:
%s

FINAL SUMMARY:]],

    REFINEMENT = [[Adjust this text to be exactly %d characters while maintaining all key information.

CURRENT TEXT (%d characters):
%s

TASK: %s the text by %d characters to reach exactly %d characters.
- Maintain all critical information and natural flow
- Return only the adjusted text

ADJUSTED TEXT:]]
}

---------------------------
-- CONFIGURATION
---------------------------

---@class CompressConfig
local CONFIG = {
    -- Token estimation: roughly how many characters equal one token for size calculations
    chars_per_token = 4,
    -- Reserve tokens for prompt instructions, formatting, and model overhead beyond content
    prompt_buffer_tokens = 500,
    -- Reserve extra tokens for generation beyond target to handle model variability
    output_buffer_tokens = 200,
    -- Leave this percentage of model context unused as safety buffer (0.1 = 10%)
    context_safety_margin = 0.1,
    -- In map-reduce mode, use this fraction of available context for each chunk (0.6 = 60%)
    chunk_context_ratio = 0.6,
    -- Overlap between chunks to maintain context continuity across boundaries
    chunk_overlap_chars = 200,
    -- Acceptable length deviation as percentage of target before attempting refinement (0.05 = 5%)
    length_tolerance_ratio = 0.05,
    -- Minimum character difference that's acceptable even if percentage would be smaller
    min_length_tolerance = 10,
    -- Maximum attempts to refine result length before accepting current result
    max_refinement_attempts = 2,
    -- Smallest meaningful summary size - reject requests below this threshold
    min_target_chars = 50,
    -- Maximum allowed expansion ratio to prevent abuse (10 = content can't grow more than 10x)
    max_expansion_ratio = 10,
    -- Maximum percentage of model's output capacity to target (0.8 = use up to 80% of max output)
    max_context_usage_ratio = 0.8,
    -- Temperature for initial compression - low for consistency
    default_temperature = 0.2,
    -- Temperature for final synthesis step - very low for accuracy
    synthesis_temperature = 0.1,
    -- Temperature for length refinement - very low for precision
    refinement_temperature = 0.1
}

---------------------------
-- UTILITY FUNCTIONS
---------------------------

---@param tokens number
---@return number
local function tokens_to_chars(tokens)
    return math.floor(tokens * CONFIG.chars_per_token)
end

---@param chars number
---@return number
local function chars_to_tokens(chars)
    return math.floor(chars / CONFIG.chars_per_token)
end

---@param model_name string
---@param mock_model_info table|nil
---@return table|nil, string|nil
local function get_model_info(model_name, mock_model_info)
    if mock_model_info then
        return mock_model_info, nil
    end

    local model_card, err = compress._models.get_by_name(model_name)
    if not model_card then
        return nil, "Model not found: " .. (err or "unknown error")
    end

    local max_context_tokens = model_card.max_tokens or 8000
    local max_output_tokens = model_card.output_tokens or 1000
    local usable_input_tokens = max_context_tokens - max_output_tokens - CONFIG.prompt_buffer_tokens
    local usable_input_chars = tokens_to_chars(usable_input_tokens)
    local safe_input_chars = math.floor(usable_input_chars * (1 - CONFIG.context_safety_margin))
    local safe_output_chars = tokens_to_chars(max_output_tokens)

    return {
        model_card = model_card,
        max_context_tokens = max_context_tokens,
        max_output_tokens = max_output_tokens,
        usable_input_chars = safe_input_chars,
        usable_input_tokens = chars_to_tokens(safe_input_chars),
        max_output_chars = safe_output_chars
    }, nil
end

---@param target_chars number
---@param model_info table
---@return number
local function calculate_safe_max_tokens(target_chars, model_info)
    local needed_tokens = chars_to_tokens(target_chars) + CONFIG.output_buffer_tokens
    return math.min(needed_tokens, model_info.max_output_tokens)
end

---@param target_chars number
---@param model_info table
---@return boolean|nil, string|nil
local function validate_target_size(target_chars, model_info)
    if not target_chars or target_chars <= 0 then
        return nil, "Target size must be a positive number"
    end

    if target_chars < CONFIG.min_target_chars then
        return nil, string.format(
            "Target size %d is too small (minimum: %d characters)",
            target_chars, CONFIG.min_target_chars
        )
    end

    local max_reasonable = math.floor(model_info.max_output_chars * CONFIG.max_context_usage_ratio)
    if target_chars > max_reasonable then
        return nil, string.format(
            "Target size %d is too large for model (max reasonable: %d characters)",
            target_chars, max_reasonable
        )
    end

    return true, nil
end

---------------------------
-- CORE COMPRESSION FUNCTIONS
---------------------------

---@param content string
---@param target_chars number
---@param model_name string
---@param model_info table
---@param options table
---@return string|nil, string|nil
local function compress_direct(content, target_chars, model_name, model_info, options)
    local prompt = string.format(PROMPTS.DIRECT_COMPRESS, target_chars, target_chars, content)
    local safe_max_tokens = calculate_safe_max_tokens(target_chars, model_info)

    local response, err = compress._llm.generate(prompt, {
        model = model_name,
        temperature = options.temperature or CONFIG.default_temperature,
        max_tokens = safe_max_tokens
    })

    if err then
        return nil, "Direct compression failed: " .. err
    end

    if not response.result or response.result == "" then
        return nil, "Model returned empty response"
    end

    return response.result, nil
end

---@param content string
---@param target_chars number
---@param model_name string
---@param model_info table
---@param options table
---@return string|nil, string|nil
local function compress_map_reduce(content, target_chars, model_name, model_info, options)
    local chunk_size = math.floor(model_info.usable_input_chars * CONFIG.chunk_context_ratio)
    local chunk_overlap = options.chunk_overlap or CONFIG.chunk_overlap_chars

    local splitter, err = compress._text.splitter.recursive({
        chunk_size = chunk_size,
        chunk_overlap = chunk_overlap
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

    local chunk_summaries = {}
    local chars_per_chunk = math.floor(target_chars / #chunks)

    if chars_per_chunk < CONFIG.min_target_chars then
        chars_per_chunk = CONFIG.min_target_chars
    end

    for i, chunk in ipairs(chunks) do
        local chunk_prompt = string.format(PROMPTS.CHUNK_COMPRESS, chars_per_chunk, chunk)
        local chunk_max_tokens = calculate_safe_max_tokens(chars_per_chunk, model_info)

        local response, err = compress._llm.generate(chunk_prompt, {
            model = model_name,
            temperature = options.temperature or CONFIG.default_temperature,
            max_tokens = chunk_max_tokens
        })

        if err then
            return nil, string.format("Failed to compress chunk %d: %s", i, err)
        end

        if not response.result or response.result == "" then
            return nil, string.format("Empty response for chunk %d", i)
        end

        table.insert(chunk_summaries, response.result)
    end

    local combined_summaries = table.concat(chunk_summaries, "\n\n")
    local synthesis_prompt = string.format(PROMPTS.SYNTHESIS, target_chars, target_chars, combined_summaries)
    local synthesis_max_tokens = calculate_safe_max_tokens(target_chars, model_info)

    local final_response, err = compress._llm.generate(synthesis_prompt, {
        model = model_name,
        temperature = CONFIG.synthesis_temperature,
        max_tokens = synthesis_max_tokens
    })

    if err then
        return nil, "Failed to synthesize final summary: " .. err
    end

    if not final_response.result or final_response.result == "" then
        return nil, "Empty response from synthesis step"
    end

    return final_response.result, nil
end

---@param result string
---@param target_chars number
---@param model_name string
---@param model_info table
---@param options table
---@param attempts number|nil
---@return string|nil, string|nil
local function refine_length(result, target_chars, model_name, model_info, options, attempts)
    attempts = attempts or 1
    local max_attempts = options.max_attempts or CONFIG.max_refinement_attempts

    if attempts > max_attempts then
        return result, nil
    end

    local actual_chars = #result
    local tolerance = math.max(
        CONFIG.min_length_tolerance,
        math.floor(target_chars * CONFIG.length_tolerance_ratio)
    )

    if math.abs(actual_chars - target_chars) <= tolerance then
        return result, nil
    end

    local adjustment_type = actual_chars > target_chars and "shorten" or "expand"
    local difference = math.abs(actual_chars - target_chars)

    local refinement_prompt = string.format(PROMPTS.REFINEMENT,
        target_chars, actual_chars, result, adjustment_type, difference, target_chars)
    local refinement_max_tokens = calculate_safe_max_tokens(target_chars, model_info)

    local refined_response, err = compress._llm.generate(refinement_prompt, {
        model = model_name,
        temperature = CONFIG.refinement_temperature,
        max_tokens = refinement_max_tokens
    })

    if err then
        return result, nil
    end

    if not refined_response.result or refined_response.result == "" then
        return result, nil
    end

    return refine_length(refined_response.result, target_chars, model_name, model_info, options, attempts + 1)
end

---------------------------
-- PUBLIC API
---------------------------

---@param model_name string
---@param content string
---@param target_chars number
---@param options table|nil
---@param mock_model_info table|nil
---@return string|nil, string|nil
function compress.to_size(model_name, content, target_chars, options, mock_model_info)
    options = options or {}

    -- Validate inputs first - no early returns for content size
    if not model_name or model_name == "" then
        return nil, "Model name is required"
    end

    if not content or content == "" then
        return nil, "Content is required"
    end

    if not target_chars or type(target_chars) ~= "number" or target_chars <= 0 then
        return nil, "Target size must be a positive number"
    end

    -- Get model information
    local model_info, err = get_model_info(model_name, mock_model_info)
    if err then
        return nil, err
    end

    -- Validate target size is reasonable for this model
    local valid, err = validate_target_size(target_chars, model_info)
    if err then
        return nil, err
    end

    -- Only return early AFTER all validation passes
    if #content <= target_chars then
        return content, nil
    end

    -- Choose compression strategy
    local result, err
    if #content <= model_info.usable_input_chars then
        result, err = compress_direct(content, target_chars, model_name, model_info, options)
    else
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
        result, err = refine_length(result, target_chars, model_name, model_info, options)
        if err then
            return nil, err
        end
    end

    return result, nil
end

---@param model_name string
---@param content string
---@param target_chars number
---@param mock_model_info table|nil
---@return table|nil, string|nil
function compress.get_stats(model_name, content, target_chars, mock_model_info)
    local model_info, err = get_model_info(model_name, mock_model_info)
    if err then
        return nil, err
    end

    local content_chars = #content
    local compression_ratio = content_chars / target_chars
    local strategy = content_chars <= model_info.usable_input_chars and "direct" or "map_reduce"

    return {
        content_chars = content_chars,
        target_chars = target_chars,
        compression_ratio = compression_ratio,
        strategy = strategy,
        model_max_context_tokens = model_info.max_context_tokens,
        model_max_output_tokens = model_info.max_output_tokens,
        model_usable_input_chars = model_info.usable_input_chars,
        model_max_output_chars = model_info.max_output_chars,
        fits_in_context = content_chars <= model_info.usable_input_chars,
        needs_compression = content_chars > target_chars,
        safe_max_tokens_for_target = calculate_safe_max_tokens(target_chars, model_info)
    }, nil
end

---@param model_name string
---@param content string
---@param target_chars number
---@param mock_model_info table|nil
---@return boolean, string|nil
function compress.can_compress(model_name, content, target_chars, mock_model_info)
    local stats, err = compress.get_stats(model_name, content, target_chars, mock_model_info)
    if err then
        return false, err
    end

    if not stats.needs_compression then
        return true, nil
    end

    if target_chars < CONFIG.min_target_chars then
        return false, string.format("Target size %d is too small (minimum: %d)", target_chars, CONFIG.min_target_chars)
    end

    if target_chars > stats.model_max_output_chars then
        return false, string.format("Target size %d exceeds model output limit (%d)", target_chars, stats.model_max_output_chars)
    end

    if stats.compression_ratio < (1 / CONFIG.max_expansion_ratio) then
        return false, string.format("Cannot expand content by more than %dx", CONFIG.max_expansion_ratio)
    end

    return true, nil
end

---@param new_config table
---@return compress
function compress.configure(new_config)
    for key, value in pairs(new_config) do
        if CONFIG[key] ~= nil then
            CONFIG[key] = value
        end
    end
    return compress
end

---@return table
function compress.get_config()
    local config_copy = {}
    for key, value in pairs(CONFIG) do
        config_copy[key] = value
    end
    return config_copy
end

return compress