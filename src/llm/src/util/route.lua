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
        return "route " .. id .. " accepts must be a table of thinking, sampling, forced_tool_choice, structured_output"
    end
    if closed then
        for key in pairs(source) do
            if VALUES[key] == nil then
                return "route " .. id .. " accepts." .. tostring(key)
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
                return "route " .. id .. " " .. key .. " must be one of: " .. ALLOWED[key]
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
            return nil, "route " .. id .. " accepts is only allowed on direct provider calls"
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

-- A driver capability table: { name, defaults = {fact = value}, supported = {fact = {value = true}} }.
-- `supported` only needs entries for facts a driver restricts beyond the global
-- enum; a fact absent from `supported` accepts any globally valid value.

-- The effective value of a fact: the route's declared value, or the driver's
-- default when the route leaves it unset.
function route.fact(accepts: any, key: string, capability: table): any
    if accepts and accepts[key] ~= nil then return accepts[key] end
    return capability.defaults[key]
end

-- A declared fact value the driver cannot honor: names the fact, the value
-- and the values the driver supports.
function route.unsupported_fact_error(accepts: any, capability: table): string?
    if not accepts then return nil end
    local keys = {}
    for key in pairs(accepts) do table.insert(keys, key) end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local allowed = capability.supported and capability.supported[key]
        if allowed and not allowed[accepts[key]] then
            local names = {}
            for name in pairs(allowed) do table.insert(names, name) end
            table.sort(names)
            return capability.name .. " does not support " .. key .. " = " .. tostring(accepts[key])
                .. "; supported: " .. table.concat(names, ", ")
        end
    end
    return nil
end

-- Strict enforcement for a set of adjustments: nil unless strict is set and at
-- least one adjustment was recorded, in which case the error names every
-- adjusted parameter, sorted.
function route.strict_error(id: string, strict: any, adjusted: any): string?
    if not strict or not adjusted or next(adjusted) == nil then return nil end
    local names = {}
    for key in pairs(adjusted) do table.insert(names, key) end
    table.sort(names)
    return "route " .. id .. " requires adjustments to: " .. table.concat(names, ", ")
end

-- Attaches adjustments to a result's metadata, only when there is at least one.
function route.attach_adjusted(result: any, adjusted: any)
    if not result or not adjusted or next(adjusted) == nil then return end
    result.metadata = result.metadata or {}
    result.metadata.adjusted = adjusted
end

-- A route with forced_tool_choice = false whose structured output can only be
-- produced by forcing a tool cannot honor the request: the driver would have
-- to force a tool choice the route declares it does not accept.
function route.forced_tool_output_error(accepts: any, capability: table): string?
    if route.fact(accepts, "structured_output", capability) == "tool"
        and route.fact(accepts, "forced_tool_choice", capability) == false then
        return "Model does not accept a forced tool choice (forced_tool_choice = false): "
            .. "structured output needs structured_output = \"native\""
    end
    return nil
end

return route
