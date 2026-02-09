-- Terminal output helpers for test runner
local io = require("io")

local term = {}

-- ANSI escape codes
local ESC = "\027["

function term.reset(): string
    return ESC .. "0m"
end

function term.bold(s: string): string
    return ESC .. "1m" .. s .. term.reset()
end

function term.dim(s: string): string
    return ESC .. "2m" .. s .. term.reset()
end

function term.red(s: string): string
    return ESC .. "31m" .. s .. term.reset()
end

function term.green(s: string): string
    return ESC .. "32m" .. s .. term.reset()
end

function term.yellow(s: string): string
    return ESC .. "33m" .. s .. term.reset()
end

function term.cyan(s: string): string
    return ESC .. "36m" .. s .. term.reset()
end

function term.clear_line(): string
    return ESC .. "2K\r"
end

function term.hide_cursor(): string
    return ESC .. "?25l"
end

function term.show_cursor(): string
    return ESC .. "?25h"
end

function term.write(s: string)
    io.write(s)
    io.flush()
end

function term.print(s: string)
    io.print(s)
end

-- Progress bar
function term.progress_bar(current: number, total: number, width: number?): string
    width = width or 20
    if total == 0 then
        return term.dim(string.rep("░", width))
    end
    local filled = math.floor((current / total) * width)
    local empty = width - filled
    return term.cyan(string.rep("█", filled)) .. term.dim(string.rep("░", empty))
end

-- Spinner frames
term.spinner_frames = {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}

function term.spinner(index: number): string
    local frame = term.spinner_frames[((index - 1) % #term.spinner_frames) + 1]
    return term.cyan(frame :: string)
end

-- Duration formatting
function term.duration(ms: number): string
    if ms < 1 then
        return term.dim("<1ms")
    elseif ms < 1000 then
        return term.dim(string.format("%dms", ms))
    else
        return term.dim(string.format("%.1fs", ms / 1000))
    end
end

return term
