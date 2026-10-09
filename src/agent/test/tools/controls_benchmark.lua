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
                local function verify(results)
                    for index = 1, size do
                        local result = results["benchmark-" .. index]
                        test.is_nil(result.error)
                        test.eq(result.result.call_id, "benchmark-" .. index)
                        test.eq(result.result._control.context.session.set.scope, "benchmark")
                    end
                end
                local function execute()
                    local validated, err = caller:validate(calls)
                    test.is_nil(err)
                    return caller:execute({}, validated)
                end
                for iteration = 1, warmup + sample_count do
                    local started = time.now()
                    local results = execute()
                    local elapsed = time.now():sub(started):seconds() * 1000
                    verify(results)
                    if iteration > warmup then samples[#samples + 1] = elapsed end
                end
                local memory
                local memory_operations = tonumber((env.get("WIPPY_BENCH_MEMORY_OPERATIONS")))
                if memory_operations then
                    test.gt(memory_operations, 0)
                    local rounds = math.ceil(memory_operations / size)
                    local memory_err
                    memory, memory_err = benchmark.measure_memory(function()
                        for _ = 1, rounds do verify(execute()) end
                    end, rounds * size)
                    test.not_nil(memory, tostring(memory_err))
                end
                local report, report_err = benchmark.report({name = "tools_" .. strategy,
                    size = size, operations_per_sample = size, samples_ms = samples, memory = memory})
                test.not_nil(report, tostring(report_err))
            end)
        end
    end)
end

return {run_tests = test.run_cases(define_tests)}
