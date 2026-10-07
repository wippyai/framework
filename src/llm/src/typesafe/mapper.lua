local output = require("output")

type Question = {
    type: string,
    instructions: any,
    criteria: any
}

type RequestPayload = {
    state: any,
    model: string,
    questions: {[string]: Question}
}

type TokenUsage = {
    prompt_tokens: number,
    completion_tokens: number,
    total_tokens: number
}

local typesafe_mapper = {}

-- Option names of a choice domain, declared either as an array or as a map of option to description
local function domain_options(domain: any): {string}
    local options: {string} = {}
    if #domain > 0 then
        for _, name in ipairs(domain) do
            options[#options + 1] = tostring(name)
        end
    else
        for name in pairs(domain) do
            options[#options + 1] = tostring(name)
        end
    end
    return options
end

local function count_keys(value: any): number
    local total = 0
    for _ in pairs(value) do
        total = total + 1
    end
    return total
end

local function probability(value: any): boolean
    return type(value) == "number" and value == value and value >= 0 and value <= 1
end

-- Providers may round each probability to four decimal places.
local function normalized(total: number, count: number): boolean
    return math.abs(total - 1) <= math.max(0.002, count * 0.00005 + 0.0001)
end

local function read_confidence(key: string, answer: any): (number?, string?)
    if answer.confidence == nil then
        return nil, nil
    end
    if not probability(answer.confidence) then
        return nil, "slot '" .. key .. "' answer carries an invalid confidence"
    end
    return answer.confidence :: number, nil
end

local function read_choice(key: string, slot: any, answer: any): (any?, string?)
    if answer.type ~= "choice" then
        return nil, "slot '" .. key .. "' expected a choice answer, received '" .. tostring(answer.type) .. "'"
    end
    if type(answer.choice) ~= "string" then
        return nil, "slot '" .. key .. "' answer carries no choice"
    end
    if type(answer.probabilities) ~= "table" then
        return nil, "slot '" .. key .. "' answer carries no probabilities"
    end

    local options = domain_options(slot.domain)
    local probabilities: {[string]: number} = {}
    local total = 0
    local highest = -1
    for _, name in ipairs(options) do
        local value = answer.probabilities[name]
        if not probability(value) then
            return nil, "slot '" .. key .. "' answer has an invalid probability for option '" .. name .. "'"
        end
        probabilities[name] = value
        total = total + (value :: number)
        if (value :: number) > highest then highest = value :: number end
    end

    if count_keys(answer.probabilities) ~= #options then
        return nil, "slot '" .. key .. "' answer reports probabilities outside its domain"
    end

    if probabilities[answer.choice] == nil then
        return nil, "slot '" .. key .. "' answer chose '" .. answer.choice .. "', which is outside its domain"
    end
    if not normalized(total, #options) then return nil, "slot '" .. key .. "' probabilities must sum to 1" end
    if probabilities[answer.choice] < highest then
        return nil, "slot '" .. key .. "' selected choice is not a highest-probability option"
    end

    local confidence, confidence_err = read_confidence(key, answer)
    if confidence_err then
        return nil, confidence_err
    end

    return {
        type = "choice",
        choice = answer.choice,
        probabilities = probabilities,
        confidence = confidence
    }
end

local function read_predicate(key: string, answer: any): (any?, string?)
    if answer.type ~= "noul" then
        return nil, "slot '" .. key .. "' expected a noul answer, received '" .. tostring(answer.type) .. "'"
    end
    if not probability(answer.noul) then
        return nil, "slot '" .. key .. "' answer carries an invalid noul probability"
    end

    return {
        type = "predicate",
        probability = answer.noul
    }
end

-- TypeSafe indexes score levels from zero; the contract reading is one-based
local function read_score(key: string, slot: any, answer: any): (any?, string?)
    if answer.type ~= "score" then
        return nil, "slot '" .. key .. "' expected a score answer, received '" .. tostring(answer.type) .. "'"
    end
    if type(answer.score) ~= "number" or answer.score ~= answer.score then
        return nil, "slot '" .. key .. "' answer carries no score"
    end
    if type(answer.probabilities) ~= "table" then
        return nil, "slot '" .. key .. "' answer carries no probabilities"
    end

    local levels = #slot.domain
    local probabilities = table.create(levels, 0)
    local total = 0
    local expected = 0
    for index = 1, levels do
        local value = answer.probabilities[tostring(index - 1)]
        if not probability(value) then
            return nil, "slot '" .. key .. "' answer has an invalid probability for level " .. tostring(index)
        end
        probabilities[index] = value
        total = total + (value :: number)
        expected = expected + (index - 1) * (value :: number)
    end

    if count_keys(answer.probabilities) ~= levels then
        return nil, "slot '" .. key .. "' answer reports probabilities outside its domain"
    end
    if not normalized(total, levels) then return nil, "slot '" .. key .. "' probabilities must sum to 1" end
    if answer.score < 0 or answer.score > levels - 1 then
        return nil, "slot '" .. key .. "' score is outside its level range"
    end
    if math.abs(answer.score - expected) > math.max(0.005, levels * levels * 0.00005) then
        return nil, "slot '" .. key .. "' score disagrees with its level probabilities"
    end

    local level = 1
    for index = 2, levels do
        if probabilities[index] > probabilities[level] then
            level = index
        end
    end

    local confidence, confidence_err = read_confidence(key, answer)
    if confidence_err then
        return nil, confidence_err
    end

    return {
        type = "score",
        score = answer.score + 1,
        level = level,
        probabilities = probabilities,
        confidence = confidence
    }
end

local function map_error_type(status_code: any, message: string?): string
    local status = tonumber(status_code) or 0
    local error_type = output.ERROR_TYPE.SERVER_ERROR

    if status == 0 then
        error_type = output.ERROR_TYPE.NETWORK_ERROR
    elseif status == 401 or status == 403 then
        error_type = output.ERROR_TYPE.AUTHENTICATION
    elseif status == 404 then
        error_type = output.ERROR_TYPE.MODEL_ERROR
    elseif status == 408 then
        error_type = output.ERROR_TYPE.TIMEOUT
    elseif status == 429 then
        error_type = output.ERROR_TYPE.RATE_LIMIT
    elseif status >= 500 then
        error_type = output.ERROR_TYPE.SERVER_ERROR
    elseif status >= 400 then
        error_type = output.ERROR_TYPE.INVALID_REQUEST
    end

    if message then
        local lower_message = message:lower()
        if lower_message:match("timeout") or lower_message:match("timed out") then
            error_type = output.ERROR_TYPE.TIMEOUT
        end
    end

    return error_type
end

-- Build the System One request body from the evaluate contract arguments
function typesafe_mapper.map_request(contract_args: any): (RequestPayload?, string?)
    local questions: {[string]: Question} = {}

    for key, slot in pairs(contract_args.questions) do
        local slot_key = tostring(key)

        if slot.type == "choice" then
            local criteria: {[string]: string} = {}
            if #slot.domain > 0 then
                for _, name in ipairs(slot.domain) do
                    criteria[tostring(name)] = ""
                end
            else
                for name, description in pairs(slot.domain) do
                    criteria[tostring(name)] = tostring(description)
                end
            end
            questions[slot_key] = {
                type = "choice",
                instructions = slot.instructions,
                criteria = criteria
            }
        elseif slot.type == "predicate" then
            local question: Question = {
                type = "noul",
                instructions = slot.instructions,
                criteria = nil
            }
            if slot.domain then
                local criteria: {[string]: string} = {}
                if slot.domain.yes ~= nil then
                    criteria["true"] = tostring(slot.domain.yes)
                end
                if slot.domain.no ~= nil then
                    criteria["false"] = tostring(slot.domain.no)
                end
                if next(criteria) then
                    question.criteria = criteria
                end
            end
            questions[slot_key] = question
        elseif slot.type == "score" then
            questions[slot_key] = {
                type = "score",
                instructions = slot.instructions,
                criteria = slot.domain
            }
        else
            return nil, "slot '" .. slot_key .. "' declares an unsupported type '" .. tostring(slot.type) .. "'"
        end
    end

    return {
        state = contract_args.state,
        model = contract_args.model :: string,
        questions = questions
    }
end

-- Build one reading per declared slot from the System One answers
function typesafe_mapper.map_response(body: any, questions: any): ({[string]: any}?, string?)
    if type(body) ~= "table" or type(body.answers) ~= "table" then
        return nil, "TypeSafe response carries no answers"
    end

    local readings: {[string]: any} = {}

    for key, slot in pairs(questions) do
        local slot_key = tostring(key)
        local answer = body.answers[slot_key]

        if type(answer) ~= "table" then
            return nil, "slot '" .. slot_key .. "' has no answer in the TypeSafe response"
        end

        local reading: any? = nil
        local reading_err: string? = nil

        if slot.type == "choice" then
            reading, reading_err = read_choice(slot_key, slot, answer)
        elseif slot.type == "predicate" then
            reading, reading_err = read_predicate(slot_key, answer)
        elseif slot.type == "score" then
            reading, reading_err = read_score(slot_key, slot, answer)
        else
            return nil, "slot '" .. slot_key .. "' declares an unsupported type '" .. tostring(slot.type) .. "'"
        end

        if not reading then
            return nil, reading_err
        end

        readings[slot_key] = reading
    end

    if count_keys(body.answers) ~= count_keys(questions) then
        return nil, "TypeSafe response contains undeclared answers"
    end

    return readings
end

function typesafe_mapper.map_tokens(usage: any): TokenUsage?
    if type(usage) ~= "table" then
        return nil
    end

    local prompt_tokens = tonumber(usage.input_tokens) or 0
    local completion_tokens = tonumber(usage.output_tokens) or 0

    return {
        prompt_tokens = prompt_tokens,
        completion_tokens = completion_tokens,
        total_tokens = prompt_tokens + completion_tokens
    }
end

function typesafe_mapper.classify_error(typesafe_error: any?): (string, string, table?)
    if not typesafe_error then
        return output.ERROR_TYPE.SERVER_ERROR, "Unknown TypeSafe error", nil
    end

    local message = typesafe_error.message or "TypeSafe API error"
    local kind = map_error_type(typesafe_error.status_code, message)

    local details: {[string]: any} = {
        status_code = typesafe_error.status_code,
        error_type = typesafe_error.error_type
    }

    if typesafe_error.metadata then
        if typesafe_error.metadata.request_id then
            details.request_id = typesafe_error.metadata.request_id
        end
        if typesafe_error.metadata.retry_after then
            details.retry_after = typesafe_error.metadata.retry_after
        end
    end

    return kind, tostring(message), details
end

return typesafe_mapper
