local fs = require("fs")
local json = require("json")
local env = require("env")
local io = require("io")
local system = require("system")
local http_client = require("http_client")

local function finite(value: any): boolean
    return type(value) == "number" and value == value and value < math.huge and value > -math.huge
end

local function positive_integer(value: any): boolean
    return finite(value) and value > 0 and value % 1 == 0
end

local function profiler_stats(): (any, string?)
    local before = assert(system.memory.stats())
    local response, err = http_client.get("http://127.0.0.1:6060/debug/pprof/heap?debug=1", {timeout = 5})
    if not response then return nil, tostring(err) end
    local after = assert(system.memory.stats())
    if response.status_code ~= 200 or type(response.body) ~= "string" then
        return nil, "native profiler returned an invalid response"
    end
    local trailer = response.body:match("# runtime%.MemStats\n(.*)")
    if not trailer then return nil, "native profiler memory counters are missing" end
    local result = {}
    for _, field in ipairs({"TotalAlloc", "Mallocs", "Frees", "HeapAlloc", "HeapObjects", "NumGC"}) do
        local value = tonumber(trailer:match("# " .. field .. " = (%d+)\n"))
        if not finite(value) or value < 0 then return nil, "invalid profiler counter: " .. field end
        result[field] = value
    end
    if result.NumGC ~= before.num_gc or result.NumGC ~= after.num_gc
        or result.TotalAlloc < before.total_alloc or result.TotalAlloc > after.total_alloc
        or result.HeapObjects < before.heap_objects or result.HeapObjects > after.heap_objects
        or result.Mallocs - result.Frees ~= result.HeapObjects then
        return nil, "native profiler belongs to a different runtime or changed during measurement"
    end
    return result
end

local function measure_memory(workload: any, operations: any, exact: boolean?): (any, string?)
    if type(workload) ~= "function" or not positive_integer(operations) then
        return nil, "memory measurement requires bounded work and a positive operation count"
    end
    if exact == nil then exact = env.get("WIPPY_BENCH_EXACT_ALLOCATIONS") == "1" end
    local previous_limit, limit_err = system.memory.set_limit(-1)
    if previous_limit == nil then return nil, tostring(limit_err) end
    if previous_limit >= 2 ^ 63 then previous_limit = -1 end
    local initial, initial_err = system.memory.stats()
    if not initial or initial.next_gc > 2 ^ 53 then
        local restored, restore_err = system.memory.set_limit(previous_limit)
        if restored == nil then return nil, "failed to restore memory limit: " .. tostring(restore_err) end
        return nil, tostring(initial_err or "memory measurement requires supported enabled garbage collection")
    end
    local previous_gc, gc_err = system.gc.set_percent(-1)
    if previous_gc == nil then
        local restored, restore_err = system.memory.set_limit(previous_limit)
        if restored == nil then return nil, "failed to restore memory limit: " .. tostring(restore_err) end
        return nil, tostring(gc_err)
    end
    local measured, result = pcall(function()
        assert(system.gc.collect())
        assert(system.gc.collect())
        if exact then
            local witness = assert(profiler_stats())
            assert(system.gc.collect())
            assert(system.gc.collect())
            local confirmed = assert(profiler_stats())
            assert(confirmed.NumGC == witness.NumGC + 2, "native profiler belongs to a different runtime")
        end
        local control_before = assert(system.memory.stats())
        local control_after = assert(system.memory.stats())
        local instrumentation_bytes = control_after.total_alloc - control_before.total_alloc
        local instrumentation_objects = control_after.heap_objects - control_before.heap_objects
        local instrumentation_allocations
        if exact then
            local profile_before = assert(profiler_stats())
            local profile_after = assert(profiler_stats())
            instrumentation_allocations = profile_after.Mallocs - profile_before.Mallocs
            instrumentation_bytes = profile_after.TotalAlloc - profile_before.TotalAlloc
        end
        control_before = nil
        control_after = nil
        assert(system.gc.collect())
        assert(system.gc.collect())
        local live_heap_before = assert(system.memory.allocated())
        local profile_before
        if exact then profile_before = assert(profiler_stats()) end
        local before = assert(system.memory.stats())
        workload()
        local after = assert(system.memory.stats())
        local profile_after
        if exact then profile_after = assert(profiler_stats()) end
        assert(after.num_gc == before.num_gc, "GC ran during allocation measurement")
        if exact then
            assert(profile_after.NumGC == profile_before.NumGC, "GC ran during exact allocation measurement")
        end
        local memory: any = {
            method = exact and "pprof_memstats_mallocs_delta" or "gc_disabled_heap_objects_delta", operations = operations,
            allocated_bytes = exact and (profile_after.TotalAlloc - profile_before.TotalAlloc)
                or (after.total_alloc - before.total_alloc),
            heap_objects = after.heap_objects - before.heap_objects,
            heap_growth_bytes = after.heap_alloc - before.heap_alloc,
            live_heap_before_bytes = live_heap_before,
            gc_before = before.num_gc, gc_after = after.num_gc,
            instrumentation_allocated_bytes = instrumentation_bytes,
            instrumentation_heap_objects = instrumentation_objects,
            allocations = exact and (profile_after.Mallocs - profile_before.Mallocs) or nil,
            instrumentation_allocations = instrumentation_allocations,
        }
        if exact then memory.allocations_per_op = memory.allocations / operations end
        memory.allocated_bytes_per_op = memory.allocated_bytes / operations
        memory.heap_objects_per_op = memory.heap_objects / operations
        memory.heap_growth_bytes_per_op = memory.heap_growth_bytes / operations
        before = nil
        after = nil
        profile_before = nil
        profile_after = nil
        assert(system.gc.collect())
        assert(system.gc.collect())
        memory.live_heap_after_bytes = assert(system.memory.allocated())
        memory.retained_heap_bytes = memory.live_heap_after_bytes - memory.live_heap_before_bytes
        return memory
    end)
    local restored_gc, restore_gc_err = system.gc.set_percent(previous_gc)
    local restored_limit, restore_limit_err = system.memory.set_limit(previous_limit)
    if restored_gc == nil or restored_limit == nil then
        return nil, "failed to restore runtime settings: " .. tostring(restore_gc_err or restore_limit_err)
    end
    if not measured then return nil, tostring(result) end
    return result
end

local function memory_measurements(memory: any): (any, string?)
    if type(memory) ~= "table" or (memory.method ~= "gc_disabled_heap_objects_delta"
        and memory.method ~= "pprof_memstats_mallocs_delta")
        or not positive_integer(memory.operations) or memory.gc_before ~= memory.gc_after then
        return nil, "memory measurement requires bounded operations without garbage collection"
    end
    local result = {}
    for _, field in ipairs({"allocated_bytes", "heap_objects", "heap_growth_bytes",
        "live_heap_before_bytes", "live_heap_after_bytes", "gc_before", "gc_after",
        "instrumentation_allocated_bytes", "instrumentation_heap_objects"}) do
        local value = memory[field]
        if not finite(value) or value < 0 then return nil, "invalid memory counter: " .. field end
        result[field] = value
    end
    result.method = memory.method
    result.operations = memory.operations
    result.allocated_bytes_per_op = memory.allocated_bytes / memory.operations
    result.heap_objects_per_op = memory.heap_objects / memory.operations
    result.heap_growth_bytes_per_op = memory.heap_growth_bytes / memory.operations
    result.retained_heap_bytes = memory.live_heap_after_bytes - memory.live_heap_before_bytes
    if memory.method == "pprof_memstats_mallocs_delta" then
        if not finite(memory.allocations) or memory.allocations < 0
            or not finite(memory.instrumentation_allocations) or memory.instrumentation_allocations < 0 then
            return nil, "invalid exact allocation counter"
        end
        result.allocations = memory.allocations
        result.instrumentation_allocations = memory.instrumentation_allocations
        result.allocations_per_op = memory.allocations / memory.operations
    end
    return result
end

local function measurements(record: any): (any, string?)
    if type(record) ~= "table" or type(record.name) ~= "string"
        or not record.name:match("^[%w_-]+$") then
        return nil, "benchmark name must contain only letters, digits, underscores or hyphens"
    end
    if not positive_integer(record.size) or not positive_integer(record.operations_per_sample) then
        return nil, "benchmark size and operations_per_sample must be positive integers"
    end
    if type(record.samples_ms) ~= "table" or #record.samples_ms == 0 then
        return nil, "benchmark samples_ms must be a nonempty dense list"
    end
    local ordered: {number} = {}
    local duration = 0
    local count = 0
    for index, value in pairs(record.samples_ms) do
        if not positive_integer(index) or index > #record.samples_ms or not finite(value) or value < 0 then
            return nil, "benchmark samples must be finite nonnegative numbers in a dense list"
        end
        count = count + 1
        ordered[index] = value
        duration = duration + value
    end
    if count ~= #record.samples_ms then
        return nil, "benchmark samples_ms must be a nonempty dense list"
    end
    if not finite(duration) or duration <= 0 then
        return nil, "benchmark total measured duration must be finite and positive"
    end
    table.sort(ordered)
    local median = ordered[math.ceil(count / 2)]
    if median == nil then return nil, "benchmark median sample is missing" end
    if count % 2 == 0 then
        local upper = ordered[count / 2 + 1]
        if upper == nil then return nil, "benchmark median sample is missing" end
        median = (median + upper) / 2
    end
    local throughput = record.operations_per_sample / duration * count * 1000
    if not finite(throughput) then return nil, "benchmark throughput must be finite" end
    local result = {
        median_ms = median,
        p95_ms = ordered[math.ceil(count * 0.95)],
        throughput_ops_per_second = throughput,
        sample_count = count,
    }
    if record.memory ~= nil then
        local memory, memory_err = memory_measurements(record.memory)
        if not memory then return nil, memory_err end
        result.memory = memory
    end
    return result
end

local function report(record)
    local result, err = measurements(record)
    if not result then return nil, err end
    result.name = record.name
    result.size = record.size
    result.operations_per_sample = record.operations_per_sample
    result.samples_ms = record.samples_ms
    result.warmup_count = tonumber((env.get("WIPPY_BENCH_WARMUP"))) or 5
    result.metadata = {
        revision = env.get("WIPPY_BENCH_REVISION") or "unknown",
        runtime = env.get("WIPPY_BENCH_RUNTIME") or "unknown",
        framework_revision = env.get("WIPPY_BENCH_FRAMEWORK_REVISION"),
    }
    local encoded, encode_err = json.encode(result)
    if encode_err then return nil, tostring(encode_err) end
    local output, output_err = fs.get("wippy.test:benchmark_output")
    if not output then return nil, tostring(output_err) end
    local filename = record.name .. "-" .. tostring(record.size) .. ".json"
    local written, write_err = output:writefile(filename, encoded)
    if not written then return nil, "failed to write benchmark report: " .. tostring(write_err) end
    local summary = string.format("%s size=%d samples=%d median=%.3fms p95=%.3fms throughput=%.1f ops/s",
        result.name, result.size, result.sample_count, result.median_ms, result.p95_ms,
        result.throughput_ops_per_second)
    if not io.print(summary) then print(summary) end
    return result, filename
end

local function compare(baseline: any, current: any, require_improvement: boolean?): (any, string?)
    local before, before_err = measurements(baseline)
    if not before then return nil, before_err end
    local after, after_err = measurements(current)
    if not after then return nil, after_err end
    if type(baseline.metadata) ~= "table" or type(current.metadata) ~= "table"
        or type(baseline.metadata.runtime) ~= "string" or baseline.metadata.runtime == ""
        or baseline.metadata.runtime ~= current.metadata.runtime then
        return nil, "benchmark comparison requires matching runtime metadata"
    end
    if baseline.name ~= current.name or baseline.size ~= current.size
        or baseline.operations_per_sample ~= current.operations_per_sample then
        return nil, "benchmark comparison requires the same workload"
    end
    if require_improvement and (baseline.warmup_count ~= current.warmup_count
        or baseline.sample_count ~= current.sample_count or before.sample_count ~= after.sample_count
        or (baseline.sample_count ~= nil and baseline.sample_count ~= before.sample_count)
        or (current.sample_count ~= nil and current.sample_count ~= after.sample_count)) then
        return nil, "benchmark comparison requires the same measurement plan"
    end
    if before.median_ms <= 0 or before.p95_ms <= 0 then
        return nil, "benchmark comparison requires positive baseline latencies"
    end
    local result = {
        name = baseline.name,
        size = baseline.size,
        median_percent = (after.median_ms / before.median_ms - 1) * 100,
        p95_percent = (after.p95_ms / before.p95_ms - 1) * 100,
        throughput_percent = (after.throughput_ops_per_second / before.throughput_ops_per_second - 1) * 100,
    }
    if (before.memory == nil) ~= (after.memory == nil) then
        return nil, "benchmark comparison requires matching memory measurements"
    end
    if before.memory then
        if before.memory.method ~= after.memory.method then return nil, "benchmark comparison requires the same memory method" end
        if before.memory.operations ~= after.memory.operations then
            return nil, "benchmark comparison requires the same memory operation count"
        end
        for _, field in ipairs({"allocated_bytes_per_op", "heap_objects_per_op", "heap_growth_bytes_per_op"}) do
            local previous = before.memory[field]
            if previous <= 0 then return nil, "benchmark comparison requires positive baseline memory counters" end
            result[field .. "_percent"] = (after.memory[field] / previous - 1) * 100
        end
        result.live_heap_after_bytes_delta = after.memory.live_heap_after_bytes - before.memory.live_heap_after_bytes
        result.retained_heap_bytes_delta = after.memory.retained_heap_bytes - before.memory.retained_heap_bytes
        if before.memory.allocations_per_op then
            if before.memory.allocations_per_op <= 0 then return nil, "benchmark comparison requires positive baseline allocations" end
            result.allocations_per_op_percent = (after.memory.allocations_per_op / before.memory.allocations_per_op - 1) * 100
        end
    end
    if require_improvement then
        local failures = {}
        for _, field in ipairs({"median_percent", "p95_percent", "allocated_bytes_per_op_percent",
            "allocations_per_op_percent", "heap_growth_bytes_per_op_percent", "live_heap_after_bytes_delta"}) do
            if result[field] == nil or result[field] >= 0 then failures[#failures + 1] = field end
        end
        if #failures > 0 then
            return nil, "benchmark did not improve required metrics: " .. table.concat(failures, ", ")
        end
    end
    return result
end

return {report = report, compare = compare, measure_memory = measure_memory}
