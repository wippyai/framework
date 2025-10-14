local client = require("google_http_client")
local config = require("google_config")
local json = require("json")

local generative_ai_client = {}

function generative_ai_client.request(contract_args)
    contract_args.options = contract_args.options or {}

    if not contract_args.model or contract_args.model == "" then
        return nil, { status_code = 400, message = "Model is required" }
    end
    if not contract_args.endpoint_path or contract_args.endpoint_path == "" then
        return nil, {status_code = 400, message = "Endpoint path is required"}
    end

    local api_key = config.get_gemini_api_key()

    if not api_key then
        return nil, {status_code = 401, message = "Google Gemini API key is missing"}
    end

    local http_options = {
        headers = {
            ["x-goog-api-key"] = api_key
        },
        timeout = contract_args.options.timeout or config.get_generative_ai_timeout(),
        body = json.encode(contract_args.payload or {})
    }

    local base_url = contract_args.options.base_url or config.get_generative_ai_base_url()

    local response, err = client.post(
        base_url .. "/" .. contract_args.model .. ":" .. contract_args.endpoint_path,
        http_options
    )

    return response, err
end

return generative_ai_client
