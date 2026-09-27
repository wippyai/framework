-- Validate the protocol independently of the case events already rendered by the runner.
type RunState = {
    declared: number?,
    observed: number,
    completed: any?,
    result_error: any?,
    returned_false: boolean?,
}
type RunnerError = {kind: string, message: string}

local function fail(message: string): RunnerError
    return {kind = "runner_failure", message = message}
end

local function check(state: RunState): RunnerError?
    if state.result_error then
        return fail("test process failed: " .. tostring(state.result_error))
    end
    if state.returned_false then
        return fail("test returned false")
    end
    if state.declared ~= nil then
        if state.observed ~= state.declared then
            return fail(tostring(state.declared) .. " declared cases, "
                .. tostring(state.observed) .. " executed")
        end
        if not state.completed then
            return fail("test process did not report completion")
        end
        local complete = state.completed
        if complete.total ~= state.declared
            or complete.passed + complete.failed + complete.skipped ~= state.observed then
            return fail("test completion counts disagree with declared cases")
        end
    end
    return nil
end

return {check = check}
