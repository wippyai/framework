local openai_client = require("openai_client")
local openai_mapper = require("openai_mapper")
local decisions_mapper = require("decisions_mapper")
local output = require("output")

type ClassifyError = (http_err: any?) -> (string, string, table?)

local evaluate_handler = { _client = openai_client, _mapper = decisions_mapper }

function evaluate_handler.handler(contract_args)
    if type(contract_args) ~= "table" then contract_args = {} end
    local err = output.errors.evaluate(contract_args):classifier(openai_mapper.classify_error :: ClassifyError)
    local payload, map_err = evaluate_handler._mapper.map_request(contract_args)
    if not payload then return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message(tostring(map_err)):build() end

    local response, request_err = evaluate_handler._client.request("/decisions", payload, {
        timeout = contract_args.timeout, retry = contract_args.retry
    })
    if request_err then return nil, err:from(request_err):build() end

    local readings, response_err, response_kind = evaluate_handler._mapper.map_response(response, contract_args.questions)
    local metadata: any = {}
    if type(response) == "table" then
        if type(response.metadata) == "table" then
            for key, value in pairs(response.metadata) do metadata[key] = value end
        end
        metadata.model = response.model
        metadata.usage = response.usage
    end
    if not readings then
        return nil, err:kind(response_kind or output.ERROR_TYPE.MODEL_ERROR):message(tostring(response_err)):details(metadata):build()
    end
    local tokens, usage_err = evaluate_handler._mapper.map_tokens(response.usage)
    if usage_err then return nil, err:kind(output.ERROR_TYPE.MODEL_ERROR):message(usage_err):details(metadata):build() end

    return { success = true, result = { readings = readings }, tokens = tokens, metadata = metadata }
end

return evaluate_handler
