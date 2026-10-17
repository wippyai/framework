local http = require("http")
local json = require("json")
local sql = require("sql")
local security = require("security")
local env = require("env")
local funcs = require("funcs")
local theming = require("theming_helpers")

local PREFERENCES_TABLE = "app_cdn_source_preferences"
local MAX_SOURCE_MODULES = 32
local MAX_REQUEST_BYTES = 65536
local MAX_PUBLIC_URL_BYTES = 512
local MAX_DIAGNOSTICS = 32
local GET_ENDPOINT = "wippy.facade:source_preferences_get_endpoint"
local PUT_ENDPOINT = "wippy.facade:source_preferences_put_endpoint"
local DISCOVERY_FUNCTION = "wippy.cdn:discover_local_sources"
local MANAGEMENT_POLICY = "wippy.facade:cdn_source_management_access"

local function get_req(name: string, overrides: {[string]: any}?): string
    return theming.requirement(name, overrides)
end

local function copy_map(value: any): {[any]: any}
    local copy = {}
    if type(value) == "table" then
        for key, item in pairs(value) do copy[key] = item end
    end
    return copy
end

local function add_diagnostic(items: {string}, message: string)
    if #items < MAX_DIAGNOSTICS then
        items[#items + 1] = message
    end
end

local function database_id(): string
    return get_req("cdn_database", {})
end

local function open_database(required: boolean): (any?, string?)
    local id = database_id()
    if id == "" then
        if required then return nil, "CDN source management database is not configured" end
        return nil, nil
    end
    local db, err = sql.get(id)
    if err or not db then return nil, "CDN source preferences database is unavailable" end
    return db, nil
end

local function missing_table(err: any): boolean
    local message = tostring(err or ""):lower()
    return message:find("no such table", 1, true) ~= nil
        or message:find("does not exist", 1, true) ~= nil
        or message:find("undefined table", 1, true) ~= nil
end

local function read_saved(required: boolean): (table?, string?)
    local db, open_err = open_database(required)
    if open_err then return nil, open_err end
    if not db then return {}, nil end
    local rows, query_err = db:query(
        "SELECT module_id, selection FROM " .. PREFERENCES_TABLE .. " ORDER BY module_id", {})
    db:release()
    if query_err or type(rows) ~= "table" then
        if missing_table(query_err) and not required then return {}, nil end
        if missing_table(query_err) and required then return {}, nil end
        return nil, "CDN source preferences could not be read"
    end
    local saved = {}
    for _, row in ipairs(rows) do
        if type(row) ~= "table" or type(row.module_id) ~= "string"
            or (row.selection ~= "internet" and row.selection ~= "this_server") then
            return nil, "Stored CDN source preferences are invalid"
        end
        saved[row.module_id] = row.selection
    end
    return saved, nil
end

local function public_base_url(): (string?, string?, string?)
    local value = env.get("PUBLIC_API_URL") or ""
    if type(value) ~= "string" or #value == 0 or #value > MAX_PUBLIC_URL_BYTES
        or value:find("[%z\1-\32\127\\]") then
        return nil, nil, "PUBLIC_API_URL is not a valid absolute HTTP(S) URL"
    end
    local scheme, authority, remainder = value:match("^([Hh][Tt][Tt][Pp][Ss]?)://([^/%?#]+)(.*)$")
    if not scheme or not authority or authority:find("@", 1, true) then
        return nil, nil, "PUBLIC_API_URL is not a valid absolute HTTP(S) URL"
    end
    scheme = scheme:lower()
    authority = authority:lower()
    if scheme == "https" and authority:sub(-4) == ":443" then
        authority = authority:sub(1, -5)
    elseif scheme == "http" and authority:sub(-3) == ":80" then
        authority = authority:sub(1, -4)
    end
    local origin = scheme .. "://" .. authority
    local path = ""
    if remainder ~= "" then
        if remainder:sub(1, 1) ~= "/" or remainder:find("[?#]") then
            return nil, nil, "PUBLIC_API_URL is not a valid absolute HTTP(S) URL"
        end
        path = remainder
    end
    path = (path or ""):gsub("/+$", "")
    if path:find("[^A-Za-z0-9._~/-]") then
        return nil, nil, "PUBLIC_API_URL contains an unsupported base path"
    end
    for segment in path:gmatch("[^/]+") do
        if segment == "." or segment == ".." then
            return nil, nil, "PUBLIC_API_URL contains an unsupported base path"
        end
    end
    return origin .. path, origin, nil
end

local function discover_sources(): (table?, string?, table?)
    local ok, result, call_err = pcall(funcs.call, DISCOVERY_FUNCTION)
    if not ok or call_err or type(result) ~= "table" or type(result.modules) ~= "table" then
        return nil, "Installed CDN source modules could not be discovered"
    end
    if #result.modules > MAX_SOURCE_MODULES then
        return nil, "Installed CDN source module count exceeds its limit"
    end
    local modules = {}
    local seen = {}
    for _, module in ipairs(result.modules) do
        if type(module) ~= "table" or type(module.id) ~= "string"
            or #module.id > 128 or not module.id:match("^[a-z][a-z0-9._-]*$")
            or type(module.kind) ~= "string" or #module.kind > 32
            or type(module.title) ~= "string" or #module.title > 96
            or seen[module.id] then
            return nil, "Installed CDN source module identities are invalid or duplicated"
        end
        local expected_function = module.id .. ":local_source"
        if module.local_source ~= expected_function then
            return nil, "Installed CDN source resolver is not owned by its module"
        end
        seen[module.id] = true
        modules[#modules + 1] = module
    end
    table.sort(modules, function(left: any, right: any): boolean return left.id < right.id end)
    local diagnostics = {}
    local reported = result.diagnostics
    if type(reported) == "table" and type(reported.total) == "number" and reported.total > 0 then
        if type(reported.items) == "table" then
            for _, item in ipairs(reported.items) do
                if type(item) == "table" and type(item.code) == "string" and #item.code <= 96
                    and type(item.entry_id) == "string" and #item.entry_id <= 128 then
                    add_diagnostic(diagnostics, "CDN source setup issue: " .. item.code .. " (" .. item.entry_id .. ")")
                end
            end
        end
        if #diagnostics == 0 then
            add_diagnostic(diagnostics, "Some installed CDN source modules have invalid settings")
        end
    end
    return modules, nil, diagnostics
end

local function parse_map(raw: string): (table?, string?)
    if raw == "" then return {}, nil end
    local decoded, decode_err = json.decode(raw)
    if decode_err then return nil, "application import map is invalid JSON" end
    if decoded == nil then return {}, nil end
    if type(decoded) ~= "table" then return nil, "application import map is not an object" end
    for key in pairs(decoded) do
        if key ~= "imports" and key ~= "scopes" then
            return nil, "application import map contains an unsupported field"
        end
    end
    return decoded, nil
end

local function valid_mapping_key(value: any): boolean
    return type(value) == "string" and #value > 0 and #value <= 512
        and not value:find("[%z\1-\32\127\\]")
end

local function valid_mapping_url(value: any): boolean
    if type(value) ~= "string" or #value == 0 or #value > 2048
        or value:find("[%z\1-\32\127\\]") then return false end
    return value:match("^https?://") ~= nil or value:sub(1, 1) == "/"
        or value:sub(1, 2) == "./" or value:sub(1, 3) == "../"
end

local function validate_import_map(value: any): (table?, string?)
    if type(value) ~= "table" then return nil, "local import map is not an object" end
    for key in pairs(value) do
        if key ~= "imports" and key ~= "scopes" then
            return nil, "local import map contains an unsupported field"
        end
    end
    local result = {}
    if value.imports ~= nil then
        if type(value.imports) ~= "table" then return nil, "local import map imports are invalid" end
        local count = 0
        local imports = {}
        for key, target in pairs(value.imports) do
            count = count + 1
            if count > 256 or not valid_mapping_key(key) or not valid_mapping_url(target) then
                return nil, "local import map imports exceed the supported shape"
            end
            imports[key] = target
        end
        result.imports = imports
    end
    if value.scopes ~= nil then
        if type(value.scopes) ~= "table" then return nil, "local import map scopes are invalid" end
        local count = 0
        local scopes = {}
        for scope, mappings in pairs(value.scopes) do
            count = count + 1
            if count > 64 or not valid_mapping_url(scope) or type(mappings) ~= "table" then
                return nil, "local import map scopes exceed the supported shape"
            end
            local mapped = {}
            local mapping_count = 0
            for key, target in pairs(mappings) do
                mapping_count = mapping_count + 1
                if mapping_count > 256 or not valid_mapping_key(key) or not valid_mapping_url(target) then
                    return nil, "local import map scope exceeds the supported shape"
                end
                mapped[key] = target
            end
            scopes[scope] = mapped
        end
        result.scopes = scopes
    end
    return result, nil
end

local function validate_local_facts(module: any, value: any, base_url: string, origin: string): (table?, string?)
    if type(value) ~= "table" then return nil, "local source returned an invalid result" end
    if module.kind == "iconify" then
        for key in pairs(value) do if key ~= "iconify" then return nil, "Iconify source returned an unsupported field" end end
        local iconify = value.iconify
        local providers = type(iconify) == "table" and iconify.providers or nil
        local provider = type(providers) == "table" and providers[""] or nil
        if type(iconify) ~= "table" or type(providers) ~= "table" or type(provider) ~= "table"
            or type(provider.resources) ~= "table" or #provider.resources ~= 1
            or provider.resources[1] ~= origin or type(provider.path) ~= "string"
            or provider.path ~= base_url:sub(#origin + 1) .. "/cdn/iconify/" then
            return nil, "Iconify source returned invalid provider facts"
        end
        for key in pairs(iconify) do
            if key ~= "providers" then return nil, "Iconify source returned unsupported configuration fields" end
        end
        for key in pairs(provider) do
            if key ~= "resources" and key ~= "path" then return nil, "Iconify source returned unsupported provider fields" end
        end
        return { iconify = { providers = { [""] = { resources = { origin }, path = provider.path } } } }, nil
    end

    for key in pairs(value) do if key ~= "importMap" then return nil, "CDN source returned an unsupported field" end end
    if value.importMap == nil then return nil, "CDN source returned no supported local facts" end
    local import_map, import_err = validate_import_map(value.importMap)
    if import_err then return nil, import_err end
    return { importMap = import_map }, nil
end

local function invoke_local_source(module: any, base_url: string, origin: string): (table?, string?)
    local ok, result, call_err = pcall(funcs.call, module.local_source, { public_base_url = base_url })
    if not ok or call_err then return nil, "local source call failed" end
    return validate_local_facts(module, result, base_url, origin)
end

local function merge_iconify(base_raw: string, contribution: table): (string?, string?)
    local base = {}
    if base_raw ~= "" then
        local decoded, decode_err = json.decode(base_raw)
        if decode_err or type(decoded) ~= "table" then return nil, "static Iconify configuration is invalid" end
        base = decoded
    end
    local providers = copy_map(base.providers)
    local default_provider = copy_map(providers[""])
    local contributed = contribution.providers[""]
    default_provider.resources = contributed.resources
    default_provider.path = contributed.path
    providers[""] = default_provider
    base.providers = providers
    local encoded, encode_err = json.encode(base)
    if encode_err or type(encoded) ~= "string" then return nil, "composed Iconify configuration could not be encoded" end
    return encoded, nil
end

local function merge_map_section(target: table, incoming: any)
    if type(incoming) ~= "table" then return end
    for key, value in pairs(incoming) do target[key] = value end
end

local function merge_import_maps(defaults: table, application: table): table
    local result = { imports = {}, scopes = {} }
    merge_map_section(result.imports, defaults.imports)
    if type(defaults.scopes) == "table" then
        for scope, mappings in pairs(defaults.scopes) do result.scopes[scope] = copy_map(mappings) end
    end
    merge_map_section(result.imports, application.imports)
    if type(application.scopes) == "table" then
        for scope, mappings in pairs(application.scopes) do
            local current = copy_map(result.scopes[scope])
            merge_map_section(current, mappings)
            result.scopes[scope] = current
        end
    end
    if next(result.imports) == nil then result.imports = nil end
    if next(result.scopes) == nil then result.scopes = nil end
    return result
end

local function baseline_states(modules: table, saved: table, overrides: table?): table
    local states = {}
    for _, module in ipairs(modules) do
        local selection = saved[module.id] or "internet"
        local state = {
            module_id = module.id,
            saved = selection,
            effective = selection == "internet" and "internet" or "baseline",
        }
        local override_key = module.kind == "iconify" and "iconify" or "import_map"
        if type(overrides) == "table" and type(overrides[override_key]) == "string" then
            state.application_override = override_key
            if module.kind == "iconify" then state.effective = "application" end
        end
        states[#states + 1] = state
    end
    return states
end

local function compose(overrides: {[string]: any}?, saved_override: table?, modules_override: table?): table
    local effective = copy_map(overrides)
    local diagnostics = {}
    local states = {}
    local saved, saved_err = saved_override, nil
    if not saved then saved, saved_err = read_saved(false) end
    if saved_err then
        add_diagnostic(diagnostics, saved_err)
        return { overrides = effective, states = states, diagnostics = diagnostics }
    end
    local needs_local_source = false
    for _, selection in pairs(saved) do
        if selection == "this_server" then needs_local_source = true; break end
    end
    if not needs_local_source then
        if modules_override then
            states = baseline_states(modules_override, saved, overrides)
        end
        return { overrides = effective, states = states, diagnostics = diagnostics }
    end
    local modules, discovery_err, discovery_diagnostics = modules_override, nil, nil
    if not modules then modules, discovery_err, discovery_diagnostics = discover_sources() end
    if discovery_err or type(modules) ~= "table" then
        add_diagnostic(diagnostics, discovery_err or "Installed CDN source modules could not be discovered")
        return { overrides = effective, states = states, diagnostics = diagnostics }
    end
    for _, diagnostic in ipairs(discovery_diagnostics or {}) do add_diagnostic(diagnostics, diagnostic) end
    states = baseline_states(modules, saved, overrides)
    local base_url, origin, url_err = public_base_url()
    if url_err then
        add_diagnostic(diagnostics, url_err)
        return { overrides = effective, states = states, diagnostics = diagnostics }
    end

    local static_iconify = get_req("iconify", {})
    local iconify_contribution = nil
    local iconify_states = {}
    local import_states = {}
    local import_defaults = { imports = {}, scopes = {} }
    local import_source_count = 0
    for index, module in ipairs(modules) do
        local selection = saved[module.id] or "internet"
        local state = states[index]
        if selection ~= "internet" and selection ~= "this_server" then
            state.saved = "internet"
            state.effective = "baseline"
            add_diagnostic(diagnostics, "Invalid saved source selection for " .. module.id)
        elseif selection == "this_server" then
            if module.kind == "iconify" and type(overrides) == "table" and type(overrides.iconify) == "string" then
                state.effective = "application"
            else
                local facts, facts_err = invoke_local_source(module, base_url, origin)
                if facts_err then
                    add_diagnostic(diagnostics, "Local source for " .. module.id .. " was skipped: " .. facts_err)
                elseif facts.iconify then
                    iconify_contribution = facts.iconify
                    iconify_states[#iconify_states + 1] = state
                elseif facts.importMap then
                    import_source_count = import_source_count + 1
                    merge_map_section(import_defaults.imports, facts.importMap.imports)
                    if type(facts.importMap.scopes) == "table" then
                        for scope, mappings in pairs(facts.importMap.scopes) do
                            local target = import_defaults.scopes[scope]
                            if not target then target = {}; import_defaults.scopes[scope] = target end
                            merge_map_section(target, mappings)
                        end
                    end
                    import_states[#import_states + 1] = state
                end
            end
        end
    end

    if iconify_contribution then
        local encoded, iconify_err = merge_iconify(static_iconify, iconify_contribution)
        if iconify_err then
            add_diagnostic(diagnostics, iconify_err)
        else
            effective.iconify = encoded
            for _, state in ipairs(iconify_states) do state.effective = "this_server" end
        end
    end

    if import_source_count > 0 then
        local baseline, baseline_err = parse_map(get_req("import_map", {}))
        local application, application_err = parse_map(type(overrides) == "table" and overrides.import_map or "")
        if baseline_err or application_err then
            add_diagnostic(diagnostics, baseline_err or application_err or "Application import map is invalid")
        else
            local combined = merge_import_maps(import_defaults, baseline)
            combined = merge_import_maps(combined, application)
            local encoded, encode_err = json.encode(combined)
            if encode_err or type(encoded) ~= "string" then
                add_diagnostic(diagnostics, "Composed application import map could not be encoded")
            else
                effective.import_map = encoded
                for _, state in ipairs(import_states) do state.effective = "this_server" end
            end
        end
    end
    return { overrides = effective, states = states, diagnostics = diagnostics }
end

local function source_view(reload_required: boolean, modules_override: table?, diagnostics_override: table?): (table?, string?)
    local saved, saved_err = read_saved(true)
    if saved_err then return nil, saved_err end
    local modules, discovery_err, discovery_diagnostics = modules_override, nil, diagnostics_override
    if not modules then modules, discovery_err, discovery_diagnostics = discover_sources() end
    if discovery_err or type(modules) ~= "table" then
        return nil, discovery_err or "Installed CDN source modules could not be discovered"
    end
    local overrides = theming.resolve_overrides()
    local composed = compose(overrides, saved, modules)
    for _, diagnostic in ipairs(discovery_diagnostics or {}) do add_diagnostic(composed.diagnostics, diagnostic) end
    local choices = {}
    local saved_sources = {}
    for _, module in ipairs(modules) do
        local selection = saved[module.id] or "internet"
        if selection ~= "internet" and selection ~= "this_server" then selection = "internet" end
        choices[#choices + 1] = {
            module_id = module.id,
            title = module.title,
            choices = {
                { id = "internet", label = "Internet" },
                { id = "this_server", label = "This server" },
            },
        }
        saved_sources[#saved_sources + 1] = { module_id = module.id, selection = selection }
    end
    local iconify = json.decode(get_req("iconify", composed.overrides))
    local provider = type(iconify) == "table" and type(iconify.providers) == "table" and iconify.providers[""] or nil
    local application_overrides = {}
    for _, key in ipairs({ "iconify", "import_map" }) do
        if type(overrides) == "table" and type(overrides[key]) == "string" then
            application_overrides[#application_overrides + 1] = key
        end
    end
    return {
        schema_version = 1,
        saved = { sources = saved_sources },
        choices = choices,
        source_status = composed.states,
        application_overrides = application_overrides,
        diagnostics = composed.diagnostics,
        expected_facade = {
            iconify_default_provider = provider,
        },
        reload_required = reload_required,
    }, nil
end

local function response_fail(res: any, status: any, code: string, message: string)
    res:set_header("Cache-Control", "no-store")
    res:set_content_type("application/json; charset=utf-8")
    res:set_status(status)
    res:write_json({ ok = false, error = { code = code, message = message } })
end

local function response_success(res: any, result: any)
    res:set_header("Cache-Control", "no-store")
    res:set_content_type("application/json; charset=utf-8")
    res:set_status(http.STATUS.OK)
    res:write_json({ ok = true, result = result })
end

local function endpoint_context(endpoint_id: string): (any?, any?)
    local request, request_err = http.request({ timeout = 30000, max_body = MAX_REQUEST_BYTES })
    local response = http.response()
    if request_err or not request or not response then return nil, nil end
    local actor = security.actor()
    if not actor then
        response_fail(response, http.STATUS.UNAUTHORIZED, "unauthorized", "Authentication is required")
        return nil, response
    end
    local scope_id = get_req("cdn_management_security_scope", {})
    local scope = security.scope()
    if scope_id == "" or not scope then
        response_fail(response, http.STATUS.FORBIDDEN, "forbidden", "CDN source management is not configured")
        return nil, response
    end
    local policies = scope:policies()
    if type(policies) == "table" then
        for _, policy in ipairs(policies) do
            if policy and policy:id() == MANAGEMENT_POLICY
                and policy:evaluate(actor, "access", endpoint_id, nil) == "allow" then
                return request, response
            end
        end
    end
    response_fail(response, http.STATUS.FORBIDDEN, "forbidden", "CDN source management is required")
    return nil, response
end

local function get_sources()
    local request, response = endpoint_context(GET_ENDPOINT)
    if not request then return end
    local result, view_err = source_view(false)
    if view_err then
        return response_fail(response, http.STATUS.INTERNAL_ERROR, "source_settings_unavailable", view_err)
    end
    response_success(response, result)
end

local function decode_form(request: any): (table?, string?)
    local length, length_err = request:content_length()
    if length_err or (length and length > MAX_REQUEST_BYTES) then
        return nil, "Request body is invalid or too large"
    end
    local raw, body_err = request:body()
    if body_err or type(raw) ~= "string" or #raw > MAX_REQUEST_BYTES then
        return nil, "Request body is invalid or too large"
    end
    local value, decode_err = json.decode(raw)
    if decode_err or type(value) ~= "table" or type(value.sources) ~= "table" then
        return nil, "Request body must contain a sources array"
    end
    for key in pairs(value) do
        if key ~= "sources" then return nil, "Request body contains an unsupported field" end
    end
    local count = #value.sources
    if count > MAX_SOURCE_MODULES then return nil, "Source form exceeds its module limit" end
    for key in pairs(value.sources) do
        if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > count then
            return nil, "Source form is not a dense array"
        end
    end
    local seen = {}
    for index, item in ipairs(value.sources) do
        if type(item) ~= "table" or type(item.module_id) ~= "string"
            or not item.module_id:match("^[a-z][a-z0-9._-]*$")
            or (item.selection ~= "internet" and item.selection ~= "this_server")
            or seen[item.module_id] then
            return nil, "Source form contains an invalid or duplicate selection"
        end
        for key in pairs(item) do
            if key ~= "module_id" and key ~= "selection" then
                return nil, "Source form contains an unsupported selection field"
            end
        end
        seen[item.module_id] = true
    end
    return value.sources, nil
end

local function save_sources(sources: table): (boolean?, string?)
    local db, open_err = open_database(true)
    if open_err then return nil, open_err end
    local _, schema_err = db:execute([[
        CREATE TABLE IF NOT EXISTS app_cdn_source_preferences (
            module_id TEXT PRIMARY KEY NOT NULL,
            selection TEXT NOT NULL
        )
    ]], {})
    if schema_err then db:release(); return nil, "CDN source preferences could not be initialized" end
    local tx, begin_err = db:begin()
    if begin_err or not tx then db:release(); return nil, "CDN source preferences could not be saved" end
    for _, item in ipairs(sources) do
        local _, write_err = tx:execute(
            "INSERT INTO " .. PREFERENCES_TABLE .. " (module_id, selection) VALUES (?, ?) "
                .. "ON CONFLICT(module_id) DO UPDATE SET selection = excluded.selection",
            { item.module_id, item.selection })
        if write_err then
            tx:rollback()
            db:release()
            return nil, "CDN source preferences could not be saved"
        end
    end
    local _, commit_err = tx:commit()
    if commit_err then
        tx:rollback()
        db:release()
        return nil, "CDN source preferences could not be saved"
    end
    db:release()
    return true, nil
end

local function put_sources()
    local request, response = endpoint_context(PUT_ENDPOINT)
    if not request then return end
    local sources, body_err = decode_form(request)
    if body_err then return response_fail(response, http.STATUS.BAD_REQUEST, "invalid_request", body_err) end
    local modules, discovery_err, discovery_diagnostics = discover_sources()
    if discovery_err or type(modules) ~= "table" then
        return response_fail(response, http.STATUS.INTERNAL_ERROR, "source_settings_unavailable",
            discovery_err or "Installed CDN source modules could not be discovered")
    end
    if #sources ~= #modules then
        return response_fail(response, http.STATUS.BAD_REQUEST, "incomplete_form", "Submit the complete source settings form")
    end
    local known = {}
    for _, module in ipairs(modules) do known[module.id] = true end
    for _, item in ipairs(sources) do
        if not known[item.module_id] then
            return response_fail(response, http.STATUS.BAD_REQUEST, "unknown_module", "Source form contains a module that is not available")
        end
    end
    local saved, save_err = save_sources(sources)
    if save_err then
        return response_fail(response, http.STATUS.INTERNAL_ERROR, "source_settings_unavailable", save_err)
    end
    local result, view_err = source_view(true, modules, discovery_diagnostics)
    if view_err then
        return response_fail(response, http.STATUS.INTERNAL_ERROR, "source_settings_unavailable", view_err)
    end
    response_success(response, result)
end

local function compose_requirements(overrides: {[string]: any}?): (table, table)
    local result = compose(overrides)
    return result.overrides, result.diagnostics
end

return {
    compose_requirements = compose_requirements,
    get_sources = get_sources,
    put_sources = put_sources,
}
