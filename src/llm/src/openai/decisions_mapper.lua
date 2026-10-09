local json = require("json")
local evaluation = require("evaluation")
local output = require("output")

local decisions_mapper = {}

local function sorted_keys(value): {string}
    local keys: {string} = {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys)
    return keys
end

local function dense_array(value): number?
    if type(value) ~= "table" then return nil end
    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then return nil end
        count = count + 1
    end
    for index = 1, count do
        if value[index] == nil then return nil end
    end
    return count
end

local function as_text(value): (string?, string?)
    if type(value) == "string" then return value, nil end
    local encoded, err = json.encode(value)
    if err then return nil, "Failed to encode JSON input: " .. tostring(err) end
    return encoded, nil
end

-- Only safety_identifier is an inference option. These other options belong
-- to the facade's actor and usage tracking, and never reach the provider.
local facade_options = { user = true, timestamp = true, metadata = true }
local contract_fields = {
    state = true, questions = true, model = true, options = true,
    timeout = true, retry = true, _provider_id = true
}

function decisions_mapper.map_request(args: any): (any?, string?)
    if type(args) ~= "table" then return nil, "Evaluation arguments must be a table" end
    local input_err = evaluation.validate(args.state, args.questions, args.model)
    if input_err then return nil, input_err end
    for key in pairs(args) do
        if not contract_fields[key] then
            return nil, "OpenAI Decisions does not support argument '" .. tostring(key) .. "'"
        end
    end
    if args.options ~= nil and type(args.options) ~= "table" then
        return nil, "OpenAI Decisions options must be a table"
    end
    local options = args.options or {}
    for key in pairs(options) do
        if key ~= "safety_identifier" and not facade_options[key] then
            return nil, "OpenAI Decisions does not support option '" .. tostring(key) .. "'"
        end
    end
    if options.safety_identifier ~= nil then
        if type(options.safety_identifier) ~= "string" or #options.safety_identifier > 128 then
            return nil, "OpenAI Decisions safety_identifier must be a string of at most 128 bytes"
        end
    end

    local input, text_err = as_text(args.state)
    if text_err then return nil, text_err end
    local questions: {any} = {}
    for index, key in ipairs(sorted_keys(args.questions)) do
        local slot = args.questions[key]
        local instructions, instructions_err = as_text(slot.instructions)
        if instructions_err then return nil, instructions_err end
        -- Caller keys are identifiers, not evidence or instructions for the model.
        local question: any = { type = slot.type, name = "q" .. tostring(index), instructions = instructions }
        if slot.type == "choice" then
            local choices: {any} = {}
            if #slot.domain > 0 then
                for _, value in ipairs(slot.domain) do choices[#choices + 1] = { value = value } end
            else
                for _, value in ipairs(sorted_keys(slot.domain)) do
                    choices[#choices + 1] = { value = value, description = slot.domain[value] }
                end
            end
            if #choices > 255 then return nil, "OpenAI Decisions choice domain supports at most 255 options in slot: " .. key end
            question.choices = choices
        elseif slot.type == "score" then
            local levels: {any} = {}
            for level, description in ipairs(slot.domain) do
                levels[level] = { label = "level_" .. tostring(level - 1), description = description }
            end
            question.levels = levels
        elseif slot.domain and next(slot.domain) ~= nil then
            -- Decisions predicates have no separate domain field.
            local criteria = "\n\nOutcome criteria:"
            if slot.domain.yes ~= nil then criteria = criteria .. "\nTrue: " .. slot.domain.yes end
            if slot.domain.no ~= nil then criteria = criteria .. "\nFalse: " .. slot.domain.no end
            question.instructions = tostring(instructions) .. criteria
        end
        questions[index] = question
    end
    return { model = args.model, input = input, questions = questions, safety_identifier = options.safety_identifier }
end

local function probability(value): boolean
    return type(value) == "number" and value == value and value >= 0 and value <= 1
end

local function normalized(total: number, count: number): boolean
    return math.abs(total - 1) <= math.max(0.002, count * 0.00005 + 0.0001)
end

local function read_distribution(key: string, slot: any, answer: any): (any?, string?)
    if not probability(answer.confidence) then return nil, "slot '" .. key .. "' answer carries an invalid confidence" end
    local count = dense_array(answer.probabilities)
    if not count then return nil, "slot '" .. key .. "' answer carries no probability array" end
    local probabilities: any = {}
    local expected_count = 0
    if slot.type == "choice" then
        if #slot.domain > 0 then
            for _, value in ipairs(slot.domain) do probabilities[value] = false; expected_count = expected_count + 1 end
        else
            for value in pairs(slot.domain) do probabilities[value] = false; expected_count = expected_count + 1 end
        end
    else
        expected_count = #slot.domain
        for index = 1, expected_count do probabilities[index] = false end
    end
    if count ~= expected_count then return nil, "slot '" .. key .. "' probability array does not cover its domain" end
    local total = 0
    local expected = 0
    local highest = -1
    for _, entry in ipairs(answer.probabilities) do
        if type(entry) ~= "table" or not probability(entry.probability) then
            return nil, "slot '" .. key .. "' answer carries an invalid probability"
        end
        local value = entry.value
        local target: any = value
        if slot.type == "choice" then
            if type(value) ~= "string" then return nil, "slot '" .. key .. "' probability has an invalid choice value" end
        else
            if type(value) ~= "number" or value % 1 ~= 0 or value < 0 or value >= expected_count then
                return nil, "slot '" .. key .. "' probability has an invalid score level"
            end
            if entry.label ~= "level_" .. tostring(value) then return nil, "slot '" .. key .. "' probability has an unexpected level label" end
            target = value + 1
            expected = expected + value * entry.probability
        end
        if probabilities[target] ~= false then return nil, "slot '" .. key .. "' probabilities contain an unknown or duplicate value" end
        probabilities[target] = entry.probability
        total = total + entry.probability
        if entry.probability > highest then highest = entry.probability end
    end
    if not normalized(total, count) then return nil, "slot '" .. key .. "' probabilities must sum to 1" end
    if slot.type == "choice" then
        if type(answer.choice) ~= "string" or type(probabilities[answer.choice]) ~= "number" then
            return nil, "slot '" .. key .. "' selected choice is outside its domain"
        end
        if probabilities[answer.choice] < highest then return nil, "slot '" .. key .. "' selected choice is not a highest-probability option" end
        return { type = "choice", choice = answer.choice, probabilities = probabilities, confidence = answer.confidence }
    end
    if type(answer.score) ~= "number" or answer.score ~= answer.score or answer.score < 0 or answer.score > count - 1 then
        return nil, "slot '" .. key .. "' score is outside its level range"
    end
    if math.abs(answer.score - expected) > math.max(0.005, count * count * 0.00005) then
        return nil, "slot '" .. key .. "' score disagrees with its level probabilities"
    end
    local level = 1
    for index = 2, count do
        if probabilities[index] > probabilities[level] then level = index end
    end
    return { type = "score", score = answer.score + 1, level = level, probabilities = probabilities, confidence = answer.confidence }
end

function decisions_mapper.map_response(body: any, questions: any): (any?, string?, string?)
    if type(body) ~= "table" or not dense_array(body.answers) then return nil, "OpenAI Decisions response carries no answer array" end
    local slots: {[string]: any} = {}
    local keys = sorted_keys(questions)
    for index, key in ipairs(keys) do slots["q" .. tostring(index)] = { key = key, slot = questions[key] } end
    if #body.answers ~= #keys then return nil, "OpenAI Decisions response does not answer every declared slot" end
    local seen: {[string]: boolean} = {}
    for _, answer in ipairs(body.answers) do
        if type(answer) ~= "table" or type(answer.name) ~= "string" or not slots[answer.name] then
            return nil, "OpenAI Decisions response contains an unnamed or undeclared answer"
        end
        if seen[answer.name] then return nil, "OpenAI Decisions response contains a duplicate answer" end
        seen[answer.name] = true
    end
    -- Any refusal fails the complete evaluation, even when other slots succeeded.
    for _, answer in ipairs(body.answers) do
        if answer.type == "refusal" then
            return nil, "OpenAI Decisions refused to answer slot '" .. slots[answer.name].key .. "'", output.ERROR_TYPE.CONTENT_FILTER
        end
    end
    local readings: {[string]: any} = {}
    for _, answer in ipairs(body.answers) do
        local entry = slots[answer.name]
        local key = entry.key :: string
        local slot = entry.slot
        if answer.type ~= slot.type then return nil, "slot '" .. key .. "' answer has an unexpected type" end
        if slot.type == "predicate" then
            if not probability(answer.probability) then return nil, "slot '" .. key .. "' answer carries an invalid probability" end
            readings[key] = { type = "predicate", probability = answer.probability }
        else
            local reading, err = read_distribution(key, slot, answer)
            if not reading then return nil, err end
            readings[key] = reading
        end
    end
    return readings
end

local function token_count(value): boolean
    return type(value) == "number" and value == value and value >= 0 and value < math.huge and value % 1 == 0
end

function decisions_mapper.map_tokens(usage: any): (any?, string?)
    if usage == nil then return nil, nil end
    if type(usage) ~= "table" then return nil, "OpenAI Decisions response carries invalid usage" end
    for _, key in ipairs({ "input_tokens", "output_tokens", "total_tokens" }) do
        if usage[key] ~= nil and not token_count(usage[key]) then return nil, "OpenAI Decisions usage has invalid " .. key end
    end
    local tokens: any = { prompt_tokens = usage.input_tokens, completion_tokens = usage.output_tokens, total_tokens = usage.total_tokens }
    if usage.input_tokens ~= nil and usage.output_tokens ~= nil and usage.total_tokens ~= nil
        and usage.total_tokens ~= (usage.input_tokens :: number) + (usage.output_tokens :: number) then
        return nil, "OpenAI Decisions total_tokens disagrees with input and output tokens"
    end
    if tokens.total_tokens == nil and usage.input_tokens ~= nil and usage.output_tokens ~= nil then
        tokens.total_tokens = (usage.input_tokens :: number) + (usage.output_tokens :: number)
    end
    if usage.input_tokens_details ~= nil then
        if type(usage.input_tokens_details) ~= "table" then return nil, "OpenAI Decisions usage has invalid input token details" end
        local details = usage.input_tokens_details
        for _, key in ipairs({ "cached_tokens", "cache_write_tokens" }) do
            if details[key] ~= nil and not token_count(details[key]) then return nil, "OpenAI Decisions usage has invalid " .. key end
        end
        tokens.cache_read_tokens = details.cached_tokens
        tokens.cache_write_tokens = details.cache_write_tokens
        tokens.cache_read_input_tokens = details.cached_tokens
        tokens.cache_creation_input_tokens = details.cache_write_tokens
        if usage.input_tokens ~= nil then
            local cached = ((details.cached_tokens or 0) :: number) + ((details.cache_write_tokens or 0) :: number)
            if cached > usage.input_tokens then return nil, "OpenAI Decisions cached token counts exceed input tokens" end
            -- Canonical token categories are disjoint, so context and tracking
            -- can sum them without counting cached input twice.
            tokens.prompt_tokens = (usage.input_tokens :: number) - cached
        end
    end
    if usage.output_tokens_details ~= nil then
        if type(usage.output_tokens_details) ~= "table" then return nil, "OpenAI Decisions usage has invalid output token details" end
        local thinking = usage.output_tokens_details.reasoning_tokens
        if thinking ~= nil and not token_count(thinking) then return nil, "OpenAI Decisions usage has invalid reasoning_tokens" end
        if thinking ~= nil and usage.output_tokens ~= nil and thinking > usage.output_tokens then
            return nil, "OpenAI Decisions reasoning tokens exceed output tokens"
        end
        tokens.thinking_tokens = thinking
    end
    return tokens
end

return decisions_mapper
