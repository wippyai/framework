local test = require("test")
local http_client = require("http_client")
local registry = require("registry")

local TITLE_ID = "wippy.facade:app_title"

local function set_title(value: string)
    local changes = registry.snapshot():changes()
    changes:update({ id = TITLE_ID, kind = "ns.requirement", data = { default = value } })
    local _, err = changes:apply()
    test.is_nil(err)
end

local function fetch(path: string): string
    local gateway = registry.get("app:gateway")
    test.not_nil(gateway)
    local response, err = http_client.get("http://127.0.0.1" .. gateway.data.addr .. path, { timeout = 5 })
    test.is_nil(err)
    test.eq(response.status_code, 200)
    return response.body or ""
end

local function fetch_shell(): string
    return fetch("/")
end

local function define_tests()
    test.describe("facade shell title", function()
        local saved = ""

        test.before_each(function()
            saved = registry.get(TITLE_ID).data.default
        end)

        test.after_each(function()
            set_title(saved)
        end)

        test.it("uses the app title while the shell loads", function()
            set_title("Kickside")
            test.contains(fetch_shell(), "<title>Kickside</title>")
        end)

        test.it("escapes the app title", function()
            set_title("A & <B>")
            test.contains(fetch_shell(), "<title>A &amp; &lt;B&gt;</title>")
        end)

        test.it("keeps Wippy when the app title is empty", function()
            set_title("")
            test.contains(fetch_shell(), "<title>Wippy</title>")
        end)

        test.it("loads the title script on deep links", function()
            test.contains(fetch("/some/deep/link"), '<script src="/api/public/facade/title.js"></script>')
        end)

        test.it("sets the app title from the title script", function()
            set_title("Kickside")
            test.contains(fetch("/api/public/facade/title.js"), 'document.title = "Kickside";')
        end)

        test.it("keeps the page title when the app title is empty", function()
            set_title("")
            test.is_nil(fetch("/api/public/facade/title.js"):match("document%.title"))
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options)
    return run_cases(options)
end

return { run = run }
