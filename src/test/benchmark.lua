local fs = require("fs")
local json = require("json")
local env = require("env")
local io = require("io")

local function finite(value: any): boolean
    return type(value) == "number" and value == value and value < math.huge and value > -math.huge
end

local function positive_integer(value: any): boolean
    return finite(value) and value > 0 and value % 1 == 0
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
    return {
        median_ms = median,
        p95_ms = ordered[math.ceil(count * 0.95)],
        throughput_ops_per_second = throughput,
        sample_count = count,
    }
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

local function compare(baseline, current)
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
    if before.median_ms <= 0 or before.p95_ms <= 0 then
        return nil, "benchmark comparison requires positive baseline latencies"
    end
    return {
        name = baseline.name,
        size = baseline.size,
        median_percent = (after.median_ms / before.median_ms - 1) * 100,
        p95_percent = (after.p95_ms / before.p95_ms - 1) * 100,
        throughput_percent = (after.throughput_ops_per_second / before.throughput_ops_per_second - 1) * 100,
    }
end

return {report = report, compare = compare}
