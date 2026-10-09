local test = require("test")
local benchmark = require("benchmark")
local fs = require("fs")
local json = require("json")
local system = require("system")
local env = require("env")

local function define_tests()
    test.describe("runtime benchmark reports", function()
        test.it("measures bounded allocation work and restores runtime settings", function()
            local gc_percent = system.gc.get_percent()
            local memory_limit = system.memory.get_limit()
            local retained = {}
            local memory, err = benchmark.measure_memory(function()
                for index = 1, 100 do retained[index] = {index, string.rep("x", 128)} end
            end, 100, false)
            test.not_nil(memory, tostring(err))
            test.eq(memory.operations, 100)
            test.eq(memory.method, "gc_disabled_heap_objects_delta")
            test.eq(memory.gc_before, memory.gc_after)
            test.gt(memory.allocated_bytes, 0)
            test.gt(memory.heap_objects, 0)
            test.eq(memory.allocated_bytes_per_op, memory.allocated_bytes / 100)
            test.eq(memory.heap_objects_per_op, memory.heap_objects / 100)
            test.gt(memory.live_heap_before_bytes, 0)
            test.gt(memory.live_heap_after_bytes, 0)
            test.eq(system.gc.get_percent(), gc_percent)
            test.eq(system.memory.get_limit(), memory_limit)
            test.eq(retained[100][1], 100)
        end)

        test.it("restores runtime settings after allocation work throws", function()
            local gc_percent = system.gc.get_percent()
            local memory_limit = system.memory.get_limit()
            local memory, err = benchmark.measure_memory(function() error("allocation fixture failed") end, 10, false)
            test.is_nil(memory)
            test.is_true(tostring(err):find("allocation fixture failed", 1, true) ~= nil)
            test.eq(system.gc.get_percent(), gc_percent)
            test.eq(system.memory.get_limit(), memory_limit)
        end)

        test.it("rejects already-disabled garbage collection without enabling it", function()
            local previous_gc = assert(system.gc.set_percent(-1))
            local previous_limit = assert(system.memory.get_limit())
            local invoked = false
            local memory, err = benchmark.measure_memory(function() invoked = true end, 10, false)
            local observed_limit = system.memory.get_limit()
            local saved_limit = assert(system.memory.set_limit(-1))
            local next_gc = assert(system.memory.stats()).next_gc
            system.memory.set_limit(saved_limit)
            system.gc.set_percent(previous_gc)
            test.is_nil(memory)
            test.not_nil(err)
            test.is_false(invoked)
            test.eq(observed_limit, previous_limit)
            test.gt(next_gc, 2 ^ 53)
        end)

        test.it("preserves an initially unbounded memory limit", function()
            local previous_limit = assert(system.memory.set_limit(-1))
            local memory, err = benchmark.measure_memory(function() end, 10, false)
            local observed_limit = system.memory.get_limit()
            system.memory.set_limit(previous_limit)
            test.not_nil(memory, tostring(err))
            test.eq(observed_limit, 2 ^ 63)
        end)

        local exact_it = env.get("WIPPY_BENCH_EXACT_ALLOCATIONS") == "1" and test.it or test.it_skip
        exact_it("reads exact cumulative allocations from the native profiler", function()
            local retained = {}
            local memory, err = benchmark.measure_memory(function()
                for index = 1, 1000 do retained[index] = {index, string.rep("y", 128)} end
            end, 1000, true)
            test.not_nil(memory, tostring(err))
            test.eq(memory.method, "pprof_memstats_mallocs_delta")
            test.gt(memory.allocations, 0)
            test.eq(memory.allocations_per_op, memory.allocations / 1000)
            test.gt(memory.instrumentation_allocations, 0)
            test.eq(memory.gc_before, memory.gc_after)
            test.eq(retained[1000][1], 1000)
        end)

        local foreign_it = env.get("WIPPY_BENCH_EXACT_ALLOCATIONS") == "foreign" and test.it or test.it_skip
        foreign_it("rejects a profiler served by a different runtime before invoking work", function()
            local invoked = false
            local previous_gc = system.gc.get_percent()
            local previous_limit = system.memory.get_limit()
            local memory, err = benchmark.measure_memory(function() invoked = true end, 10, true)
            test.is_nil(memory)
            test.is_false(invoked)
            test.is_true(tostring(err):find("different runtime", 1, true) ~= nil)
            test.eq(system.gc.get_percent(), previous_gc)
            test.eq(system.memory.get_limit(), previous_limit)
        end)

        test.it("rejects unbounded allocation measurement inputs before invoking work", function()
            local invoked = false
            for _, operations in ipairs({0, -1, 1.5, math.huge}) do
                local memory, err = benchmark.measure_memory(function() invoked = true end, operations)
                test.is_nil(memory)
                test.not_nil(err)
            end
            test.is_false(invoked)
        end)

        test.it("persists allocation counters and derives normalized memory comparisons", function()
            local memory = {method = "gc_disabled_heap_objects_delta", operations = 10,
                allocated_bytes = 1000, heap_objects = 20, heap_growth_bytes = 1000,
                live_heap_before_bytes = 20000, live_heap_after_bytes = 21000,
                retained_heap_bytes = 1000, gc_before = 2, gc_after = 2,
                instrumentation_allocated_bytes = 100, instrumentation_heap_objects = 2}
            local baseline, filename = benchmark.report({name = "memory-report", size = 1,
                operations_per_sample = 1, samples_ms = {2}, memory = memory})
            test.not_nil(baseline, tostring(filename))
            local stored = json.decode((fs.get("wippy.test:benchmark_output"):readfile(filename)))
            test.not_nil(stored.memory)
            test.eq(stored.memory.allocated_bytes_per_op, 100)
            test.eq(stored.memory.heap_objects_per_op, 2)
            test.eq(stored.memory.heap_growth_bytes_per_op, 100)
            memory.allocated_bytes = 500
            memory.heap_objects = 10
            memory.heap_growth_bytes = 500
            memory.live_heap_after_bytes = 20500
            memory.retained_heap_bytes = 500
            local current = benchmark.report({name = "memory-report", size = 1,
                operations_per_sample = 1, samples_ms = {1}, memory = memory})
            local deltas, err = benchmark.compare(stored, current)
            test.not_nil(deltas, tostring(err))
            test.eq(deltas.allocated_bytes_per_op_percent, -50)
            test.eq(deltas.heap_objects_per_op_percent, -50)
            test.eq(deltas.heap_growth_bytes_per_op_percent, -50)
            test.eq(deltas.live_heap_after_bytes_delta, -500)
        end)

        test.it("rejects allocation records invalidated by garbage collection", function()
            local report, err = benchmark.report({name = "memory-gc", size = 1,
                operations_per_sample = 1, samples_ms = {2}, memory = {
                    method = "gc_disabled_heap_objects_delta", operations = 10,
                    allocated_bytes = 1000, heap_objects = 20, heap_growth_bytes = 1000,
                    live_heap_before_bytes = 20000, live_heap_after_bytes = 21000,
                    retained_heap_bytes = 1000, gc_before = 2, gc_after = 3,
                    instrumentation_allocated_bytes = 100, instrumentation_heap_objects = 2}})
            test.is_nil(report)
            test.not_nil(err)
        end)

        test.it("requires faster latencies and lower exact allocations and heap footprint", function()
            local function record(latency, bytes, allocations, growth, live)
                return {name = "strict-improvement", size = 1, operations_per_sample = 1,
                    samples_ms = {latency}, metadata = {runtime = "fixture"}, memory = {
                        method = "pprof_memstats_mallocs_delta", operations = 10,
                        allocated_bytes = bytes, allocations = allocations, heap_objects = allocations,
                        heap_growth_bytes = growth, live_heap_before_bytes = 20000,
                        live_heap_after_bytes = live, gc_before = 2, gc_after = 2,
                        instrumentation_allocated_bytes = 100, instrumentation_heap_objects = 2,
                        instrumentation_allocations = 3}}
            end
            local baseline = record(10, 1000, 20, 1000, 21000)
            for _, current in ipairs({record(10, 500, 10, 500, 20500),
                record(11, 500, 10, 500, 20500), record(5, 1000, 10, 500, 20500),
                record(5, 500, 20, 500, 20500), record(5, 500, 10, 1000, 20500),
                record(5, 500, 10, 500, 21000)}) do
                local deltas, err = benchmark.compare(baseline, current, true)
                test.is_nil(deltas)
                test.not_nil(err)
            end
            local deltas, err = benchmark.compare(baseline, record(5, 500, 10, 500, 20500), true)
            test.not_nil(deltas, tostring(err))
        end)

        test.it("rejects comparisons with different allocation operation counts", function()
            local function record(operations)
                return {name = "matched-operations", size = 1, operations_per_sample = 1,
                    samples_ms = {10}, metadata = {runtime = "fixture"}, memory = {
                        method = "gc_disabled_heap_objects_delta", operations = operations,
                        allocated_bytes = 1000, heap_objects = 20, heap_growth_bytes = 1000,
                        live_heap_before_bytes = 20000, live_heap_after_bytes = 21000,
                        gc_before = 2, gc_after = 2, instrumentation_allocated_bytes = 100,
                        instrumentation_heap_objects = 2}}
            end
            local deltas, err = benchmark.compare(record(10), record(100))
            test.is_nil(deltas)
            test.not_nil(err)
        end)

        test.it("rejects strict comparison with mismatched warmup or sample plans", function()
            local baseline = {name = "matched-plan", size = 1, operations_per_sample = 1,
                samples_ms = {10, 20}, warmup_count = 5, sample_count = 2,
                metadata = {runtime = "fixture"}}
            for _, current in ipairs({
                {name = "matched-plan", size = 1, operations_per_sample = 1,
                    samples_ms = {5, 10}, warmup_count = 100, sample_count = 2, metadata = {runtime = "fixture"}},
                {name = "matched-plan", size = 1, operations_per_sample = 1,
                    samples_ms = {5}, warmup_count = 5, sample_count = 1, metadata = {runtime = "fixture"}},
            }) do
                local deltas, err = benchmark.compare(baseline, current, true)
                test.is_nil(deltas)
                test.is_true(tostring(err):find("measurement plan", 1, true) ~= nil)
            end
        end)

        test.it("does not report success when the artifact cannot be written", function()
            local output = fs.get("wippy.test:benchmark_output")
            output:remove("report-write-failure-1.json")
            test.is_true((output:mkdir("report-write-failure-1.json")))
            local report, err = benchmark.report({name = "report-write-failure", size = 1,
                operations_per_sample = 1, samples_ms = {2}})
            output:remove("report-write-failure-1.json")
            test.is_nil(report)
            test.not_nil(err)
        end)

        test.it("compares equivalent workloads with independently derived percentage deltas", function()
            local baseline = {name = "comparison", size = 2, operations_per_sample = 1,
                samples_ms = {10, 20}, metadata = {runtime = "fixture"}}
            local current = {name = "comparison", size = 2, operations_per_sample = 1,
                samples_ms = {20, 40}, metadata = {runtime = "fixture"}}
            local deltas, err = benchmark.compare(baseline, current)
            test.not_nil(deltas, tostring(err))
            test.eq(deltas.median_percent, 100)
            test.eq(deltas.p95_percent, 100)
            test.eq(deltas.throughput_percent, -50)
        end)

        test.it("rejects comparison across workloads or runtimes and missing records", function()
            local baseline = {name = "comparison", size = 2, operations_per_sample = 1,
                samples_ms = {10, 20}, metadata = {runtime = "fixture"}}
            for _, current in ipairs({{},
                {name = "different", size = 2, operations_per_sample = 1, samples_ms = {1}, metadata = {runtime = "fixture"}},
                {name = "comparison", size = 3, operations_per_sample = 1, samples_ms = {1}, metadata = {runtime = "fixture"}},
                {name = "comparison", size = 2, operations_per_sample = 2, samples_ms = {1}, metadata = {runtime = "fixture"}},
                {name = "comparison", size = 2, operations_per_sample = 1, samples_ms = {1}, metadata = {runtime = "different"}},
                {name = "comparison", size = 2, operations_per_sample = 1, samples_ms = {1}},
            }) do
                local deltas, err = benchmark.compare(baseline, current)
                test.is_nil(deltas)
                test.not_nil(err)
            end
        end)

        test.it("writes measured samples and independently derived aggregate metrics", function()
            local samples = {40, 10, 30, 20}
            local report, filename = benchmark.report({name = "report-roundtrip", size = 2,
                operations_per_sample = 4, samples_ms = samples})
            test.not_nil(report, tostring(filename))
            test.eq(filename, "report-roundtrip-2.json")
            local output = fs.get("wippy.test:benchmark_output")
            local stored, err = json.decode((output:readfile(filename)))
            test.is_nil(err)
            test.eq(stored.name, "report-roundtrip")
            test.eq(stored.size, 2)
            test.eq(stored.operations_per_sample, 4)
            test.eq(stored.sample_count, 4)
            test.eq(stored.median_ms, 25)
            test.eq(stored.p95_ms, 40)
            test.eq(stored.throughput_ops_per_second, 160)
            test.eq(stored.samples_ms[1], 40)
            test.eq(stored.samples_ms[2], 10)
            test.eq(samples[1], 40)
            test.eq(samples[2], 10)
            test.is_string(stored.metadata.revision)
            test.is_string(stored.metadata.runtime)
        end)

        test.it("retains zero samples when total measured time is positive", function()
            local report, filename = benchmark.report({name = "report-zero-sample", size = 1,
                operations_per_sample = 3, samples_ms = {0, 4}})
            test.not_nil(report, tostring(filename))
            test.eq(report.median_ms, 2)
            test.eq(report.p95_ms, 4)
            test.eq(report.throughput_ops_per_second, 1500)
        end)

        test.it("selects the nearest rank p95 without replacing an odd median", function()
            local report, filename = benchmark.report({name = "report-odd-sample", size = 1,
                operations_per_sample = 1, samples_ms = {5, 1, 3}})
            test.not_nil(report, tostring(filename))
            test.eq(report.median_ms, 3)
            test.eq(report.p95_ms, 5)
        end)

        test.it("uses distinct files for benchmark names and sizes", function()
            local first, first_file = benchmark.report({name = "report-distinct", size = 1,
                operations_per_sample = 1, samples_ms = {2}})
            local second, second_file = benchmark.report({name = "report-distinct", size = 2,
                operations_per_sample = 1, samples_ms = {8}})
            local third, third_file = benchmark.report({name = "report-other", size = 1,
                operations_per_sample = 1, samples_ms = {6}})
            test.not_nil(first)
            test.not_nil(second)
            test.not_nil(third)
            local output = fs.get("wippy.test:benchmark_output")
            test.eq(json.decode((output:readfile(first_file))).median_ms, 2)
            test.eq(json.decode((output:readfile(second_file))).median_ms, 8)
            test.eq(json.decode((output:readfile(third_file))).median_ms, 6)
        end)

        test.it("rejects missing measurements and malformed records before writing", function()
            for _, record in ipairs({false, {},
                {name = "missing-size", operations_per_sample = 1, samples_ms = {1}},
                {name = "missing-ops", size = 1, samples_ms = {1}},
                {name = "missing-samples", size = 1, operations_per_sample = 1},
                {name = "empty-samples", size = 1, operations_per_sample = 1, samples_ms = {}},
                {name = "zero-duration", size = 1, operations_per_sample = 1, samples_ms = {0}},
                {name = "zero-ops", size = 1, operations_per_sample = 0, samples_ms = {1}},
                {name = "negative-size", size = -1, operations_per_sample = 1, samples_ms = {1}},
                {name = "fractional-size", size = 1.5, operations_per_sample = 1, samples_ms = {1}},
                {name = "../escaped", size = 1, operations_per_sample = 1, samples_ms = {1}},
            }) do
                local report, err = benchmark.report(record)
                test.is_nil(report)
                test.not_nil(err)
            end
        end)

        test.it("rejects non-finite, negative, non-numeric and sparse samples", function()
            local sparse = {1, 2, 3, 4, 5}
            sparse[4] = nil
            sparse[1000000000] = 6
            for _, samples in ipairs({{math.huge}, {-math.huge}, {0 / 0}, {-1}, {"1"},
                {[2] = 1}, sparse, {[1] = 1, extra = 2}, {1e308, 1e308}}) do
                local report, err = benchmark.report({name = "report-invalid", size = 1,
                    operations_per_sample = 1, samples_ms = samples})
                test.is_nil(report)
                test.not_nil(err)
            end
            local output = fs.get("wippy.test:benchmark_output")
            local found = false
            for entry in output:readdir("/") do
                if entry.name == "report-invalid-1.json" then found = true end
            end
            test.is_false(found)
        end)
    end)
end

return {run = test.run_cases(define_tests)}
