local runner_util = {}

function runner_util.create_error(message: string): any
    return {
        status = "error",
        error = tostring(message)
    }
end

function runner_util.get_description(migration: any): any
    if migration.meta and migration.meta.description and migration.meta.description ~= "" then
        return migration.meta.description
    end
    if migration.comment and migration.comment ~= "" then
        return migration.comment
    end
    return ""
end

return runner_util
