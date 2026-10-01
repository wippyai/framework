local thinking = {}

function thinking.effort_level(effort: number): string
    if effort >= 100 then return "max" end
    if effort >= 80 then return "xhigh" end
    if effort > 50 then return "high" end
    if effort >= 20 then return "medium" end
    return "low"
end

return thinking
