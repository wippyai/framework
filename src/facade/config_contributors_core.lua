local function new(registry: any, json: any, funcs: any, theming: any)

local MAX_CONTRIBUTORS = 32
local MAX_KEYS = 32
local MAX_BYTES = 256 * 1024
local MAX_DIAGNOSTICS = 32
local CONTRIBUTOR_TYPE = "wippy.facade.config_contributor"

local function add_diagnostic(diagnostics: {string}, message: string)
    if #diagnostics < MAX_DIAGNOSTICS then
        diagnostics[#diagnostics + 1] = message
    end
end

local function contributor_diagnostic(diagnostics: {string}, id: string?, message: string)
    if id then
        add_diagnostic(diagnostics, "Facade config contributor " .. id .. ": " .. message)
    else
        add_diagnostic(diagnostics, "Facade config contributor: " .. message)
    end
end

local function valid_requirement_name(value: any): boolean
    return type(value) == "string" and value:match("^[a-z][a-z0-9_]*$") ~= nil
end

local function dense_string_array(value: any): (table?, string?)
    if type(value) ~= "table" then return nil, "metadata must be an array" end
    local count = 0
    for key, item in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            return nil, "metadata must be a dense array"
        end
        count = count + 1
        if count > MAX_KEYS then return nil, "metadata exceeds its key limit" end
        if not valid_requirement_name(item) then return nil, "metadata contains an invalid requirement name" end
    end
    if count ~= #value then return nil, "metadata must be a dense array" end
    local seen = {}
    for _, item in ipairs(value) do
        if seen[item] then return nil, "metadata contains a duplicate requirement name" end
        seen[item] = true
    end
    return value, nil
end

local function encode_bounded(value: any): (string?, string?)
    local encoded, err = json.encode(value)
    if err or type(encoded) ~= "string" then return nil, "value could not be serialized" end
    if #encoded > MAX_BYTES then return nil, "serialized value exceeds its size limit" end
    return encoded, nil
end

local function contributor_id(entry: any): string?
    if type(entry) ~= "table" or type(entry.id) ~= "string" then return nil end
    local namespace, name = entry.id:match("^([a-z][a-z0-9._-]*):([a-z][a-z0-9._-]*)$")
    if not namespace or name ~= "facade_config_contribute" then return nil end
    return entry.id
end

local function validate_result(result: any, declared_outputs: {[string]: boolean}): (table?, string?)
    if type(result) ~= "table" then return nil, "returned a non-object result" end
    for key in pairs(result) do
        if key ~= "overrides" and key ~= "diagnostics" then
            return nil, "returned an unsupported result field"
        end
    end
    local overrides = result.overrides
    if overrides == nil then overrides = {} end
    if type(overrides) ~= "table" then return nil, "returned invalid overrides" end
    local key_count = 0
    for key, value in pairs(overrides) do
        key_count = key_count + 1
        if key_count > MAX_KEYS or type(key) ~= "string" or not declared_outputs[key]
            or type(value) ~= "string" then
            return nil, "returned an undeclared or invalid override"
        end
    end
    local reported = result.diagnostics
    if reported ~= nil then
        if type(reported) ~= "table" then return nil, "returned invalid diagnostics" end
        local count = 0
        for key, value in pairs(reported) do
            count = count + 1
            if type(key) ~= "number" or key < 1 or key % 1 ~= 0 or type(value) ~= "string"
                or #value > 512 or count > MAX_DIAGNOSTICS then
                return nil, "returned invalid diagnostics"
            end
        end
        if count ~= #reported then return nil, "returned sparse diagnostics" end
    end
    local encoded, encode_err = encode_bounded(result)
    if encode_err then return nil, encode_err end
    return { overrides = overrides, diagnostics = reported or {}, bytes = #encoded }, nil
end

local function inspect_entry(entry: any): (table?, string?)
    local id = contributor_id(entry)
    if not id or entry.kind ~= "function.lua" or type(entry.meta) ~= "table"
        or entry.meta.type ~= CONTRIBUTOR_TYPE then
        return nil, "entry kind, identity or metadata is invalid"
    end
    local inputs, input_err = dense_string_array(entry.meta.config_inputs)
    if input_err then return nil, input_err end
    local outputs, output_err = dense_string_array(entry.meta.config_outputs)
    if output_err then return nil, output_err end
    local output_set = {}
    for _, key in ipairs(outputs) do output_set[key] = true end
    return { id = id, inputs = inputs, outputs = outputs, output_set = output_set }, nil
end

local function compose_requirements(overrides: {[string]: any}?): (table, table)
    local original = type(overrides) == "table" and overrides or {}
    local composed = {}
    for key, value in pairs(original) do composed[key] = value end
    local diagnostics = {}
    local entries, find_err = registry.find({ [".kind"] = "function.lua", ["meta.type"] = CONTRIBUTOR_TYPE })
    if find_err or type(entries) ~= "table" then
        add_diagnostic(diagnostics, "Facade config contributors could not be discovered")
        return composed, diagnostics
    end
    if #entries > MAX_CONTRIBUTORS then
        add_diagnostic(diagnostics, "Facade config contributor count exceeds its limit")
        return composed, diagnostics
    end

    local contributors = {}
    local total_keys = 0
    for _, entry in ipairs(entries) do
        local item = inspect_entry(entry)
        if not item then
            contributor_diagnostic(diagnostics, contributor_id(entry), "skipped because its registry entry is malformed")
        else
            total_keys = total_keys + #item.inputs + #item.outputs
            if total_keys > MAX_KEYS then
                add_diagnostic(diagnostics, "Facade config contributor key count exceeds its limit")
                return composed, diagnostics
            end
            contributors[#contributors + 1] = item
        end
    end
    table.sort(contributors, function(left: any, right: any): boolean return left.id < right.id end)

    local declared_claims = {}
    for _, item in ipairs(contributors) do
        for _, key in ipairs(item.outputs) do
            declared_claims[key] = (declared_claims[key] or 0) + 1
        end
    end
    local eligible = {}
    for _, item in ipairs(contributors) do
        local conflict = false
        for _, key in ipairs(item.outputs) do
            if declared_claims[key] > 1 then conflict = true end
        end
        if conflict then
            contributor_diagnostic(diagnostics, item.id, "skipped because another contributor declares the same output")
        else
            eligible[#eligible + 1] = item
        end
    end

    local valid = {}
    local total_input_bytes = 0
    local total_output_bytes = 0
    for _, item in ipairs(eligible) do
        local defaults, explicit = {}, {}
        for _, key in ipairs(item.inputs) do
            defaults[key] = theming.requirement(key, {})
            if type(original[key]) == "string" then explicit[key] = original[key] end
        end
        local payload = { defaults = defaults, overrides = explicit }
        local encoded = encode_bounded(payload)
        if not encoded then
            contributor_diagnostic(diagnostics, item.id, "skipped because its input exceeds the size limit")
        else
            total_input_bytes = total_input_bytes + #encoded
            if total_input_bytes > MAX_BYTES then
                add_diagnostic(diagnostics, "Facade config contributor inputs exceed the total size limit")
                return composed, diagnostics
            end
            local ok, result, call_err = pcall(funcs.call, item.id, payload)
            if not ok or call_err then
                contributor_diagnostic(diagnostics, item.id, "skipped after call failure")
            else
                local checked = validate_result(result, item.output_set)
                if not checked then
                    contributor_diagnostic(diagnostics, item.id, "skipped because its result is invalid")
                else
                    total_output_bytes = total_output_bytes + checked.bytes
                    if total_output_bytes > MAX_BYTES then
                        add_diagnostic(diagnostics, "Facade config contributor outputs exceed the total size limit")
                        return composed, diagnostics
                    end
                    for _, message in ipairs(checked.diagnostics) do
                        contributor_diagnostic(diagnostics, item.id, "reported: " .. message:sub(1, 512))
                    end
                    valid[#valid + 1] = { id = item.id, overrides = checked.overrides }
                end
            end
        end
    end

    for _, item in ipairs(valid) do
        for key, value in pairs(item.overrides) do composed[key] = value end
    end
    return composed, diagnostics
end

    return { compose_requirements = compose_requirements }
end

return { new = new }
