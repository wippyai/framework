local client = require("google_client")
local config = require("google_config")
local json = require("json")

local generative_ai_client = {}

function generative_ai_client.request(contract_args)
    contract_args.options = contract_args.options or {}
    contract_args.options.method = contract_args.options.method or "POST"

    local api_key = config.get_gemini_api_key()

    if not api_key then
        return {status_code = 401, message = "Google Gemini API key is missing"}
    end

    local options = {
        headers = {
            ["x-goog-api-key"] = api_key
        },
        timeout = contract_args.options.timeout or config.get_generative_ai_timeout()
    }
    if contract_args.options.method == "POST" then
        options.body = json.encode(contract_args.payload or {})
    end

    local base_url = contract_args.options.base_url or config.get_generative_ai_base_url()
    if contract_args.model and contract_args.model ~= "" then
        base_url = base_url .. "/" .. contract_args.model
    end
    if contract_args.endpoint_path and contract_args.endpoint_path ~= "" then
        base_url = base_url .. ":" .. contract_args.endpoint_path
    end

    local response, err = client.request(contract_args.options.method, base_url, options)

    if err then
        return err
    end

    return response
end

return generative_ai_client
