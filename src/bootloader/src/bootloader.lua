local time = require("time")
local json = require("json")
local logger = require("logger")
local funcs = require("funcs")
local bootloader_registry = require("bootloader_registry")
local registry = require("registry")

local log = logger:named("boot")

local function log_bootloader_result(bootloader_entry, result)
    local prefix
    local log_level

    if result.status == "success" then
        prefix = "SUCCESS"
        log_level = "info"
    elseif result.status == "error" then
        prefix = "FAILED"
        log_level = "error"
    elseif result.status == "skipped" then
        prefix = "SKIPPED"
        log_level = "info"
    else
        prefix = "UNKNOWN"
        log_level = "warn"
    end

    local log_data = {
        order = bootloader_entry.meta and bootloader_entry.meta.order,
        description = bootloader_entry.meta and bootloader_entry.meta.description,
        message = result.message
    }

    if result.duration then
        log_data.duration = result.duration
    end

    if result.details then
        log_data.details = result.details
    end

    if log_level == "error" then
        log:error(prefix .. ": " .. bootloader_entry.id, log_data)
    elseif log_level == "warn" then
        log:warn(prefix .. ": " .. bootloader_entry.id, log_data)
    else
        log:info(prefix .. ": " .. bootloader_entry.id, log_data)
    end
end

local function is_service_id(dep_id)
    -- Service IDs contain ':' but don't have '.' in namespace part
    -- Bootloader IDs: "wippy.bootloader.bootloaders:encryption_key"
    -- Service IDs: "app:db", "system:logger"
    if not dep_id:match(":") then
        return false
    end

    local namespace = dep_id:match("^([^:]+):")
    -- If namespace contains '.', it's a bootloader
    return not namespace:match("%.")
end

local function wait_for_service(service_id, max_attempts, sleep_ms)
    log:info("Waiting for service", {
        service = service_id,
        max_attempts = max_attempts
    })

    for attempt = 1, max_attempts do
        -- Check if service entry exists in registry
        local entry, err = registry.get(service_id)

        if entry then
            log:info("Service is available", {
                service = service_id,
                attempts = attempt
            })
            return true, nil
        end

        if attempt < max_attempts then
            log:debug("Service not ready, retrying...", {
                service = service_id,
                attempt = attempt,
                max_attempts = max_attempts
            })
            time.sleep(sleep_ms .. "ms")
        end
    end

    local err_msg = "Service not available after " .. max_attempts .. " attempts"
    log:error("Service wait timeout", {
        service = service_id,
        attempts = max_attempts
    })

    return false, err_msg
end

local function check_dependencies(entry, completed_bootloaders)
    -- Check if bootloader has requirements
    if not entry.meta or not entry.meta.requires then
        return true, nil
    end

    local requires = entry.meta.requires
    if type(requires) ~= "table" then
        requires = { requires }
    end

    -- Check each requirement
    local missing_bootloaders = {}
    local failed_services = {}

    for _, dep_id in ipairs(requires) do
        if is_service_id(dep_id) then
            -- Service dependency - wait for it to be available
            local ok, err = wait_for_service(dep_id, 20, 500)
            if not ok then
                table.insert(failed_services, dep_id .. " (" .. tostring(err) .. ")")
            end
        else
            -- Bootloader dependency - check if completed
            local found = false
            for _, completed_id in ipairs(completed_bootloaders) do
                if completed_id == dep_id then
                    found = true
                    break
                end
            end

            if not found then
                table.insert(missing_bootloaders, dep_id)
            end
        end
    end

    -- Combine errors
    local all_errors = {}
    if #missing_bootloaders > 0 then
        table.insert(all_errors, "Missing bootloaders: " .. table.concat(missing_bootloaders, ", "))
    end
    if #failed_services > 0 then
        table.insert(all_errors, "Unavailable services: " .. table.concat(failed_services, ", "))
    end

    if #all_errors > 0 then
        return false, all_errors
    end

    return true, nil
end

local function execute_bootloader(entry, options, completed_bootloaders)
    local bootloader_id = entry.id
    local start_time = time.now()

    log:info("Executing bootloader", {
        id = bootloader_id,
        order = entry.meta and entry.meta.order,
        description = entry.meta and entry.meta.description,
        requires = entry.meta and entry.meta.requires
    })

    -- Check dependencies
    local deps_ok, dep_errors = check_dependencies(entry, completed_bootloaders)
    if not deps_ok then
        local error_message = table.concat(dep_errors, "; ")
        log:error("Bootloader dependencies not met", {
            id = bootloader_id,
            errors = dep_errors
        })

        return {
            status = "error",
            message = "Dependencies not met: " .. tostring(error_message),
            duration = 0
        }
    end

    -- Create function executor
    local executor = funcs.new()

    -- Execute bootloader
    local result, err = executor:call(bootloader_id, options)
    local end_time = time.now()
    local duration = end_time:sub(start_time):milliseconds()

    if err then
        log:error("Bootloader execution failed", {
            id = bootloader_id,
            error = err
        })

        return {
            status = "error",
            message = "Execution failed: " .. tostring(err),
            duration = duration
        }
    end

    -- Validate result
    if type(result) ~= "table" then
        log:error("Bootloader returned invalid result", {
            id = bootloader_id,
            result_type = type(result)
        })

        return {
            status = "error",
            message = "Bootloader must return a table with status field",
            duration = duration
        }
    end

    result.duration = duration
    result.id = bootloader_id

    return result
end

local function run(options)
    options = options or {}

    log:info("Starting application bootloader")

    -- Find all bootloaders
    local bootloaders, err = bootloader_registry.find()
    if err then
        log:error("Failed to discover bootloaders", { error = err })
        return false, "Failed to discover bootloaders: " .. tostring(err)
    end

    if not bootloaders or #bootloaders == 0 then
        log:warn("No bootloaders found")
        return true, "No bootloaders to execute"
    end

    log:info("Discovered bootloaders", {
        count = #bootloaders
    })

    -- Log sorted bootloader list
    for i, entry in ipairs(bootloaders) do
        log:info("Bootloader scheduled", {
            position = i,
            id = entry.id,
            order = entry.meta and entry.meta.order or 999,
            description = entry.meta and entry.meta.description or "No description"
        })
    end

    -- Execution statistics
    local total_stats = {
        success = 0,
        failed = 0,
        skipped = 0,
        total = #bootloaders,
        bootloaders = {}
    }

    local had_failure = false
    local completed_bootloaders = {}

    -- Execute each bootloader in order
    for _, entry in ipairs(bootloaders) do
        local result = execute_bootloader(entry, options, completed_bootloaders)

        log_bootloader_result(entry, result)

        -- Save result
        table.insert(total_stats.bootloaders, {
            id = entry.id,
            order = entry.meta and entry.meta.order,
            status = result.status,
            message = result.message,
            duration = result.duration
        })

        -- Update counters
        if result.status == "success" then
            total_stats.success = total_stats.success + 1
            -- Track completed bootloaders for dependency checking
            table.insert(completed_bootloaders, entry.id)
        elseif result.status == "error" then
            total_stats.failed = total_stats.failed + 1
            had_failure = true

            log:error("Bootloader failed, stopping execution", {
                id = entry.id,
                error = result.message
            })
            break
        elseif result.status == "skipped" then
            total_stats.skipped = total_stats.skipped + 1
            -- Skipped bootloaders are also considered completed for dependencies
            table.insert(completed_bootloaders, entry.id)
        end
    end

    local completion_status = had_failure and "error" or "success"
    local completion_message = had_failure
        and "Bootloader completed with errors"
        or "Bootloader completed successfully"

    log:info(completion_message, {
        status = completion_status,
        bootloaders_executed = #total_stats.bootloaders,
        success = total_stats.success,
        failed = total_stats.failed,
        skipped = total_stats.skipped
    })

    return not had_failure, total_stats
end

return { run = run }
