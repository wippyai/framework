-- Test discovery, sorting, grouping, and filtering
local discovery = {}

type TestEntry = {
    id: string,
    name: string,
    group: string,
    meta: {
        type: string?,
        suite: string?,
        order: number?,
    }
}

-- Sort tests by meta.order, then by id
function discovery.sort_tests(tests: {TestEntry}): {TestEntry}
    table.sort(tests, function(a: TestEntry, b: TestEntry): boolean
        local order_a = (a.meta and a.meta.order) or 0
        local order_b = (b.meta and b.meta.order) or 0
        if order_a ~= order_b then
            return order_a < order_b
        end
        return a.id < b.id
    end)
    return tests
end

-- Group test entries by their meta.suite field
function discovery.group_by_suite(entries: {TestEntry}): ({[string]: {TestEntry}}, {TestEntry})
    local suites: {[string]: {TestEntry}} = {}
    local no_suite: {TestEntry} = {}

    for _, entry in ipairs(entries) do
        local suite = entry.meta and entry.meta.suite
        if suite then
            suites[suite] = suites[suite] or {}
            table.insert(suites[suite], entry)
        else
            table.insert(no_suite, entry)
        end
    end

    for _, tests in pairs(suites) do
        discovery.sort_tests(tests)
    end
    discovery.sort_tests(no_suite)

    return suites, no_suite
end

-- Return alphabetically sorted keys from a table
function discovery.sorted_keys(t: {[string]: any}): {string}
    local keys: {string} = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return keys
end

-- Extract the short name from a fully qualified id (after last colon)
function discovery.short_name(id: string): string
    return id:match(":([^:]+)$") or id
end

-- Filter entries whose id contains any of the given patterns
function discovery.filter_tests(entries: {TestEntry}, patterns: {string}): {TestEntry}
    if not patterns or #patterns == 0 then
        return entries
    end

    local filtered: {TestEntry} = {}
    for _, entry in ipairs(entries) do
        for _, pattern in ipairs(patterns) do
            if entry.id:find(pattern, 1, true) then
                table.insert(filtered, entry)
                break
            end
        end
    end
    return filtered
end

return discovery
