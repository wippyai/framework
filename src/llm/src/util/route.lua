local route = {}

local VALUES = {
    thinking = { adaptive = true, budget = true, none = true, always = true },
    sampling = "boolean",
    forced_tool_choice = "boolean",
    structured_output = { native = true, tool = true }
}
local ALLOWED = {
    thinking = "adaptive, budget, none, always",
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

-- `legacy_reasoning_flag` is true only when the route's driver binding
-- declares it owns the legacy reasoning_model_request meaning (see
-- discovery/providers.lua driver_declares_legacy_reasoning_flag). On every
-- other driver the flag derives nothing, so the request behaves as it does
-- without this normalizer.
function route.accepts(provider_ref: table?, caller_options: table?, mode: string,
    legacy_reasoning_flag: boolean?): (table?, string?)
    local ref = provider_ref or {}
    local caller = caller_options or {}
    local options = ref.options or {}
    local id = tostring(ref.id or "(direct)")
    local facts = {}
    if legacy_reasoning_flag then
        -- A per-call legacy flag replaces the route's legacy flag, as caller
        -- options replace provider options.
        local reasoning = options.reasoning_model_request
        if type(caller.reasoning_model_request) == "boolean" then
            reasoning = caller.reasoning_model_request
        end
        if reasoning == true then
            facts.thinking = "adaptive"
            facts.sampling = false
        end
    end
    profile_facts(facts, options.model_profile)
    if mode == "resolved" then
        if caller.accepts ~= nil then
            return nil, "route " .. id .. " accepts is only allowed on direct provider calls"
        end
        if caller.request ~= nil then
            return nil, "route " .. id .. " options.request is only allowed on direct provider calls; "
                .. "a resolved call takes it from the route's catalog options"
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

-- Budget thinking takes a share of the response: the budget grows with the effort
-- and the response keeps room for an answer behind it.
local MIN_THINKING_BUDGET = 1024
local MAX_THINKING_BUDGET = 24000
local ANSWER_ROOM = 1024

function route.thinking_budget(effort: number): number
    return math.floor(MIN_THINKING_BUDGET + (MAX_THINKING_BUDGET - MIN_THINKING_BUDGET) * (effort / 100) + 0.5)
end

-- The output a request sends, computed once per route before the card limit and
-- admission: `mode` is the effective thinking mode, `default_max_tokens` what the
-- driver sends for an unset max_tokens and `limit` the card's output limit.
-- budget is nil when the request has no budget thinking; dropped_thinking says the
-- limit leaves no room for the smallest budget.
function route.plan_output(max_tokens: number?, effort: number?, mode: string?, default_max_tokens: number?, limit: number?): table
    local thinks = mode == "budget" and effort ~= nil and effort > 0
    local wanted_budget = thinks and route.thinking_budget(effort :: number) or nil
    local output = max_tokens or default_max_tokens
    if wanted_budget and (not max_tokens or max_tokens <= wanted_budget) then
        output = wanted_budget + ANSWER_ROOM
    end
    local capped = false
    if limit and output and output > limit then
        output = limit
        capped = true
    end
    if not wanted_budget then
        return { max_tokens = output }
    end
    if output <= MIN_THINKING_BUDGET then
        return { max_tokens = math.min(max_tokens or default_max_tokens or output, output), dropped_thinking = true }
    end
    local budget = wanted_budget
    if capped then
        budget = math.min(budget, math.max(output - ANSWER_ROOM, MIN_THINKING_BUDGET))
    end
    return { max_tokens = output, budget = budget, wanted_budget = wanted_budget }
end

-- The budget and output a budget-thinking request sends. llm plans them before the
-- request; a driver called directly with no plan gets the same arithmetic.
function route.budget_output(options: table): (number, number)
    if options.thinking_budget_tokens then
        return options.thinking_budget_tokens, options.max_tokens
    end
    local plan = route.plan_output(options.max_tokens, options.thinking_effort, "budget", nil, nil)
    return plan.budget, plan.max_tokens
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
