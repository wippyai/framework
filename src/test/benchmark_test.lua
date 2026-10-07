local test = require("test")
local benchmark = require("benchmark")
local fs = require("fs")
local json = require("json")

local function define_tests()
    test.describe("runtime benchmark reports", function()
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
