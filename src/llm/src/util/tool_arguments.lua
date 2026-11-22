local json = require("json")

local tool_arguments = {}

-- Decodes the JSON argument text of a provider tool call into the ToolCall
-- argument fields. Malformed text stays in `arguments` and `raw_arguments`,
-- and the decoder diagnostic goes to `arguments_error`; both optional fields
-- are nil on a valid call.
function tool_arguments.decode(text: string): (any, string?, string?)
    local parsed, parse_err = json.decode(text)
    if parse_err then
        return text, text, tostring(parse_err)
    end
    return parsed or {}, nil, nil
end

return tool_arguments
