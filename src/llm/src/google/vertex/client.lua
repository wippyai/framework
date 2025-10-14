local client = require("google_client")
local config = require("google_config")
local json = require("json")

local vertex_client = {}

function vertex_client.request(contract_args)
    contract_args.options = contract_args.options or {}

    if not contract_args.model or contract_args.model == "" then
        return nil, { status_code = 400, message = "Model is required" }
    end
    if not contract_args.endpoint_path or contract_args.endpoint_path == "" then
        return nil, {status_code = 400, message = "Endpoint path is required"}
    end

    local token = config.get_oauth2_token()
    if not token then
        return nil, {status_code = 401, message = "Google OAuth2 token is missing"}
    end

    local http_options = {
        headers = {
            ["Authorization"] = "Bearer " .. token.access_token
        },
        timeout = contract_args.options.timeout or config.get_vertex_timeout(),
        body = json.encode(contract_args.payload or {})
    }

    local base_url = contract_args.options.base_url
    if not base_url then
        base_url, err = config.get_vertex_base_url(contract_args.options.project, contract_args.options.location)
        if err then
            return nil, {status_code = 401, message = err}
        end
    end

    local response, err = client.post(
        base_url .. "/" .. contract_args.model .. ":" .. contract_args.endpoint_path,
        http_options
    )

    return response, err
end

return vertex_client
