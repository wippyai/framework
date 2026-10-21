local test = require("test")
local fragment_html = require("fragment_html")

local BASE = "http://app.test/app/app/demo/"

local function starts(tokens)
    local out = {}
    for _, t in ipairs(tokens) do
        if t.type == "start" or t.type == "end" then
            table.insert(out, (t.type == "end" and "/" or "") .. t.name)
        else
            table.insert(out, "#" .. t.type)
        end
    end
    return table.concat(out, " ")
end

local function names(html)
    return starts(fragment_html.tokenize(html))
end

local function first_start(html, name)
    for _, t in ipairs(fragment_html.tokenize(html)) do
        if t.type == "start" and t.name == name then
            return t
        end
    end
    return nil
end

local function contains(text, part)
    return text:find(part, 1, true) ~= nil
end

local function transform(html, head_prepend)
    return fragment_html.transform_document(html, { base_url = BASE, head_prepend = head_prepend })
end

local function define_tests()
    test.describe("fragment html tokenizer", function()
        test.it("reads every attribute quoting form", function()
            local tag = first_start('<a b="1" c=\'2\' d=3 e f = "4" G="5">', "a")
            local got = {}
            for _, a in ipairs(tag.attrs) do
                table.insert(got, a.name .. "=" .. tostring(a.value))
            end
            test.eq(table.concat(got, ","), "b=1,c=2,d=3,e=nil,f=4,g=5")
        end)

        test.it("lowercases tag names and handles self-closing and missing whitespace", function()
            test.eq(names('<SCRIPT TYPE="x"></SCRIPT><img src=x /><a b="1"c="2">'), "script /script img a")
            test.eq(first_start('<img src=x />', "img").self_closing, true)
            test.eq(#first_start('<a b="1"c="2">', "a").attrs, 2)
        end)

        test.it("treats comments, bogus comments and stray < as non-tags", function()
            test.eq(names('<!-- <script type="importmap">{}</script> -->x<p>'), "#comment p")
            test.eq(names('<!--><p>'), "#comment p")
            test.eq(names('<!---><p>'), "#comment p")
            test.eq(names('<!-- a --!><p>'), "#comment p")
            test.eq(names('<?xml version="1.0"?><p>'), "#comment p")
            test.eq(names('</ x><p>'), "#comment p")
            test.eq(names('</><p>'), "p")
            test.eq(names('<p>a < b</p>'), "p /p")
            test.eq(names('<!DOCTYPE html><p>'), "#doctype p")
        end)

        test.it("does not see tags inside script, style or textarea content", function()
            test.eq(names('<script>if (a<b) document.write("</div>")</script><p>'), "script /script p")
            test.eq(names('<script>var s = "</scr" + "ipt>"</script><p>'), "script /script p")
            test.eq(names('<script>x</SCRIPT ><p>'), "script /script p")
            test.eq(names('<script>x</scripts></script><p>'), "script /script p")
            test.eq(names('<style>a</p>{}</style><p>'), "style /style p")
            test.eq(names('<textarea><script type="importmap">{}</script></textarea><p>'), "textarea /textarea p")
        end)

        test.it("follows the script escape and double-escape states", function()
            local html = '<script><!--<script>x</script>y--></script><p>'
            test.eq(names(html), "script /script p")
            local tag = first_start(html, "script")
            test.eq(html:sub(tag.content_s, tag.content_e), "<!--<script>x</script>y-->")
            test.eq(names('<script><!--</script><p>'), "script /script p")
        end)

        test.it("stops at a tag cut off by the end of input and keeps unclosed raw text", function()
            test.eq(names('<p>x<img src="a'), "p")
            local html = '<script>never closed <p>'
            test.eq(names(html), "script")
            local tag = first_start(html, "script")
            test.eq(html:sub(tag.content_s, tag.content_e), "never closed <p>")
        end)
    end)

    test.describe("fragment html import maps", function()
        test.it("detects import maps in every quoting, case and entity form", function()
            local variants = {
                '<script type="importmap">{}</script>',
                "<script type='importmap'>{}</script>",
                "<script type=importmap>{}</script>",
                '<SCRIPT TYPE="ImportMap">{}</SCRIPT>',
                '<script type=" importmap ">{}</script>',
                '<script type="&#x69;mportmap">{}</script>',
                '<script nonce="n" id="m" type="importmap" data-x>{}</script>',
            }
            for _, html in ipairs(variants) do
                test.eq(fragment_html.is_import_map(first_start(html, "script")), true)
            end
        end)

        test.it("ignores scripts that are not import maps", function()
            local variants = {
                '<script type="importmapx">{}</script>',
                '<script type="module">{}</script>',
                '<script data-type="importmap">{}</script>',
                '<script type="module" type="importmap">{}</script>',
            }
            for _, html in ipairs(variants) do
                test.eq(fragment_html.is_import_map(first_start(html, "script")), false)
            end
            test.eq(fragment_html.page_import_map('<!-- <script type="importmap">{"a":1}</script> -->'), nil)
            test.eq(fragment_html.page_import_map('<textarea><script type="importmap">{}</script></textarea>'), nil)
        end)

        test.it("returns the first import map as raw text", function()
            local html = '<head><script type="importmap">{"imports":{"a":"./a.js"}}</script>'
                .. '<script type="importmap">{"imports":{"b":"./b.js"}}</script></head>'
            test.eq(fragment_html.page_import_map(html), '{"imports":{"a":"./a.js"}}')
            test.eq(fragment_html.page_import_map("<p>none</p>"), nil)
            test.eq(fragment_html.page_import_map('<script type="importmap"></script>'), nil)
            test.eq(fragment_html.page_import_map('<script type="importmap">  </script>'), "  ")
        end)

        test.it("removes every import map and the dev-proxy placeholder", function()
            local html = '<head><script type="importmap">{"imports":{"a":"./a.js"}}</script>'
                .. "<script TYPE='ImportMap' nonce=x>{}</script>"
                .. '<script data-role="@wippy/scripts" src="https://cdn.test/dev-proxy.js"></script>'
                .. '<script DATA-ROLE=@wippy/scripts></script>'
                .. '<script type="module" src="https://cdn.test/app.js"></script></head>'
            local out, page_map = transform(html)
            test.eq(page_map, '{"imports":{"a":"./a.js"}}')
            test.eq(contains(out:lower(), "importmap"), false)
            test.eq(contains(out, "@wippy/scripts"), false)
            test.eq(contains(out, '<script type="module" src="https://cdn.test/app.js"></script>'), true)
        end)
    end)

    test.describe("fragment html transform", function()
        test.it("makes relative resource URLs absolute in every quoting form", function()
            local out = transform('<link rel=stylesheet href="./a.css"><link href=\'./b.css\'><link href=./c.css>'
                .. '<script src="../lib/x.js"></script><img src="d.png"><img src="/root.png">'
                .. '<link href="./e.css?x=1&amp;y=2">')
            test.eq(contains(out, 'href="http://app.test/app/app/demo/a.css"'), true)
            test.eq(contains(out, 'href="http://app.test/app/app/demo/b.css"'), true)
            test.eq(contains(out, 'href="http://app.test/app/app/demo/c.css"'), true)
            test.eq(contains(out, 'src="http://app.test/app/app/lib/x.js"'), true)
            test.eq(contains(out, 'src="http://app.test/app/app/demo/d.png"'), true)
            test.eq(contains(out, 'src="http://app.test/root.png"'), true)
            test.eq(contains(out, 'href="http://app.test/app/app/demo/e.css?x=1&amp;y=2"'), true)
        end)

        test.it("leaves absolute, fragment, data and navigation URLs alone", function()
            local html = '<img src="https://cdn.test/x.png"><img src="//cdn.test/y.png"><img src="data:image/png;base64,AA">'
                .. '<a href="#top">t</a><a href="page">p</a><a href="/root">r</a>'
            test.eq(transform(html), html)
            local out = transform('<a href="./page">p</a>')
            test.eq(contains(out, 'href="http://app.test/app/app/demo/page"'), true)
        end)

        test.it("does not edit text inside scripts, comments or duplicate attributes", function()
            local html = '<script>el.innerHTML = \'<link href="./x.css"><html>\'</script>'
                .. '<!-- <link href="./y.css"> --><img src="https://cdn.test/a.png" src="./b.png">'
            test.eq(transform(html), html)
        end)

        test.it("inserts the head content after <head>, never after <header>", function()
            local out = transform('<!doctype html><html lang="en"><head data-x><title>t</title></head><body></body></html>', "<!--HOST-->")
            test.eq(contains(out, "<wf-head data-x><!--HOST--><title>"), true)
            out = transform('<html><body><header>h</header></body></html>', "<!--HOST-->")
            test.eq(contains(out, "<wf-html><!--HOST--><wf-body><header>"), true)
            out = transform('<!doctype html><p>x</p>', "<!--HOST-->")
            test.eq(out, "<!doctype html><!--HOST--><p>x</p>")
            out = transform('<p>x</p>', "<!--HOST-->")
            test.eq(out, "<!--HOST--><p>x</p>")
        end)

        test.it("renames only the real html, head and body tags", function()
            local out = transform('<HTML lang="en"><Head ><TITLE>t</TITLE></Head><BODY class="b"><header></header>'
                .. '<script>"<body>"</script><!-- <head> --></BODY></HTML>')
            test.eq(out, '<wf-html lang="en"><wf-head ><TITLE>t</TITLE></wf-head><wf-body class="b"><header></header>'
                .. '<script>"<body>"</script><!-- <head> --></wf-body></wf-html>')
        end)

        test.it("returns untouched markup byte for byte", function()
            local html = "<div class=x data-y='1'>caf\195\169 &amp; co < 3 > 2</div><p>a<br/>b</p>"
            test.eq(transform(html), html)
        end)

        test.it("handles a built view.page document", function()
            local html = '<!DOCTYPE html>\n<html lang="en">\n<head>\n'
                .. '    <script type="application/json" data-role="@wippy/package">{"name":"@wippy/demo"}</script>\n'
                .. '    <meta charset="UTF-8">\n'
                .. '    <script\n            src="https://web-host.wippy.ai/webcomponents-1.0.66/dev-proxy.js"\n'
                .. '            data-role="@wippy/scripts"\n    ></script>\n'
                .. '    <script type="importmap">\n    {\n        "imports": { "vue": "https://esm.sh/vue@3" }\n    }\n    </script>\n'
                .. '  <script type="module" crossorigin src="./assets/app-1.js"></script>\n'
                .. '  <link rel="stylesheet" crossorigin href="./style-1.css">\n'
                .. '</head>\n<body>\n    <div id="app"></div>\n</body>\n</html>'
            local out, page_map = transform(html, "<link data-role=host>")
            test.eq(contains(page_map, '"vue": "https://esm.sh/vue@3"'), true)
            test.eq(contains(out, "dev-proxy.js"), false)
            test.eq(contains(out, '"importmap"'), false)
            test.eq(contains(out, '<script type="application/json" data-role="@wippy/package">'), true)
            test.eq(contains(out, 'src="http://app.test/app/app/demo/assets/app-1.js"'), true)
            test.eq(contains(out, 'href="http://app.test/app/app/demo/style-1.css"'), true)
            test.eq(contains(out, "<wf-head><link data-role=host>\n"), true)
            test.eq(contains(out, "</wf-body>\n</wf-html>"), true)
        end)
    end)

    test.describe("fragment html helpers", function()
        test.it("resolves references like a browser with a base URL", function()
            local cases = {
                { "./a.css", "http://app.test/app/app/demo/a.css" },
                { "a.css", "http://app.test/app/app/demo/a.css" },
                { "../a.css", "http://app.test/app/app/a.css" },
                { "../../../../a.css", "http://app.test/a.css" },
                { "./x/../y/./z.js?q=1#h", "http://app.test/app/app/demo/y/z.js?q=1#h" },
                { "/root.css", "http://app.test/root.css" },
                { "?v=2", "http://app.test/app/app/demo/?v=2" },
                { "  ./a.css  ", "http://app.test/app/app/demo/a.css" },
            }
            for _, c in ipairs(cases) do
                test.eq(fragment_html.resolve_url(BASE, c[1]), c[2])
            end
            for _, ref in ipairs({ "https://x.test/a", "//x.test/a", "#h", "", "data:,x", "mailto:a@b.c" }) do
                test.eq(fragment_html.resolve_url(BASE, ref), nil)
            end
        end)

        test.it("decodes numeric and basic named character references", function()
            test.eq(fragment_html.decode_attribute("&#x69;mport&#109;ap"), "importmap")
            test.eq(fragment_html.decode_attribute("a&amp;b&lt;&gt;&quot;&apos;"), "a&b<>\"'")
            test.eq(fragment_html.decode_attribute("&#233;"), "\195\169")
            test.eq(fragment_html.decode_attribute("&unknown; &amp no-semicolon &#;"), "&unknown; & no-semicolon &#;")
        end)

        test.it("decodes character references the way the tokenizer does in attributes", function()
            local cases = {
                { "&#105mportmap", "importmap" }, -- numeric without `;`
                { "&#000000000000105;mportmap", "importmap" },
                { "&Tab;importmap", "\timportmap" },
                { "&AMP;&LT;&GT;&QUOT;", "&<>\"" },
                { "a&ampx", "a&ampx" }, -- a letter follows a legacy reference
                { "a&amp=x", "a&amp=x" }, -- `=` follows a legacy reference
                { "&# 105;", "&# 105;" },
                { "&#+105;", "&#+105;" },
                { "&#x;", "&#x;" },
                { "&#0;", "\239\191\189" },
                { "&#x110000;", "\239\191\189" },
                { "&#xD800;", "\239\191\189" },
            }
            for _, c in ipairs(cases) do
                test.eq(fragment_html.decode_attribute(c[1]), c[2])
            end
        end)

        test.it("resolves dot segments, backslashes and control characters like the URL standard", function()
            local cases = {
                { "%2e/../a.css", "http://app.test/app/app/a.css" },
                { "x/%2E%2e/a.css", "http://app.test/app/app/demo/a.css" },
                { "..\\a.css", "http://app.test/app/app/a.css" },
                { "./a.css?x=\\y", "http://app.test/app/app/demo/a.css?x=\\y" },
                { "\t./a\n.css\r", "http://app.test/app/app/demo/a.css" },
                { "http:x.css", "http://app.test/app/app/demo/x.css" },
            }
            for _, c in ipairs(cases) do
                test.eq(fragment_html.resolve_url(BASE, c[1]), c[2])
            end
            for _, ref in ipairs({ "\\\\cdn.test\\a.css", "ht\ntp://x.test/a.css", "https:x.css", "http:/x.test/a", "http:" }) do
                test.eq(fragment_html.resolve_url(BASE, ref), nil)
            end
        end)
    end)

    test.describe("fragment html robustness", function()
        test.it("joins large outputs without overflowing", function()
            local out = transform(string.rep('<img src="x.png">', 20000))
            local count, pos = 0, 1
            while true do
                local s = out:find('src="http://app.test/app/app/demo/x.png"', pos, true)
                if not s then
                    break
                end
                count = count + 1
                pos = s + 1
            end
            test.eq(count, 20000)
            local maps = string.rep('<script type="importmap">{}</script>', 20000)
            test.eq(transform(maps .. "<p>"), "<p>")
        end)

        test.it("handles very long attribute values", function()
            local long = string.rep("a", 40000)
            test.eq(fragment_html.decode_attribute(long .. "&amp;"), long .. "&")
            local out = transform('<link href="./' .. long .. '.css?x=1&amp;y=2">')
            test.eq(out, '<link href="http://app.test/app/app/demo/' .. long .. '.css?x=1&amp;y=2">')
            local tag = '<script type="' .. long .. '&amp;">{}</script>'
            test.eq(fragment_html.page_import_map(tag), nil)
        end)

        test.it("rewrites the first of many attributes in one tag", function()
            local parts = {}
            for k = 1, 4000 do
                parts[k] = "a" .. k .. '="' .. k .. '"'
            end
            local out = transform("<img " .. table.concat(parts, " ") .. ' src="x.png" src="y.png">')
            test.eq(contains(out, 'src="http://app.test/app/app/demo/x.png" src="y.png">'), true)
        end)

        test.it("skips import maps inside <template>", function()
            local html = '<template><script type="importmap">{"a":1}</script></template>'
                .. '<script type="importmap">{"b":2}</script>'
            test.eq(fragment_html.page_import_map(html), '{"b":2}')
            test.eq(fragment_html.page_import_map('<template><template></template><script type="importmap">{}</script></template>'), nil)
        end)

        test.it("lowercases names as ASCII only", function()
            -- U+0130 and U+212A are lowercased to ASCII by the runtime's string.lower.
            test.eq(fragment_html.page_import_map('<scr\196\176pt type="importmap">{}</scr\196\176pt>'), nil)
            test.eq(fragment_html.page_import_map('<script type="\196\176mportmap">{}</script>'), nil)
            -- A real <link> would get `x.css` made absolute; this element is unknown.
            local html = '<lin\226\132\170 href="x.css">'
            test.eq(transform(html), html)
            test.eq(transform('<LINK href="x.css">'), '<LINK href="http://app.test/app/app/demo/x.css">')
        end)

        test.it("rewrites srcset lists, object data and SVG references", function()
            local out = transform('<img srcset="a.png 1x, ../b.png 2x, https://cdn.test/c.png 3x">'
                .. '<link rel="preload" as="image" imagesrcset="d.png 480w,e.png 800w" href="d.png">'
                .. '<object data="doc.pdf"></object>'
                .. '<svg><use href="sprite.svg#i"></use><use href="#local"></use><image xlink:href="./p.png"/></svg>')
            test.eq(contains(out, 'srcset="http://app.test/app/app/demo/a.png 1x, http://app.test/app/app/b.png 2x, https://cdn.test/c.png 3x"'), true)
            test.eq(contains(out, 'imagesrcset="http://app.test/app/app/demo/d.png 480w, http://app.test/app/app/demo/e.png 800w"'), true)
            test.eq(contains(out, 'href="http://app.test/app/app/demo/d.png"'), true)
            test.eq(contains(out, 'data="http://app.test/app/app/demo/doc.pdf"'), true)
            test.eq(contains(out, 'href="http://app.test/app/app/demo/sprite.svg#i"'), true)
            test.eq(contains(out, '<use href="#local">'), true)
            test.eq(contains(out, 'xlink:href="http://app.test/app/app/demo/p.png"'), true)
            local absolute = '<img srcset="https://cdn.test/a.png 1x, data:image/png;base64,AA,BB 2x">'
            test.eq(transform(absolute), absolute)
        end)
    end)
end

local run_cases = test.run_cases(define_tests)

local function run(options: any): any
    return run_cases(options)
end

return { run = run }
