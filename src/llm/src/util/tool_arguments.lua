local json = require("json")

-- Older runtimes expose only the ordinary decoder. Use it there with the
-- same malformed-input contract and leave provider response envelopes alone.
local lossless_decode = (json :: any).decode_with_nulls
local tool_arguments = {
    decode_json = lossless_decode or json.decode,
    preserves_nulls = lossless_decode ~= nil
}

-- Decodes the JSON argument text of a provider tool call into the ToolCall
-- argument fields. Malformed text stays in `arguments` and `raw_arguments`,
-- and the decoder diagnostic goes to `arguments_error`; both optional fields
-- are nil on a valid call.
function tool_arguments.decode(text: string): (any, string?, string?)
    local parsed, parse_err = tool_arguments.decode_json(text)
    if parse_err then
        return text, text, tostring(parse_err)
    end
    return parsed or {}, nil, nil
end

return tool_arguments
