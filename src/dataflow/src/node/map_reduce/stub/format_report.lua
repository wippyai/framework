local ctx = require("ctx")

local function run(stats_data)
    local config = ctx.all() or {}

    if config.should_fail then
        return nil, "Test failure in format_report"
    end

    local report = {
        title = config.title or "Map-Reduce Report",
        formatted_by = "format_report",
        data = stats_data
    }

    if config.style == "summary" and type(stats_data) == "table" then
        report.summary = {
            total = stats_data.sum or stats_data.count or 0,
            items = stats_data.count or 0
        }
    end

    if config.include_timestamp then
        report.timestamp = os.time()
    end

    return report
end

return { run = run }