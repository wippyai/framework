local llm = require("llm")

-- resolve answers how llm resolves an identifier under the caller's security context.
local function resolve(model: string)
    llm._model_resolver = nil
    local card, err = llm.resolve_model(model)
    if err then
        return { kind = err:kind(), retryable = err:retryable(), message = err:message() }
    end
    return { name = card and card.name }
end

return { resolve = resolve }
