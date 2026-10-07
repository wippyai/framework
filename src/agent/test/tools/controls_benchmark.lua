local test = require("test")
local tool_caller = require("tool_caller")
local time = require("time")
local env = require("env")
local benchmark = require("benchmark")

local function define_tests()
    local sample_count = tonumber((env.get("WIPPY_BENCH_SAMPLES")))
    local benchmark_it = sample_count and _G.it or _G.it_skip
    describe("registered tool batch benchmarks", function()
        for _, strategy in ipairs({tool_caller.STRATEGY.SEQUENTIAL, tool_caller.STRATEGY.PARALLEL}) do
            benchmark_it("tools_" .. strategy, function()
                local size = tonumber((env.get("WIPPY_BENCH_SIZE"))) or 1
                local warmup = tonumber((env.get("WIPPY_BENCH_WARMUP"))) or 5
                test.gt(sample_count, 0)
                test.gt(size, 0)
                local caller = tool_caller.new():set_strategy(strategy)
                local calls = {}
                for index = 1, size do
                    calls[index] = {id = "benchmark-" .. index, name = "runtime_control",
                        registry_id = "app:control_fixture", arguments = {message = "benchmark",
                            control = {context = {session = {set = {scope = "benchmark"}}}}}}
                end
                local samples = {}
                for iteration = 1, warmup + sample_count do
                    local started = time.now()
                    local validated, err = caller:validate(calls)
                    test.is_nil(err)
                    local results = caller:execute({}, validated)
                    local elapsed = time.now():sub(started):seconds() * 1000
                    for index = 1, size do
                        local result = results["benchmark-" .. index]
                        test.is_nil(result.error)
                        test.eq(result.result.call_id, "benchmark-" .. index)
                        test.eq(result.result._control.context.session.set.scope, "benchmark")
                    end
                    if iteration > warmup then samples[#samples + 1] = elapsed end
                end
                local report, report_err = benchmark.report({name = "tools_" .. strategy,
                    size = size, operations_per_sample = size, samples_ms = samples})
                test.not_nil(report, tostring(report_err))
            end)
        end
    end)
end

return {run_tests = test.run_cases(define_tests)}
