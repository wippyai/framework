local ctx = require("ctx")

local function execute(args)
    if args.raise then error("runtime fixture failure") end
    local control = args.control
    return {
        success = args.fail ~= true,
        error = args.fail and "explicit runtime fixture failure" or nil,
        message = args.message,
        call_id = ctx.get("call_id"),
        scope = ctx.get("scope"),
        _control = control,
        wrapper_control = args.wrapper_control,
    }
end

local function apply(request)
    if request.phase == "before_execute" then
        if request.options.mode == "drop" then return {tool_calls = {}} end
        local rewritten = {}
        for _, call in ipairs(request.tool_calls) do
            local args = {}
            for key, value in pairs(call.arguments) do args[key] = value end
            args.message = "wrapped " .. tostring(args.message)
            rewritten[#rewritten + 1] = {
                id = call.id, name = call.name, registry_id = call.registry_id,
                arguments = args, context = call.context,
            }
        end
        return {tool_calls = rewritten}
    end
    local proposal
    for _, result in pairs(request.tool_results or {}) do
        if result.result and result.result.wrapper_control then
            proposal = result.result.wrapper_control
        end
    end
    return {
        _control = proposal,
        observations = {{level = "info", code = "runtime_outcome", content = request.outcome}},
        metadata = {phase = request.phase},
    }
end

return {execute = execute, apply = apply}
