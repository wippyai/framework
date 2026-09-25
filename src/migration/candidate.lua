local sql = require("sql")
local hash = require("hash")
local eval_runner = require("eval_runner")
local repository = require("repository")
local migration_registry = require("migration_registry")

type StagedEntry = {
    id: string,
    kind: string,
    meta: {[string]: any},
    data: any,
}

type CandidateResult = {
    applied: {{id: string, hash: string}},
    skipped: {{id: string, hash: string}},
}

local candidate = {}

local function canonical(value: any, seen: any): (string?, string?)
    local kind = type(value)
    if kind == "nil" then return "n", nil end
    if kind == "boolean" then return value and "b1" or "b0", nil end
    if kind == "number" then return "d" .. tostring(value) .. ";", nil end
    if kind == "string" then return "s" .. tostring(#value) .. ":" .. value, nil end
    if kind ~= "table" then return nil, "unsupported migration value: " .. kind end
    if seen[value] then return nil, "migration entry contains a cycle" end
    seen[value] = true
    local keys = {}
    for key in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            seen[value] = nil
            return nil, "unsupported migration key"
        end
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a: any, b: any): boolean
        if type(a) == type(b) then return a < b end
        return type(a) < type(b)
    end)
    local parts = { "t", tostring(#keys), ":" }
    for _, key in ipairs(keys) do
        local encoded_key, key_err = canonical(key, seen)
        if not encoded_key then seen[value] = nil; return nil, key_err end
        local encoded_value, value_err = canonical(value[key], seen)
        if not encoded_value then seen[value] = nil; return nil, value_err end
        parts[#parts + 1] = encoded_key
        parts[#parts + 1] = encoded_value
    end
    seen[value] = nil
    return table.concat(parts), nil
end

local ERROR_KINDS = {
    CANDIDATE_INVALID = { kind = errors.INVALID, retryable = false },
    CANDIDATE_UNKNOWN = { kind = errors.NOT_FOUND, retryable = false },
    CANDIDATE_HASH_MISMATCH = { kind = errors.CONFLICT, retryable = false },
    MIGRATION_HASH_MISMATCH = { kind = errors.CONFLICT, retryable = false },
    CANDIDATE_HASH_FAILED = { kind = errors.INTERNAL, retryable = true },
    CANDIDATE_UNAVAILABLE = { kind = errors.UNAVAILABLE, retryable = true },
    CANDIDATE_TARGET_UNAVAILABLE = { kind = errors.UNAVAILABLE, retryable = true },
    CANDIDATE_MIGRATION_FAILED = { kind = errors.INTERNAL, retryable = true },
}

local function failure(code: string, message: string, details: any?): (nil, any)
    local mapping = ERROR_KINDS[code] or { kind = errors.UNKNOWN, retryable = false }
    local info: any = { code = code }
    if type(details) == "table" then
        for key, value in pairs(details) do info[key] = value end
    elseif details ~= nil then
        info.detail = details
    end
    return nil, errors.new({
        message = message,
        kind = mapping.kind,
        retryable = mapping.retryable,
        details = info,
    })
end

local function invalid_bytes(message: string): any
    return errors.new({
        message = message,
        kind = errors.INVALID,
        retryable = false,
        details = { code = "CANDIDATE_INVALID" },
    })
end

function candidate.sha256(value: any): (string?, any)
    local bytes, err = canonical(value, {})
    if not bytes then return nil, invalid_bytes(tostring(err)) end
    return hash.sha256(bytes)
end

function candidate.entry_hash(entry: any): (string?, any)
    if type(entry) ~= "table" or not entry.id then
        return nil, invalid_bytes("migration entry id is required")
    end
    return candidate.sha256({ id = entry.id, kind = entry.kind,
        meta = entry.meta, data = entry.data })
end

local function is_migration(entry: any): boolean
    return type(entry) == "table" and type(entry.meta) == "table"
        and entry.meta.type == "migration"
end

function candidate.staged_resolver(closure: any): any
    local items = closure
    if type(items) ~= "table" then items = {} end
    local resolver = { closure = items }

    function resolver:find(options: any?): ({StagedEntry}?, string?)
        local opts = options or {}
        local collected: {StagedEntry} = {}
        for _, artifact in ipairs(self.closure) do
            if type(artifact) ~= "table" then goto skip_artifact end
            local staged = artifact.migrations
            if staged == nil and artifact.entries ~= nil then
                staged = {}
                for _, entry in ipairs(artifact.entries) do
                    if is_migration(entry) then staged[#staged + 1] = entry end
                end
            end
            for _, entry in ipairs(staged or {}) do
                if is_migration(entry)
                    and (opts.target_db == nil or entry.meta.target_db == opts.target_db) then
                    collected[#collected + 1] = entry
                end
            end
            ::skip_artifact::
        end
        table.sort(collected, migration_registry.compare)
        return collected, nil
    end

    return resolver
end

local function staged_source(entry: StagedEntry): (string?, string?)
    local data = entry.data
    if type(data) == "table" and type(data.source) == "string" and data.source ~= "" then
        return data.source, nil
    end
    return nil, "staged migration " .. tostring(entry.id) .. " has no source"
end

local function staged_method(entry: StagedEntry): string
    if type(entry.data) == "table" and type(entry.data.method) == "string" then
        return entry.data.method
    end
    local method = (entry :: any).method
    if type(method) == "string" and method ~= "" then return method end
    return "migrate"
end

local function staged_imports(entry: StagedEntry): any
    if type(entry.data) == "table" and entry.data.imports ~= nil then
        return entry.data.imports
    end
    return (entry :: any).imports
end

local MIGRATION_LIBRARY_ID = "wippy.migration:migration"
local MIGRATION_LIBRARY_MODULES = { "sql", "time" }
local MIGRATION_LIBRARY_IMPORTS = {
    core = "wippy.migration:core",
    repository = "wippy.migration:repository",
}

local function import_target_id(target: any): string?
    if type(target) == "string" then return target end
    if type(target) == "table" and type(target.id) == "string" then return target.id end
    return nil
end

local function expand_imports(imports: any): any
    local expanded = {}
    if type(imports) == "table" then
        for alias, target in pairs(imports) do
            if import_target_id(target) == MIGRATION_LIBRARY_ID and type(target) == "string" then
                expanded[alias] = { id = target, modules = MIGRATION_LIBRARY_MODULES }
            else
                expanded[alias] = target
            end
        end
    end
    local uses_migration = false
    for _, target in pairs(expanded) do
        if import_target_id(target) == MIGRATION_LIBRARY_ID then uses_migration = true end
    end
    if uses_migration then
        for alias, id in pairs(MIGRATION_LIBRARY_IMPORTS) do
            if expanded[alias] == nil then expanded[alias] = id end
        end
    end
    return expanded
end

local function expand_modules(modules: any): {string}
    local seen = { sql = true, time = true }
    local merged = { "sql", "time" }
    if type(modules) == "table" then
        for _, name in ipairs(modules) do
            if type(name) == "string" and not seen[name] then
                seen[name] = true
                merged[#merged + 1] = name
            end
        end
    end
    return merged
end

local function staged_modules(entry: StagedEntry): any
    if type(entry.data) == "table" then return entry.data.modules end
    return nil
end

local function ledger_row(target_db: string, id: string): (any, string?)
    local db, db_err = sql.get(target_db)
    if db_err then return nil, "failed to connect to database: " .. tostring(db_err) end
    local row, query_err = repository.get_migration(db, id)
    db:release()
    if query_err then return nil, tostring(query_err) end
    return row, nil
end

local function execute_staged(target_db: string, entry: StagedEntry, content_hash: string): (any, string?)
    local source, source_err = staged_source(entry)
    if source_err then return nil, source_err end
    return eval_runner.run({
        source = source,
        method = staged_method(entry),
        modules = expand_modules(staged_modules(entry)),
        imports = expand_imports(staged_imports(entry)),
        allow_classes = { "storage" },
        args = { {
            database_id = target_db,
            direction = "up",
            id = entry.id,
            content_hash = content_hash,
        } },
    })
end

function candidate.candidate_migrations_up(args: any): (CandidateResult?, any)
    if type(args) ~= "table" then
        return failure("CANDIDATE_INVALID", "argument table is required")
    end
    if type(args.target_db) ~= "string" or args.target_db == "" then
        return failure("CANDIDATE_INVALID", "target_db is required")
    end
    if type(args.resolver) ~= "table" or type(args.resolver.find) ~= "function" then
        return failure("CANDIDATE_INVALID", "resolver with find is required")
    end
    if type(args.installer_lock_token) ~= "string" or args.installer_lock_token == "" then
        return failure("CANDIDATE_INVALID", "installer_lock_token is required")
    end
    if args.candidate_closure == nil then
        return failure("CANDIDATE_INVALID", "candidate_closure is required")
    end

    local target_db: string = args.target_db
    local expected_hashes = args.expected_hashes

    local staged, find_err = args.resolver:find({ target_db = target_db })
    if find_err then
        return failure("CANDIDATE_UNAVAILABLE",
            "staged migration discovery failed: " .. tostring(find_err))
    end
    staged = staged or {}
    if type(staged) ~= "table" then
        return failure("CANDIDATE_UNAVAILABLE", "resolver returned no staged list")
    end
    table.sort(staged, migration_registry.compare)

    local db, db_err = sql.get(target_db)
    if db_err then
        return failure("CANDIDATE_TARGET_UNAVAILABLE",
            "failed to connect to database: " .. tostring(db_err))
    end
    local init_ok, init_err = repository.init_tracking_table(db)
    db:release()
    if not init_ok then
        return failure("CANDIDATE_TARGET_UNAVAILABLE",
            "failed to initialize migration tracking table: " .. tostring(init_err))
    end

    local applied: {{id: string, hash: string}} = {}
    local skipped: {{id: string, hash: string}} = {}
    local entries = staged :: {StagedEntry}

    for _, entry in ipairs(entries) do
        if type(entry.id) ~= "string" or entry.id == "" then
            return failure("CANDIDATE_INVALID", "staged migration lacks an id")
        end

        local actual, hash_err = candidate.entry_hash(entry)
        if hash_err or actual == nil then
            return failure("CANDIDATE_HASH_FAILED",
                "cannot hash staged migration " .. entry.id .. ": " .. tostring(hash_err))
        end

        if expected_hashes ~= nil then
            local expected = expected_hashes[entry.id]
            if expected == nil then
                return failure("CANDIDATE_UNKNOWN",
                    "staged migration " .. entry.id .. " is not in expected_hashes")
            end
            if expected ~= actual then
                return failure("CANDIDATE_HASH_MISMATCH",
                    "staged migration " .. entry.id .. " differs from expected hash",
                    { migration_id = entry.id, expected = expected, actual = actual })
            end
        end

        local row, row_err = ledger_row(target_db, entry.id)
        if row_err then
            return failure("CANDIDATE_TARGET_UNAVAILABLE", tostring(row_err))
        end
        if row then
            if row.content_hash ~= nil and row.content_hash ~= actual then
                return failure("MIGRATION_HASH_MISMATCH",
                    "applied migration " .. entry.id .. " changed under its id",
                    { migration_id = entry.id,
                        expected = row.content_hash, actual = actual })
            end
            skipped[#skipped + 1] = { id = entry.id, hash = actual }
        else
            local result, run_err = execute_staged(target_db, entry, actual)
            if run_err then
                return failure("CANDIDATE_MIGRATION_FAILED",
                    "staged migration " .. entry.id .. " failed: " .. tostring(run_err),
                    { migration_id = entry.id, applied = applied, skipped = skipped })
            end
            if result == nil then
                return failure("CANDIDATE_MIGRATION_FAILED",
                    "staged migration " .. entry.id .. " returned no result",
                    { migration_id = entry.id, applied = applied, skipped = skipped })
            end
            if result.status == "error" then
                return failure("CANDIDATE_MIGRATION_FAILED",
                    "staged migration " .. entry.id .. " failed: " .. tostring(result.error),
                    { migration_id = entry.id, applied = applied, skipped = skipped })
            end
            local item = result.migrations and result.migrations[1]
            if item == nil then
                return failure("CANDIDATE_MIGRATION_FAILED",
                    "staged migration " .. entry.id .. " returned no migration result",
                    { migration_id = entry.id, applied = applied, skipped = skipped })
            end
            if item.status == "applied" then
                applied[#applied + 1] = { id = entry.id, hash = actual }
            elseif item.status == "skipped" then
                skipped[#skipped + 1] = { id = entry.id, hash = actual }
            else
                return failure("CANDIDATE_MIGRATION_FAILED",
                    "staged migration " .. entry.id .. " failed: " .. tostring(item.error),
                    { migration_id = entry.id, applied = applied, skipped = skipped })
            end
        end
    end

    return { applied = applied, skipped = skipped }, nil
end

return candidate
