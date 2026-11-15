local test = require("test")
local json = require("json")
local output = require("output")
local transport = require("transport")

local providers = {
    { name = "openai", client = require("openai_client"), mapper = require("openai_mapper") },
    { name = "openai_compat", client = require("openai_compat_client"), mapper = require("openai_compat_mapper") },
    { name = "claude", client = require("claude_client"), mapper = require("claude_mapper") },
    { name = "typesafe", client = require("typesafe_client"), mapper = require("typesafe_mapper") },
    { name = "bedrock", client = require("bedrock_client"), mapper = require("bedrock_mapper") },
    { name = "google", client = require("google_client"), mapper = require("google_mapper") },
}

local key = 'echo-timeout-key."\\ /+fixture'
local header_secret = "echo-header-%value"
local bearer = "echo-bearer-fixture"
local encoded_key = json.encode(key):sub(2, -2)
local url_key = key:gsub("([^%w%-._~])", function(char) return string.format("%%%02X", string.byte(char)) end)
local diagnostic = "Denied " .. key .. " / " .. header_secret .. " / Bearer " .. bearer
local sanitized = "Denied [REDACTED] / [REDACTED] / [REDACTED]"

local function assert_clean(value)
    if type(value) == "userdata" then
        assert_clean(value:message())
        assert_clean(value:details() or {})
        return
    end
    if type(value) == "table" then
        for name, nested in pairs(value) do
            assert_clean(name)
            assert_clean(nested)
        end
        return
    end
    if type(value) ~= "string" then return end
    for _, secret in ipairs({ key, encoded_key, url_key, url_key:lower(), header_secret, bearer }) do
        test.is_nil(value:find(secret, 1, true), "credential remains in diagnostic")
    end
end

local function upstream_error()
    return {
        message = diagnostic,
        type = "authentication_error",
        code = "invalid_api_key",
        param = { nested = { message = diagnostic, [key] = header_secret }, retained = 7, encoded = encoded_key .. " / " .. url_key },
        metadata = { raw = json.encode({ message = diagnostic }), provider_name = header_secret },
    }
end

local function stream_once(data, read_error)
    local consumed = false
    return { read = function()
        if consumed then return nil end
        consumed = true
        return data, read_error
    end }
end

local function bedrock_frame(body)
    local function header(name, value)
        return string.char(#name) .. name .. string.char(7) .. string.pack(">I2", #value) .. value
    end
    local headers = header(":message-type", "exception") .. header(":exception-type", "validationException")
    local payload = json.encode(body)
    return string.pack(">I4I4I4", 16 + #headers + #payload, #headers, 0)
        .. headers .. payload .. string.pack(">I4", 0)
end

return test.run_cases(function()
    for _, provider in ipairs(providers) do
        describe(provider.name .. " credential error redaction", function()
            local client: any = provider.client
            local saved = {}
            local context
            local collect_secrets
            local secret_collections
            before_each(function()
                secret_collections = 0
                collect_secrets = transport.request_secrets
                transport.request_secrets = function(...)
                    secret_collections = secret_collections + 1
                    return collect_secrets(...)
                end
                for _, name in ipairs({ "_ctx", "_env", "_http_client", "_credentials", "_sigv4" }) do
                    saved[name] = client[name]
                end
                context = { api_key = key, headers = {
                    Authorization = "Bearer " .. key, ["X-Custom-Secret"] = header_secret,
                    ["X-Other-Secret"] = "Bearer " .. bearer,
                } }
                client._ctx = { all = function() return context end }
                client._env = { get = function() return nil end }
                if provider.name == "bedrock" then
                    client._credentials = { resolve = function()
                        return { access_key = key, secret_key = "unused-signing-key", session_token = bearer }
                    end }
                    client._sigv4 = { sign_request = function(request)
                        request.headers.Authorization = "Bearer " .. bearer
                        request.headers["x-amz-security-token"] = key
                        return request.headers
                    end }
                end
            end)
            after_each(function()
                transport.request_secrets = collect_secrets
                for _, name in ipairs({ "_ctx", "_env", "_http_client", "_credentials", "_sigv4" }) do
                    client[name] = saved[name]
                end
            end)

            local function request(streaming: boolean): (any, any)
                if provider.name == "google" then
                    return client.request("POST", "https://api.example.test/generate", {
                        headers = { ["x-goog-api-key"] = key, Authorization = "Bearer " .. bearer,
                            ["X-Custom-Secret"] = header_secret },
                        stream = streaming, stream_reply_to = "fixture-pid", stream_topic = "fixture-errors",
                    })
                elseif provider.name == "bedrock" then
                    if streaming then
                        local converse_stream = client.converse_stream
                        assert(converse_stream)
                        return converse_stream("model", {})
                    end
                    local converse = client.converse
                    assert(converse)
                    return converse("model", {})
                end
                return client.request("/generate", {}, { stream = streaming })
            end

            local function build_error(err)
                return output.errors.generate():classifier(provider.mapper.classify_error):from(err):build()
            end

            it("redacts HTTP messages and nested details before logging or returning", function()
                client._http_client = { post = function()
                    return { status_code = 401, body = json.encode({ error = upstream_error(),
                        detail = upstream_error(), message = diagnostic }),
                        headers = { ["X-Request-Id"] = header_secret, ["request-id"] = header_secret,
                            ["x-amzn-requestid"] = header_secret, ["x-typesafe-request-id"] = header_secret } }
                end }
                for _, streaming in ipairs({ false, true }) do
                    local response, err = request(streaming)
                    test.is_nil(response)
                    test.eq(err.status_code, 401)
                    test.eq(err.message, sanitized)
                    assert_clean(err)
                    test.ok(secret_collections > 0)
                    local built = build_error(err)
                    assert_clean(built:message())
                    assert_clean(built:details())
                    test.eq(built:kind(), errors.PERMISSION_DENIED)
                    test.is_false(built:retryable())
                end
            end)

            it("preserves successful provider content", function()
                client._http_client = { post = function()
                    return { status_code = 200, headers = {}, body = json.encode({ message = diagnostic }) }
                end }
                local response, err = request(false)
                test.is_nil(err)
                test.eq(response.message, diagnostic)
                test.eq(secret_collections, 0)
            end)

            if provider.name ~= "typesafe" then
                it("keeps successful streams free of secret collection and public credential state", function()
                    mock("process.send", function() return true end)
                    client._http_client = { post = function()
                        return { status_code = 200, headers = {}, stream = stream_once(nil) }
                    end }
                    local response, err = request(true)
                    test.is_nil(err)
                    test.eq(secret_collections, 0)
                    if provider.name ~= "google" then
                        for name in pairs(response) do
                            test.ok(name == "stream" or name == "status_code" or name == "headers" or name == "metadata")
                        end
                        local process_stream = provider.name == "bedrock" and client.process_converse_stream or client.process_stream
                        assert(process_stream)
                        process_stream(response, {})
                        test.eq(secret_collections, 0)
                    end
                end)
            end

            it("redacts connection errors without changing their shape", function()
                client._http_client = { post = function() return nil, diagnostic end }
                local response, err = request(false)
                test.is_nil(response)
                test.eq(err.status_code, 0)
                test.eq(err.message, "Connection failed: " .. sanitized)
                assert_clean(err)
                assert_clean(build_error(err):message())
            end)

            if provider.name ~= "typesafe" then
                for _, mode in ipairs({ "event", "string", "native" }) do
                    local read_failure = mode ~= "event"
                    it("redacts " .. mode .. " stream failures before callbacks and chunks", function()
                        local read_error = mode == "native" and errors.new({ message = diagnostic,
                            kind = errors.UNAVAILABLE, retryable = true, details = { nested = { message = diagnostic } } }) or diagnostic
                        local chunks = {}
                        mock("process.send", function(_, _, chunk)
                            chunks[#chunks + 1] = chunk
                            return true
                        end)
                        local data
                        if provider.name == "bedrock" then data = bedrock_frame(upstream_error())
                        elseif provider.name == "claude" then
                            data = "event: error\ndata: " .. json.encode({ type = "error", error = upstream_error() }) .. "\n\n"
                        else
                            data = "data: " .. json.encode({ type = "error", error = upstream_error() }) .. "\n\n"
                        end
                        client._http_client = { post = function()
                            local stream = stream_once(read_failure and nil or data, read_failure and read_error or nil)
                            if provider.name == "google" then
                                local reads = 0
                                stream = { read = function()
                                    reads = reads + 1
                                    if reads == 1 then
                                        return 'data: {"candidates":[{"content":{"parts":[{"text":"prefix content"}]}}]}\n\n'
                                    elseif reads == 2 then
                                        return read_failure and nil or data, read_failure and read_error or nil
                                    end
                                    return nil
                                end }
                            end
                            return { status_code = 200, headers = {}, stream = stream }
                        end }
                        local response, err = request(true)
                        if provider.name ~= "google" then
                            test.is_nil(err)
                            test.is_nil(response._request_secrets)
                            test.eq(secret_collections, 0)
                            -- Stream diagnostics belong to the dispatched request even if configuration changes.
                            context = { api_key = "next-request-key", headers = {} }
                            local streamer = output.streamer("fixture-pid", "fixture-errors")
                            assert(streamer)
                            local callbacks = { on_error = function(info)
                                assert_clean(info)
                                local normalized = info
                                if type(info) == "userdata" then normalized = { message = info:message() }
                                elseif type(info) == "string" then normalized = { message = info }
                                elseif type(info.message) == "userdata" then normalized = { message = tostring(info.message) } end
                                local built = build_error(normalized)
                                streamer:send_error(tostring(built:kind()), built:message())
                            end }
                            local process_stream = provider.name == "bedrock" and client.process_converse_stream or client.process_stream
                            assert(process_stream)
                            local content, stream_err, result = process_stream(response, callbacks)
                            test.is_nil(content)
                            if mode == "native" and provider.name ~= "bedrock" then
                                test.eq(type(stream_err), type(read_error))
                                test.eq(stream_err:kind(), read_error:kind())
                                test.eq(stream_err:retryable(), read_error:retryable())
                            else
                                test.eq(type(stream_err), "string")
                            end
                            assert_clean(stream_err)
                            if result then assert_clean(result) end
                        else
                            test.is_nil(response)
                            assert_clean(err)
                            assert_clean(build_error(err):message())
                        end
                        test.eq(#chunks, provider.name == "google" and 2 or 1)
                        assert_clean(chunks)
                    end)
                end
            end
        end)
    end
end)
