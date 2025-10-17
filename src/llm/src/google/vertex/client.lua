local client = require("google_client")
local config = require("google_config")
local json = require("json")

local vertex_client = {
    _client = client,
    _config = config
}

local PROJECT_REQUIRED_ENDPOINTS = {
    "generateContent"
}

local function build_url(base_url, contract_args)
    local url = contract_args.options.base_url or base_url

    local is_project_required = false
    if contract_args.endpoint_path and contract_args.endpoint_path ~= "" then
        for _, endpoint in ipairs(PROJECT_REQUIRED_ENDPOINTS) do
            if contract_args.endpoint_path == endpoint then
                is_project_required = true
                break
            end
        end
    end

    if is_project_required then
        local project_id = contract_args.options.project or vertex_client._config.get_project_id()
        local location = contract_args.options.location or vertex_client._config.get_vertex_location()
        url = string.format("%s/projects/%s/locations/%s", url, project_id, location)
    end

    url = url .. "/publishers/google/models"

    if contract_args.model and contract_args.model ~= "" then
        url = url .. "/" .. contract_args.model
    end
    if contract_args.endpoint_path and contract_args.endpoint_path ~= "" then
        url = url .. ":" .. contract_args.endpoint_path
    end

    return url
end

function vertex_client.request(contract_args)
    contract_args.options = contract_args.options or {}
    contract_args.options.method = contract_args.options.method or "POST"

    local token = vertex_client._config.get_oauth2_token()
    if not token then
        return {status_code = 401, message = "Google OAuth2 token is missing"}
    end

    local options = {
        headers = {
            ["Authorization"] = "Bearer " .. token.access_token
        },
        timeout = contract_args.options.timeout or vertex_client._config.get_vertex_timeout()
    }
    if contract_args.options.method == "POST" then
        options.body = json.encode(contract_args.payload or {})
    end

    local base_url = contract_args.options.base_url
    if not base_url then
        base_url, err = vertex_client._config.get_vertex_base_url(contract_args.options.location)
        if err then
            return { status_code = 401, message = err }
        end
    end

    local response, err = vertex_client._client.request(contract_args.options.method, build_url(base_url, contract_args), options)

    if err then
        return err
    end

    return response
end

return vertex_client
