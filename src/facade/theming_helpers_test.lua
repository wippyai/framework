local test = require("test")
local helpers = require("theming_helpers")

local function define_tests()
    test.describe("theming_helpers", function()

        -- ------------------------------------------------------------------ --
        test.describe("build_variables_css", function()

            test.it("returns empty string for empty vars", function()
                test.eq(helpers.build_variables_css({}), "")
            end)

            test.it("generates :root block for flat string vars", function()
                local css = helpers.build_variables_css({ ["--p-primary"] = "#6366f1" })
                test.ok(css:find(":root {") ~= nil)
                test.ok(css:find("--p-primary: #6366f1;") ~= nil)
            end)

            test.it("prepends -- to keys that lack the prefix", function()
                local css = helpers.build_variables_css({ ["p-primary"] = "#6366f1" })
                test.ok(css:find("--p-primary: #6366f1;") ~= nil)
                -- original key without -- must not appear
                test.is_true(css:find("[^-]p%-primary") == nil)
            end)

            test.it("generates @media dark block for @dark key", function()
                local css = helpers.build_variables_css({
                    ["--p-primary"] = "#6366f1",
                    ["@dark"] = { ["--p-primary"] = "#818cf8" },
                })
                test.ok(css:find("prefers%-color%-scheme: dark") ~= nil)
                test.ok(css:find("--p-primary: #818cf8;") ~= nil)
            end)

            test.it("generates @media light block for @light key", function()
                local css = helpers.build_variables_css({
                    ["@light"] = { ["--bg"] = "#ffffff" },
                })
                test.ok(css:find("prefers%-color%-scheme: light") ~= nil)
                test.ok(css:find("--bg: #ffffff;") ~= nil)
            end)

            test.it("emits :root block before media blocks", function()
                local css = helpers.build_variables_css({
                    ["--a"] = "1",
                    ["@dark"] = { ["--a"] = "2" },
                })
                local root_pos = css:find(":root {")
                local media_pos = css:find("@media")
                test.not_nil(root_pos)
                test.not_nil(media_pos)
                test.is_true((root_pos or 0) < (media_pos or 0))
            end)

            test.it("ignores non-string, non-table values at top level", function()
                local vars: {[string]: any} = { ["--x"] = "ok", ["--y"] = 42, ["--z"] = true }
                local css = helpers.build_variables_css(vars)
                test.ok(css:find("--x: ok;") ~= nil)
                test.ok(css:find("--y") == nil)
                test.ok(css:find("--z") == nil)
            end)

            test.it("handles multiple root vars", function()
                local css = helpers.build_variables_css({
                    ["--a"] = "1",
                    ["--b"] = "2",
                })
                test.ok(css:find("--a: 1;") ~= nil)
                test.ok(css:find("--b: 2;") ~= nil)
            end)

            test.it("returns empty string for nil input", function()
                local vars: any = nil
                test.eq(helpers.build_variables_css(vars), "")
            end)

            test.it("prepends -- to key inside @dark media block", function()
                local css = helpers.build_variables_css({
                    ["@dark"] = { ["p-accent"] = "#818cf8" },
                })
                test.ok(css:find("prefers%-color%-scheme: dark") ~= nil)
                test.ok(css:find("--p%-accent: #818cf8;") ~= nil)
            end)

            test.it("ignores non-string values inside @dark block", function()
                local vars: {[string]: any} = {
                    ["@dark"] = { ["--a"] = "1", ["--b"] = 99 },
                }
                local css = helpers.build_variables_css(vars)
                test.ok(css:find("--a: 1;") ~= nil)
                test.ok(css:find("--b") == nil)
            end)

            test.it("generates both @dark and @light blocks when both present", function()
                local css = helpers.build_variables_css({
                    ["@dark"] = { ["--bg"] = "#000" },
                    ["@light"] = { ["--bg"] = "#fff" },
                })
                test.ok(css:find("prefers%-color%-scheme: dark") ~= nil)
                test.ok(css:find("prefers%-color%-scheme: light") ~= nil)
            end)

        end)

        -- ------------------------------------------------------------------ --
        test.describe("resolve_css", function()

            test.it("returns inline CSS unchanged", function()
                local css = "@import url('https://fonts.example.com');"
                test.eq(helpers.resolve_css(css, nil), css)
            end)

            test.it("returns empty string for file:// ref when file_sys is nil", function()
                test.eq(helpers.resolve_css("file://brand.css", nil), "")
            end)

            test.it("returns empty string for non-existent file even when file_sys is set", function()
                -- We cannot create a real fs.directory in unit tests, so we test
                -- the graceful-failure path via a fake FS object whose readfile raises.
                local fake_fs = {
                    readfile = function()
                        error("file not found")
                    end
                }
                test.eq(helpers.resolve_css("file://missing.css", fake_fs), "")
            end)

            test.it("returns file content when file_sys has the file", function()
                local fake_fs = {
                    readfile = function()
                        return "body { color: red; }"
                    end
                }
                test.eq(helpers.resolve_css("file://brand.css", fake_fs), "body { color: red; }")
            end)

            test.it("returns empty string when file_sys readfile returns nil", function()
                local fake_fs = {
                    readfile = function()
                        return nil
                    end
                }
                test.eq(helpers.resolve_css("file://brand.css", fake_fs), "")
            end)

            test.it("resolves fs:// ref and strips the scheme prefix", function()
                local got_path: string? = nil
                local fake_fs = {
                    readfile = function(_self, path)
                        got_path = path
                        return ":root { color: blue; }"
                    end,
                }
                test.eq(helpers.resolve_css("fs://custom-css.facade.css", fake_fs), ":root { color: blue; }")
                test.eq(got_path, "custom-css.facade.css")
            end)

            test.it("resolves file:// ref and strips the scheme prefix", function()
                -- guards the sub(8) offset for file:// at the resolver level
                -- (the fs:// path uses sub(6); a divergence here would slip through
                -- without this assertion)
                local got_path: string? = nil
                local fake_fs = {
                    readfile = function(_self, path)
                        got_path = path
                        return "body { color: green; }"
                    end,
                }
                test.eq(helpers.resolve_css("file://brand.css", fake_fs), "body { color: green; }")
                test.eq(got_path, "brand.css")
            end)

        end)

        -- ------------------------------------------------------------------ --
        test.describe("resolve_json", function()

            test.it("decodes inline JSON string", function()
                local result = helpers.resolve_json('{"--p-primary":"#6366f1"}', nil)
                test.eq(result["--p-primary"], "#6366f1")
            end)

            test.it("returns empty table for empty string", function()
                local result = helpers.resolve_json("", nil)
                test.eq(next(result), nil)
            end)

            test.it("returns empty table for invalid JSON", function()
                local result = helpers.resolve_json("not-json", nil)
                test.eq(next(result), nil)
            end)

            test.it("returns empty table for file:// ref when file_sys is nil", function()
                local result = helpers.resolve_json("file://vars.json", nil)
                test.eq(next(result), nil)
            end)

            test.it("returns empty table when file_sys readfile raises", function()
                local fake_fs = {
                    readfile = function()
                        error("file not found")
                    end
                }
                local result = helpers.resolve_json("file://vars.json", fake_fs)
                test.eq(next(result), nil)
            end)

            test.it("parses JSON from file when file_sys has the file", function()
                local fake_fs = {
                    readfile = function()
                        return '{"--p-primary":"#818cf8"}'
                    end
                }
                local result = helpers.resolve_json("file://vars.json", fake_fs)
                test.eq(result["--p-primary"], "#818cf8")
            end)

            test.it("preserves @dark nested object from inline JSON", function()
                local result = helpers.resolve_json(
                    '{"--x":"1","@dark":{"--x":"2"}}',
                    nil
                )
                test.eq(result["--x"], "1")
                local dark = result["@dark"]
                test.not_nil(dark)
                test.eq(dark["--x"], "2")
            end)

            test.it("parses JSON from fs:// ref and strips the scheme prefix", function()
                local got_path: string? = nil
                local fake_fs = {
                    readfile = function(_self, path)
                        got_path = path
                        return '{"--p-primary":"#22d3ee"}'
                    end,
                }
                local result = helpers.resolve_json("fs://css-variables.facade.json", fake_fs)
                test.eq(result["--p-primary"], "#22d3ee")
                test.eq(got_path, "css-variables.facade.json")
            end)

        end)

        -- ------------------------------------------------------------------ --
        test.describe("file_ref_path", function()

            test.it("strips the fs:// prefix (canonical YAML scheme)", function()
                test.eq(helpers.file_ref_path("fs://custom-css.facade.css"), "custom-css.facade.css")
            end)

            test.it("strips the file:// prefix (non-YAML scheme)", function()
                test.eq(helpers.file_ref_path("file://vars.json"), "vars.json")
            end)

            test.it("returns nil for an inline value", function()
                test.is_nil(helpers.file_ref_path("body { color: red; }"))
            end)

        end)

        -- ------------------------------------------------------------------ --
        test.describe("get_fs", function()

            test.it("returns nil for empty entry_id", function()
                test.is_nil(helpers.get_fs(""))
            end)

            test.it("returns nil for non-existent entry (does not raise)", function()
                -- This entry ID doesn't exist in the registry; get_fs must not raise.
                local result = helpers.get_fs("wippy.facade:nonexistent_fs_entry")
                test.is_nil(result)
            end)

        end)

    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options)
    return run_cases(options)
end

return { run = run }
