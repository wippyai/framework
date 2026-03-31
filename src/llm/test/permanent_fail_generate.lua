local output = require("output")
local store = require("store")

local function handler(contract_args)
    local s, serr = store.get("app:test_store")
    if serr then return nil, errors.new({ message = "store error: " .. serr, kind = "Internal" }) end

    local count = (s:get("permanent_fail_count") or 0) + 1
    s:set("permanent_fail_count", count)

    return nil, errors.new({
        message = "Invalid API key",
        kind = "PermissionDenied",
        retryable = false,
    })
end

return { handler = handler }
