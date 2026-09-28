local route = {}

local VALUES = {
    thinking = { adaptive = true, budget = true, none = true },
    sampling = "boolean",
    forced_tool_choice = "boolean",
    structured_output = { native = true, tool = true }
}
local ALLOWED = {
    thinking = "adaptive, budget, none",
    sampling = "boolean (true, false)",
    forced_tool_choice = "boolean (true, false)",
    structured_output = "native, tool"
}

local function profile_facts(facts, profile)
    if type(profile) ~= "table" then return end
    if profile.thinking_mode == "adaptive_only" then facts.thinking = "adaptive" end
    if type(profile.forced_tool_choice) == "boolean" then facts.forced_tool_choice = profile.forced_tool_choice end
    if profile.structured_output_mode == "native" then facts.structured_output = "native" end
end

local function canonical(facts: table, source: any, id: string, closed: boolean): string?
    if type(source) ~= "table" then
        return "invalid_request: route " .. id .. " accepts must be a table of thinking, sampling, forced_tool_choice, structured_output"
    end
    if closed then
        for key in pairs(source) do
            if VALUES[key] == nil then
                return "invalid_request: route " .. id .. " accepts." .. tostring(key)
                    .. " is unknown; allowed keys: thinking, sampling, forced_tool_choice, structured_output"
            end
        end
    end
    for key, values in pairs(VALUES) do
        local value = source[key]
        if value ~= nil then
            local valid = false
            if values == "boolean" then
                valid = type(value) == "boolean"
            elseif type(value) == "string" then
                valid = (values :: {[string]: boolean})[value] == true
            end
            if not valid then
                return "invalid_request: route " .. id .. " " .. key .. " must be one of: " .. ALLOWED[key]
            end
            facts[key] = value
        end
    end
    return nil
end

function route.accepts(provider_ref: table?, caller_options: table?, mode: string): (table?, string?)
    local ref = provider_ref or {}
    local caller = caller_options or {}
    local options = ref.options or {}
    local id = tostring(ref.id or "(direct)")
    local facts = {}
    -- A per-call legacy flag replaces the route's legacy flag, as caller options
    -- replace provider options.
    local reasoning = options.reasoning_model_request
    if type(caller.reasoning_model_request) == "boolean" then
        reasoning = caller.reasoning_model_request
    end
    if reasoning == true then
        facts.thinking = "adaptive"
        facts.sampling = false
    end
    profile_facts(facts, options.model_profile)
    if mode == "resolved" then
        if caller.accepts ~= nil then
            return nil, "invalid_request: route " .. id .. " accepts is only allowed on direct provider calls"
        end
        local err = canonical(facts, ref, id, false)
        if err then return nil, err end
    else
        profile_facts(facts, caller.model_profile)
        if caller.accepts ~= nil then
            local err = canonical(facts, caller.accepts, id, true)
            if err then return nil, err end
        end
    end
    return facts, nil
end

function route.clean_options(options: table): table
    local clean = {}
    for key, value in pairs(options) do
        if key ~= "reasoning_model_request" and key ~= "model_profile" and key ~= "accepts" then
            clean[key] = value
        end
    end
    return clean
end

return route
