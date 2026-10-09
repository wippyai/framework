-- Validate the protocol independently of the case events already rendered by the runner.
type RunState = {
    entry_id: string?,
    require_cases: boolean?,
    declared: number?,
    observed: number,
    cases: {passed: number, failed: number, skipped: number}?,
    completed: any?,
    result_error: any?,
    returned_false: boolean?,
    timed_out: boolean?,
    lifecycle_error: string?,
}
type RunnerError = {kind: string, message: string}

local function fail(message: string): RunnerError
    return {kind = "runner_failure", message = message}
end

local function valid_count(value: any): boolean
    return type(value) == "number" and value >= 0 and value % 1 == 0
end

local function is_event_applicable(event_ref_id: string?, active_entry_id: string?, active_status: string?): boolean
    if not event_ref_id or event_ref_id == "" then
        return false
    end
    if active_status ~= "running" then
        return false
    end
    return event_ref_id == active_entry_id
end

local function check(state: RunState): RunnerError?
    if state.lifecycle_error then
        return fail(state.lifecycle_error)
    end
    if state.completed and state.entry_id and state.completed.ref_id ~= state.entry_id then
        return fail("test completion attributed to " .. tostring(state.completed.ref_id or "<missing>")
            .. ", expected " .. tostring(state.entry_id))
    end
    if state.timed_out then
        return fail("test timed out")
    end
    if state.result_error then
        return fail("test process failed: " .. tostring(state.result_error))
    end
    if state.returned_false then
        return fail("test returned false")
    end
    if state.completed and state.declared == nil then
        return fail("test process did not report a plan")
    end
    if state.declared ~= nil then
        if state.declared < 0 then
            return fail("test process reported more than one plan")
        end
        if state.observed ~= state.declared then
            return fail(tostring(state.declared) .. " declared cases, "
                .. tostring(state.observed) .. " executed")
        end
        if not state.completed then
            return fail("test process did not report completion")
        end
        local complete = state.completed
        local total = complete.total
        local passed = complete.passed
        local failed = complete.failed
        local skipped = complete.skipped
        if not valid_count(total) or not valid_count(passed)
            or not valid_count(failed) or not valid_count(skipped)
            or total ~= state.declared
            or passed + failed + skipped ~= state.observed then
            return fail("test completion counts disagree with declared cases")
        end
        local cases = state.cases
        if cases and (passed ~= cases.passed or failed ~= cases.failed or skipped ~= cases.skipped) then
            return fail("test completion counts disagree with declared cases")
        end
    end
    if state.require_cases and (state.declared == nil or not state.completed
        or state.completed.passed + state.completed.failed == 0) then
        return fail("required test suite executed no cases")
    end
    return nil
end

return {
    check = check,
    is_event_applicable = is_event_applicable,
}
