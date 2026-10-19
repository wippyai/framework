type Details = { [string]: any }

type Failure = {
    model: string?,
    provider_id: string?,
    provider_model: string?,
    error_type: string?,
    message: string?,
    skipped: boolean?,
}

local fallback = {}

fallback.MAX_CANDIDATES = 4
fallback.MIN_FALLBACK_BUDGET_MS = 5000

local DEFAULT_FALLBACK_ON: {string} = {
    "rate_limit_exceeded",
    "server_error",
    "timeout_error",
    "network_error",
}
fallback.DEFAULT_FALLBACK_ON = DEFAULT_FALLBACK_ON

function fallback.set_of(list: {string}): { [string]: boolean }
    local set: { [string]: boolean } = {}
    for _, item in ipairs(list) do
        set[item] = true
    end
    return set
end

local TRANSIENT = fallback.set_of({
    "rate_limit_exceeded",
    "server_error",
    "timeout_error",
    "network_error",
})

local CANDIDATE_UNUSABLE = fallback.set_of({
    "authentication_error",
    "model_error",
    "context_length_exceeded",
})

function fallback.string_list(value: any): {string}?
    if type(value) ~= "table" then
        return nil
    end

    local list: {string} = {}
    for _, item in ipairs(value :: {any}) do
        if type(item) == "string" and item ~= "" then
            table.insert(list, item)
        end
    end

    return list
end

function fallback.switch_set(value: any): { [string]: boolean }
    local configured = fallback.string_list(value)
    if configured ~= nil and #configured > 0 then
        return fallback.set_of(configured)
    end
    return fallback.set_of(DEFAULT_FALLBACK_ON)
end

function fallback.ordered_routes(card: any): {any}
    local routes: {any} = {}
    if type(card) ~= "table" or type(card.providers) ~= "table" then
        return routes
    end

    local ranked = {}
    for index, route in ipairs(card.providers :: {any}) do
        if type(route) == "table" then
            table.insert(ranked, { route = route, index = index, priority = tonumber(route.priority) or 0 })
        end
    end

    table.sort(ranked, function(a, b)
        if a.priority ~= b.priority then
            return a.priority > b.priority
        end
        return a.index < b.index
    end)

    for _, entry in ipairs(ranked) do
        table.insert(routes, entry.route)
    end

    return routes
end

function fallback.find_route(card: any, provider_id: string, provider_model: string?): any?
    for _, route in ipairs(fallback.ordered_routes(card)) do
        if route.id == provider_id and (provider_model == nil or route.provider_model == provider_model) then
            return route
        end
    end
    return nil
end

function fallback.should_switch(details: Details?, primary: boolean, streaming: boolean, fallback_on: { [string]: boolean }): boolean
    if details == nil then
        return false
    end

    if streaming and details.stream_started ~= false then
        return false
    end

    local error_type = details.error_type
    if type(error_type) ~= "string" then
        return false
    end

    if primary then
        return fallback_on[error_type] == true
    end

    return TRANSIENT[error_type] == true or CANDIDATE_UNUSABLE[error_type] == true
end

function fallback.capped_timeout(timeout: any, remaining_ms: number): number
    local remaining_s = math.max(1, math.floor(remaining_ms / 1000))
    local current = tonumber(timeout)

    if current ~= nil and current > 0 then
        return math.min(current, remaining_s)
    end

    return remaining_s
end

function fallback.error_details(err: any): Details?
    if err == nil or type(err) == "string" then
        return nil
    end

    local ok, details = pcall(function()
        return err:details()
    end)

    if ok and type(details) == "table" then
        return details :: Details
    end

    return nil
end

function fallback.error_message(err: any): string
    if type(err) == "string" then
        return err
    end

    local ok, message = pcall(function()
        return err:message()
    end)

    if ok and message ~= nil then
        return tostring(message)
    end

    return tostring(err)
end

function fallback.summary(failures: {Failure}): string
    local parts: {string} = {}

    for _, failure in ipairs(failures) do
        local label = tostring(failure.model or "unknown model")
        if failure.provider_id then
            label = label .. " via " .. tostring(failure.provider_id)
        end
        if failure.skipped then
            table.insert(parts, label .. ": skipped, " .. tostring(failure.message or "not usable"))
        else
            table.insert(parts, label .. ": " .. tostring(failure.error_type or "error"))
        end
    end

    return table.concat(parts, "; ")
end

return fallback
