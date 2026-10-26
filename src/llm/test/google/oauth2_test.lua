local test = require("test")
local oauth2 = require("google_oauth2")
local config = require("google_config")
local base64 = require("base64")
local json = require("json")
local store = require("store")
local env = require("env")

local function define_tests()
    describe("Google OAuth2 profile refresh", function()
        local get_token = oauth2.get_token
        local cache
        local function profile(email)
            config._ctx = {get = function(key)
                if key == "google_credentials" then
                    return base64.encode(json.encode({
                        client_email = email, token_uri = "https://issuer.invalid/token", private_key_id = "fixture",
                    }))
                end
            end}
        end
        before_each(function()
            cache = assert(store.get(env.get("APP_CACHE") or config.DEFAULT_CACHE_ID))
            profile("refresh-a@example.invalid")
            local key = assert(config.get_oauth2_cache_key())
            cache:delete(key)
            profile("refresh-b@example.invalid")
            key = assert(config.get_oauth2_cache_key())
            cache:delete(key)
            profile("refresh-a@example.invalid")
        end)
        after_each(function()
            oauth2.get_token = get_token
            config._ctx = nil
            cache:release()
        end)

        it("keeps reader and refresher keys aligned for independent profiles", function()
            oauth2.get_token = function()
                return {access_token = "token-" .. config.get_client_email(), expires_in = 3600}
            end
            cache:set(config.OAUTH2_TOKEN_CACHE_KEY, {access_token = "unidentified-legacy"}, 60)
            local missing, missing_err = config.get_oauth2_token()
            test.is_nil(missing)
            test.is_nil(missing_err)
            local a, a_err = oauth2.refresh_token()
            test.is_nil(a_err)
            profile("refresh-b@example.invalid")
            local b, b_err = oauth2.refresh_token()
            test.is_nil(b_err)
            test.eq(config.get_oauth2_token().access_token, b.access_token)
            profile("refresh-a@example.invalid")
            test.eq(config.get_oauth2_token().access_token, a.access_token)
            test.is_true(a.access_token ~= b.access_token)
            test.is_true(type(a.expires_at) == "number")
            cache:delete(config.OAUTH2_TOKEN_CACHE_KEY)
        end)

        it("leaves existing tokens intact when the issuer fails", function()
            oauth2.get_token = function() return {access_token = "existing-token"} end
            test.not_nil(oauth2.refresh_token())
            oauth2.get_token = function() return nil, "issuer unavailable" end
            local token, err = oauth2.refresh_token()
            test.is_nil(token)
            test.eq(err, "issuer unavailable")
            test.eq(config.get_oauth2_token().access_token, "existing-token")
        end)

        it("rejects malformed issuer responses without poisoning the cache", function()
            for _, response in ipairs({42, {}, {access_token = ""}, {access_token = "token", expires_in = 0},
                {access_token = "token", expires_in = "invalid"}, {access_token = "token", expires_in = math.huge}}) do
                oauth2.get_token = function() return response end
                local token, err = oauth2.refresh_token()
                test.is_nil(token)
                test.contains(tostring(err), "no valid access token")
                test.is_nil(config.get_oauth2_token())
            end
        end)
    end)
end

return require("test").run_cases(define_tests)
