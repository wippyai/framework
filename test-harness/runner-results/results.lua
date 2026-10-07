local function emit(args, kind, data)
    data.ref_id = args.ref_id
    process.send(args.pid, args.topic, {type = kind, data = data})
end

local function one_pass(args)
    emit(args, "test:plan", {suites = {{tests = {"one"}}}})
    emit(args, "test:case:pass", {suite = "result protocol", test = "one"})
end

return {
    returns_false = function() return false end,
    returns_true = function() return true end,
    returns_nil = function() return nil end,
    raises_error = function() error("expected execution failure") end,
    error_status = function() return {status = "error"} end,
    completion_without_plan = function(args)
        emit(args, "test:complete", {total = 1, passed = 0, failed = 1, skipped = 0})
        return true
    end,
    missing_completion = function(args)
        one_pass(args)
        return true
    end,
    conflicting_completion = function(args)
        one_pass(args)
        emit(args, "test:complete", {total = 1, passed = 0, failed = 1, skipped = 0})
        return true
    end,
    empty_completion = function(args)
        emit(args, "test:plan", {suites = {}})
        emit(args, "test:complete", {})
        return true
    end,
}
