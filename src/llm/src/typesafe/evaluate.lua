local typesafe_client = require("typesafe_client")
local typesafe_mapper = require("typesafe_mapper")
local output = require("output")
local evaluation = require("evaluation")

type ClassifyError = (http_err: any?) -> (string, string, table?)

type EvaluationResponse = {
    success: boolean,
    result: { readings: {[string]: any} },
    tokens: any,
    metadata: any
}

local evaluate_handler = {
    _client = typesafe_client,
    _mapper = typesafe_mapper
}

function evaluate_handler.handler(contract_args)
    if type(contract_args) ~= "table" then contract_args = {} end
    local err = output.errors.evaluate(contract_args)
        :classifier(evaluate_handler._mapper.classify_error :: ClassifyError)

    local input_err = evaluation.validate(contract_args.state, contract_args.questions, contract_args.model)
    if input_err then
        return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message(input_err):build()
    end

    local payload, request_map_err = evaluate_handler._mapper.map_request(contract_args)
    if not payload then
        return nil, err:kind(output.ERROR_TYPE.INVALID_REQUEST):message(tostring(request_map_err)):build()
    end

    local typesafe_response, req_err = evaluate_handler._client.request("/systemone", payload, {
        timeout = contract_args.timeout,
        retry = contract_args.retry,
    })

    if req_err then
        return nil, err:from(req_err):build()
    end

    local readings, response_map_err = evaluate_handler._mapper.map_response(typesafe_response, contract_args.questions)
    if not readings then
        return nil, err
            :kind(output.ERROR_TYPE.MODEL_ERROR)
            :message(tostring(response_map_err))
            :details(typesafe_response.metadata or {})
            :build()
    end

    local metadata = typesafe_response.metadata or {}
    metadata.model = typesafe_response.model

    local contract_response: EvaluationResponse = {
        success = true,
        result = {
            readings = readings
        },
        tokens = nil,
        metadata = metadata
    }

    local tokens = evaluate_handler._mapper.map_tokens(typesafe_response.usage)
    if tokens then
        contract_response.tokens = tokens
    end

    return contract_response
end

return evaluate_handler
