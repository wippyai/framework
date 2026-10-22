-- Byte-precise HTML tokenizer and document edits for the fragment gateway.
--
-- The tokenizer follows the WHATWG tokenization rules the gateway depends on:
-- start and end tags with attributes in every quoting form, comments (including
-- the abrupt `<!-->` / `<!--->` forms and `--!>`), doctype, bogus comments, and
-- the raw content of script, style, textarea, title and the other raw-text
-- elements, including the script escape and double-escape states. Tag and
-- attribute names are ASCII-lowercased, as the HTML parser does.
--
-- Edits are applied by byte range, so every byte the gateway does not edit is
-- returned unchanged. Nothing here pattern-matches HTML.
--
-- Known limits: the tokenizer does not run the tree builder. Content inside
-- <svg>/<math> (where raw-text elements are not raw text and CDATA sections
-- exist), <select>, <frameset>, and markup that the parser moves out of a
-- <table> can differ from a browser. Stray <html>/<head>/<body> tags are
-- renamed like real ones. Well-formed view.page documents are not affected.

local M = {}

local RAWTEXT = { style = true, xmp = true, iframe = true, noembed = true, noframes = true, noscript = true }
local RCDATA = { title = true, textarea = true }

local LT, GT, SLASH, BANG, QMARK, EQ, DQ, SQ, DASH, AMP, HASH, SEMI = 60, 62, 47, 33, 63, 61, 34, 39, 45, 38, 35, 59

local function is_ws(c)
    return c == 9 or c == 10 or c == 12 or c == 13 or c == 32
end

local function is_alpha(c)
    return c ~= nil and ((c >= 65 and c <= 90) or (c >= 97 and c <= 122))
end

local function is_digit(c)
    return c ~= nil and c >= 48 and c <= 57
end

local function is_alnum(c)
    return is_alpha(c) or is_digit(c)
end

local function is_hex(c)
    return is_digit(c) or (c ~= nil and ((c >= 65 and c <= 70) or (c >= 97 and c <= 102)))
end

-- table.concat fails above roughly 32,000 pieces in this runtime, so output is
-- joined in blocks.
local BLOCK = 2048

local function joiner()
    return { blocks = {}, pieces = {} }
end

local function join_add(j, s)
    local pieces = j.pieces
    pieces[#pieces + 1] = s
    if #pieces >= BLOCK then
        j.blocks[#j.blocks + 1] = table.concat(pieces)
        j.pieces = {}
    end
end

local function join_result(j)
    j.blocks[#j.blocks + 1] = table.concat(j.pieces)
    return table.concat(j.blocks)
end

-- ASCII-only lowercase. The runtime's string.lower also maps some non-ASCII
-- letters (for example U+0130 and U+212A) to ASCII, which the HTML parser
-- does not do.
local function ascii_lower(s)
    local j = nil
    local run = 1
    for k = 1, #s do
        local c = s:byte(k)
        if c >= 65 and c <= 90 then
            j = j or joiner()
            if k > run then
                join_add(j, s:sub(run, k - 1))
            end
            join_add(j, string.char(c + 32))
            run = k + 1
        end
    end
    if not j then
        return s
    end
    if run <= #s then
        join_add(j, s:sub(run))
    end
    return join_result(j)
end

-- Literal (non-pattern) replacement of every occurrence of `from` in `text`.
local function replace_plain(text, from, to)
    local j = nil
    local pos = 1
    while true do
        local s = text:find(from, pos, true)
        if not s then
            break
        end
        j = j or joiner()
        join_add(j, text:sub(pos, s - 1))
        join_add(j, to)
        pos = s + #from
    end
    if not j then
        return text
    end
    join_add(j, text:sub(pos))
    return join_result(j)
end

-- `</name` (ASCII case-insensitive) at `i`, followed by whitespace, `/` or `>`:
-- the "appropriate end tag" that closes a raw-text element.
local function end_tag_at(html, i, name)
    if html:byte(i) ~= LT or html:byte(i + 1) ~= SLASH then
        return false
    end
    if ascii_lower(html:sub(i + 2, i + 1 + #name)) ~= name then
        return false
    end
    local after = html:byte(i + 2 + #name)
    return after ~= nil and (is_ws(after) or after == SLASH or after == GT)
end

-- `script` (ASCII case-insensitive) at `j`, followed by whitespace, `/` or `>`.
local function script_word_at(html, j)
    if ascii_lower(html:sub(j, j + 5)) ~= "script" then
        return false
    end
    local after = html:byte(j + 6)
    return after ~= nil and (is_ws(after) or after == SLASH or after == GT)
end

-- End of a comment whose `<!--` ends just before `p`. Returns the index of its last byte.
local function comment_end(html, p)
    local n = #html
    if html:byte(p) == GT then
        return p -- `<!-->`
    end
    if html:byte(p) == DASH and html:byte(p + 1) == GT then
        return p + 1 -- `<!--->`
    end
    local j = p
    while j <= n do
        local d = html:find("--", j, true)
        if not d then
            return n
        end
        if html:byte(d + 2) == GT then
            return d + 2 -- `-->`
        end
        if html:byte(d + 2) == BANG and html:byte(d + 3) == GT then
            return d + 3 -- `--!>`
        end
        j = d + 1
    end
    return n
end

-- Index of the `<` of the end tag that closes a RAWTEXT/RCDATA element, or nil at EOF.
local function raw_end(html, p, name)
    local j = p
    while true do
        local found = html:find("</", j, true)
        if not found then
            return nil
        end
        if end_tag_at(html, found, name) then
            return found
        end
        j = found + 1
    end
end

-- Index of the `<` of the `</script` that closes script data, or nil at EOF.
-- Implements the script data, escaped and double-escaped states.
local function script_end(html, p)
    local n = #html
    local state = "data"
    local i = p
    while i <= n do
        local c = html:byte(i)
        local step = 1
        if state == "data" then
            if c == LT then
                if end_tag_at(html, i, "script") then
                    return i
                end
                if html:byte(i + 1) == BANG and html:byte(i + 2) == DASH and html:byte(i + 3) == DASH then
                    state = "esc_dash_dash"
                    step = 4
                end
            end
        elseif state == "esc" or state == "esc_dash" or state == "esc_dash_dash" then
            if c == DASH then
                if state == "esc" then
                    state = "esc_dash"
                elseif state == "esc_dash" then
                    state = "esc_dash_dash"
                end
            elseif c == LT then
                if end_tag_at(html, i, "script") then
                    return i
                end
                if script_word_at(html, i + 1) then
                    state = "dbl"
                    step = 7
                else
                    state = "esc"
                end
            elseif c == GT and state == "esc_dash_dash" then
                state = "data"
            else
                state = "esc"
            end
        else -- dbl, dbl_dash, dbl_dash_dash
            if c == DASH then
                if state == "dbl" then
                    state = "dbl_dash"
                elseif state == "dbl_dash" then
                    state = "dbl_dash_dash"
                end
            elseif c == LT then
                if html:byte(i + 1) == SLASH and script_word_at(html, i + 2) then
                    state = "esc"
                    step = 8
                else
                    state = "dbl"
                end
            elseif c == GT and state == "dbl_dash_dash" then
                state = "data"
            else
                state = "dbl"
            end
        end
        i = i + step
    end
    return nil
end

-- Read a start or end tag whose `<` is at `lt`. Returns nil when the input ends
-- inside the tag (the HTML parser then drops it).
local function read_tag(html, lt, is_end)
    local n = #html
    local i = lt + (is_end and 2 or 1)
    local name_s = i
    while i <= n do
        local c = html:byte(i)
        if is_ws(c) or c == SLASH or c == GT then
            break
        end
        i = i + 1
    end
    if i > n then
        return nil
    end
    local tag = {
        type = is_end and "end" or "start",
        s = lt,
        name_s = name_s,
        name_e = i - 1,
        name = ascii_lower(html:sub(name_s, i - 1)),
        attrs = {},
        self_closing = false,
    }
    while true do
        while i <= n and is_ws(html:byte(i)) do
            i = i + 1
        end
        if i > n then
            return nil
        end
        local c = html:byte(i)
        if c == GT then
            tag.e = i
            return tag
        end
        if c == SLASH then
            if html:byte(i + 1) == GT then
                tag.self_closing = true
                tag.e = i + 1
                return tag
            end
            i = i + 1
        else
            -- Attribute name. Its first character is always part of the name, even `=`.
            local an_s = i
            i = i + 1
            while i <= n do
                local d = html:byte(i)
                if is_ws(d) or d == SLASH or d == GT or d == EQ then
                    break
                end
                i = i + 1
            end
            if i > n then
                return nil
            end
            local attr = { name = ascii_lower(html:sub(an_s, i - 1)), name_s = an_s, name_e = i - 1 }
            local j = i
            while j <= n and is_ws(html:byte(j)) do
                j = j + 1
            end
            if j > n then
                return nil
            end
            if html:byte(j) == EQ then
                j = j + 1
                while j <= n and is_ws(html:byte(j)) do
                    j = j + 1
                end
                if j > n then
                    return nil
                end
                local q = html:byte(j)
                if q == DQ or q == SQ then
                    local close = html:find(q == DQ and '"' or "'", j + 1, true)
                    if not close then
                        return nil
                    end
                    attr.quote = string.char(q)
                    attr.value_s, attr.value_e = j + 1, close - 1
                    attr.raw_s, attr.raw_e = j, close
                    i = close + 1
                elseif q == GT then
                    attr.quote = ""
                    attr.value_s, attr.value_e = j, j - 1
                    attr.raw_s, attr.raw_e = j, j - 1
                    i = j
                else
                    local k = j
                    while k <= n do
                        local d = html:byte(k)
                        if is_ws(d) or d == GT then
                            break
                        end
                        k = k + 1
                    end
                    if k > n then
                        return nil
                    end
                    attr.quote = ""
                    attr.value_s, attr.value_e = j, k - 1
                    attr.raw_s, attr.raw_e = j, k - 1
                    i = k
                end
                attr.value = html:sub(attr.value_s, attr.value_e)
            else
                i = j
            end
            table.insert(tag.attrs, attr)
        end
    end
end

-- Bogus comment: from `<` to the next `>`, or to EOF.
local function bogus_comment(html, lt)
    local gt = html:find(">", lt + 1, true)
    return { type = "comment", s = lt, e = gt or #html, bogus = true }
end

--- Tokenize `html` into start tags, end tags, comments and doctypes with byte
--- ranges (1-based, inclusive). Start tags of raw-text elements carry
--- `content_s`/`content_e` and `end_token`. Text is not tokenized.
function M.tokenize(html)
    local tokens = {}
    local n = #html
    local i = 1
    while i <= n do
        local lt = html:find("<", i, true)
        if not lt then
            break
        end
        local c = html:byte(lt + 1)
        if c == BANG then
            if html:byte(lt + 2) == DASH and html:byte(lt + 3) == DASH then
                local e = comment_end(html, lt + 4)
                table.insert(tokens, { type = "comment", s = lt, e = e })
                i = e + 1
            elseif ascii_lower(html:sub(lt + 2, lt + 8)) == "doctype" then
                local gt = html:find(">", lt + 2, true) or n
                table.insert(tokens, { type = "doctype", s = lt, e = gt })
                i = gt + 1
            else
                local tok = bogus_comment(html, lt)
                table.insert(tokens, tok)
                i = tok.e + 1
            end
        elseif c == QMARK then
            local tok = bogus_comment(html, lt)
            table.insert(tokens, tok)
            i = tok.e + 1
        elseif c == SLASH then
            local c2 = html:byte(lt + 2)
            if is_alpha(c2) then
                local tag = read_tag(html, lt, true)
                if not tag then
                    break
                end
                table.insert(tokens, tag)
                i = tag.e + 1
            elseif c2 == GT then
                i = lt + 3 -- `</>` is dropped
            elseif c2 == nil then
                break
            else
                local tok = bogus_comment(html, lt)
                table.insert(tokens, tok)
                i = tok.e + 1
            end
        elseif is_alpha(c) then
            local tag = read_tag(html, lt, false)
            if not tag then
                break
            end
            table.insert(tokens, tag)
            i = tag.e + 1
            local name = tag.name
            if name == "script" or RAWTEXT[name] or RCDATA[name] then
                local close
                if name == "script" then
                    close = script_end(html, i)
                else
                    close = raw_end(html, i, name)
                end
                tag.content_s = i
                tag.content_e = (close or (n + 1)) - 1
                if close then
                    local end_tag = read_tag(html, close, true)
                    if end_tag then
                        table.insert(tokens, end_tag)
                        tag.end_token = end_tag
                        i = end_tag.e + 1
                    else
                        i = n + 1
                    end
                else
                    i = n + 1
                end
            elseif name == "plaintext" then
                tag.content_s = i
                tag.content_e = n
                i = n + 1
            end
        else
            i = lt + 1 -- a `<` that does not start markup is text
        end
    end
    return tokens
end

-- Character references in attribute values, as the HTML tokenizer decodes
-- them: numeric references (with or without `;`), the named references that
-- matter for `type`, `data-role` and URL values, and the legacy forms of
-- amp/lt/gt/quot without `;` when no letter, digit or `=` follows.
local NAMED = {
    amp = "&", AMP = "&", lt = "<", LT = "<", gt = ">", GT = ">",
    quot = '"', QUOT = '"', apos = "'", Tab = "\t", NewLine = "\n",
}
local LEGACY = { amp = true, AMP = true, lt = true, LT = true, gt = true, GT = true, quot = true, QUOT = true }
local REPLACEMENT = "\239\191\189" -- U+FFFD

local function utf8_char(cp)
    if cp < 0x80 then
        return string.char(cp)
    elseif cp < 0x800 then
        return string.char(0xC0 + math.floor(cp / 0x40), 0x80 + cp % 0x40)
    elseif cp < 0x10000 then
        return string.char(0xE0 + math.floor(cp / 0x1000), 0x80 + math.floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40)
    else
        return string.char(0xF0 + math.floor(cp / 0x40000), 0x80 + math.floor(cp / 0x1000) % 0x40,
            0x80 + math.floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40)
    end
end

-- Decode the character reference whose `&` is at `i`. Returns the text and the
-- index after the reference, or nil when the tokenizer would keep `&` as text.
local function char_ref(value, i)
    local n = #value
    if value:byte(i + 1) == HASH then
        local k = i + 2
        local hex = value:byte(k) == 120 or value:byte(k) == 88
        if hex then
            k = k + 1
        end
        local digits_s = k
        local cp = 0
        while k <= n do
            local c = value:byte(k)
            if hex and is_hex(c) then
                local d = is_digit(c) and c - 48 or (c >= 97 and c - 87 or c - 55)
                cp = math.min(cp * 16 + d, 0x110000)
            elseif not hex and is_digit(c) then
                cp = math.min(cp * 10 + (c - 48), 0x110000)
            else
                break
            end
            k = k + 1
        end
        if k == digits_s then
            return nil, nil
        end
        if value:byte(k) == SEMI then
            k = k + 1
        end
        if cp == 0 or cp > 0x10FFFF or (cp >= 0xD800 and cp <= 0xDFFF) then
            return REPLACEMENT, k
        end
        return utf8_char(cp), k
    end
    local k = i + 1
    while k <= n and is_alnum(value:byte(k)) do
        k = k + 1
    end
    local name = value:sub(i + 1, k - 1)
    local text = NAMED[name]
    if not text then
        return nil, nil
    end
    if value:byte(k) == SEMI then
        return text, k + 1
    end
    if LEGACY[name] and value:byte(k) ~= EQ then
        return text, k -- the loop above stopped at a byte that is not alphanumeric
    end
    return nil, nil
end

function M.decode_attribute(value)
    if not value or not value:find("&", 1, true) then
        return value
    end
    local j = joiner()
    local pos = 1
    while true do
        local amp = value:find("&", pos, true)
        if not amp then
            break
        end
        local text, next_i = char_ref(value, amp)
        if text and next_i then
            join_add(j, value:sub(pos, amp - 1))
            join_add(j, text)
            pos = next_i
        else
            join_add(j, value:sub(pos, amp))
            pos = amp + 1
        end
    end
    join_add(j, value:sub(pos))
    return join_result(j)
end

local function trim_ascii_ws(s)
    local i, j = 1, #s
    while i <= j and is_ws(s:byte(i)) do
        i = i + 1
    end
    while j >= i and is_ws(s:byte(j)) do
        j = j - 1
    end
    return s:sub(i, j)
end

local function attr(tag, name)
    for _, a in ipairs(tag.attrs) do
        if a.name == name then
            return a -- the HTML parser keeps the first of duplicate attributes
        end
    end
    return nil
end

local function attr_value(tag, name)
    local a = attr(tag, name)
    if not a or a.value == nil then
        return nil
    end
    return M.decode_attribute(a.value)
end

--- A `<script>` whose type, trimmed and ASCII case-insensitive, is `importmap`.
function M.is_import_map(tag)
    if tag.type ~= "start" or tag.name ~= "script" then
        return false
    end
    local value = attr_value(tag, "type")
    return value ~= nil and ascii_lower(trim_ascii_ws(value)) == "importmap"
end

local function is_wippy_scripts_placeholder(tag)
    if tag.type ~= "start" or tag.name ~= "script" then
        return false
    end
    local value = attr_value(tag, "data-role")
    return value ~= nil and trim_ascii_ws(value) == "@wippy/scripts"
end

--- Raw text of the first import map that a browser would apply, or nil when
--- there is none or it is empty. Import maps inside <template> are inert and
--- are skipped.
function M.page_import_map(html, tokens)
    local template_depth = 0
    for _, t in ipairs(tokens or M.tokenize(html)) do
        if t.name == "template" then
            if t.type == "start" then
                template_depth = template_depth + 1
            elseif t.type == "end" and template_depth > 0 then
                template_depth = template_depth - 1
            end
        elseif template_depth == 0 and M.is_import_map(t) then
            local text = html:sub(t.content_s, t.content_e)
            if text == "" then
                return nil
            end
            return text
        end
    end
    return nil
end

-- URL helpers --------------------------------------------------------------

-- The lowercased scheme of `ref` and the index after its `:`, or nil.
local function scheme_of(ref)
    if not is_alpha(ref:byte(1)) then
        return nil, nil
    end
    for k = 2, #ref do
        local c = ref:byte(k)
        if c == 58 then -- ':'
            return ascii_lower(ref:sub(1, k - 1)), k + 1
        end
        if not (is_alnum(c) or c == 43 or c == 45 or c == 46) then -- not + - .
            return nil, nil
        end
    end
    return nil, nil
end

local function has_scheme(ref)
    return scheme_of(ref) ~= nil
end

-- A reference as the URL parser reads it against an http(s) base: leading and
-- trailing C0 controls and spaces stripped, tabs and newlines removed, and `\`
-- read as `/` before the query.
local function clean_ref(ref)
    local i, j = 1, #ref
    while i <= j and ref:byte(i) <= 32 do
        i = i + 1
    end
    while j >= i and ref:byte(j) <= 32 do
        j = j - 1
    end
    local s = replace_plain(replace_plain(replace_plain(ref:sub(i, j), "\t", ""), "\n", ""), "\r", "")
    local cut = #s + 1
    for k = 1, #s do
        local c = s:byte(k)
        if c == 63 or c == HASH then
            cut = k
            break
        end
    end
    return replace_plain(s:sub(1, cut - 1), "\\", "/") .. s:sub(cut)
end

-- Split an absolute or root-relative URL into origin ("scheme://authority" or
-- ""), path, and suffix (query and fragment).
local function split_url(url)
    local origin, rest = "", url
    local scheme_end = url:find("://", 1, true)
    if scheme_end and has_scheme(url) then
        local path_start = url:find("/", scheme_end + 3, true)
        local q = url:find("?", scheme_end + 3, true)
        local h = url:find("#", scheme_end + 3, true)
        local cut = path_start
        for _, x in ipairs({ q, h }) do
            if x and (not cut or x < cut) then
                cut = x
            end
        end
        if cut then
            origin, rest = url:sub(1, cut - 1), url:sub(cut)
        else
            origin, rest = url, ""
        end
    end
    local suffix_at
    for k = 1, #rest do
        local c = rest:byte(k)
        if c == 63 or c == HASH then
            suffix_at = k
            break
        end
    end
    if suffix_at then
        return origin, rest:sub(1, suffix_at - 1), rest:sub(suffix_at)
    end
    return origin, rest, ""
end

-- 1 for a single-dot segment, 2 for a double-dot segment (percent-encoded dots
-- included, as in the URL standard), else 0.
local function dot_kind(seg)
    local s = ascii_lower(seg)
    if s == "." or s == "%2e" then
        return 1
    end
    if s == ".." or s == ".%2e" or s == "%2e." or s == "%2e%2e" then
        return 2
    end
    return 0
end

-- RFC 3986 section 5.2.4, with the URL standard's dot segments.
local function remove_dot_segments(path)
    local absolute = path:byte(1) == SLASH
    local segments = {}
    local parts = {}
    local start = 1
    while true do
        local slash = path:find("/", start, true)
        if not slash then
            table.insert(parts, path:sub(start))
            break
        end
        table.insert(parts, path:sub(start, slash - 1))
        start = slash + 1
    end
    for idx, seg in ipairs(parts) do
        local last = idx == #parts
        local kind = dot_kind(seg)
        if kind == 1 then
            if last then
                table.insert(segments, "")
            end
        elseif kind == 2 then
            if #segments > 0 and not (#segments == 1 and segments[1] == "" and absolute) then
                table.remove(segments)
            end
            if last then
                table.insert(segments, "")
            end
        else
            table.insert(segments, seg)
        end
    end
    local out = table.concat(segments, "/")
    if absolute and out:byte(1) ~= SLASH then
        out = "/" .. out
    end
    return out
end

--- Resolve `ref` against the absolute http(s) `base_url` (a directory URL).
--- Returns nil when `ref` is already absolute, protocol-relative, a fragment,
--- or empty.
function M.resolve_url(base_url, ref)
    local value = clean_ref(ref)
    if value == "" or value:byte(1) == HASH then
        return nil
    end
    local scheme, rest_at = scheme_of(value)
    if scheme and rest_at then
        -- `http:x.css` against an http base is relative (the URL standard's
        -- special-relative state); any other scheme makes the reference absolute.
        if scheme ~= scheme_of(base_url) or value:byte(rest_at) == SLASH or rest_at > #value then
            return nil
        end
        value = value:sub(rest_at)
    end
    if value:byte(1) == SLASH and value:byte(2) == SLASH then
        return nil
    end
    local base_origin, base_path = split_url(base_url)
    if value:byte(1) == 63 then -- '?'
        return base_origin .. base_path .. value
    end
    local _, ref_path, ref_suffix = split_url(value)
    local merged
    if ref_path:byte(1) == SLASH then
        merged = ref_path
    else
        local dir = base_path
        local last_slash
        for k = #dir, 1, -1 do
            if dir:byte(k) == SLASH then
                last_slash = k
                break
            end
        end
        dir = last_slash and dir:sub(1, last_slash) or "/"
        merged = dir .. ref_path
    end
    return base_origin .. remove_dot_segments(merged) .. ref_suffix
end

-- Rewrite every candidate URL of a srcset-style list (the HTML "parse a srcset
-- attribute" steps), keeping descriptors. Returns nil when nothing changes.
local function srcset_rewrite(value, base_url)
    local j = joiner()
    local changed, first = false, true
    local i, n = 1, #value
    while i <= n do
        local c = value:byte(i)
        if is_ws(c) or c == 44 then -- ','
            i = i + 1
        else
            local url_s = i
            while i <= n and not is_ws(value:byte(i)) do
                i = i + 1
            end
            local url_e = i - 1
            local ended = false
            while url_e >= url_s and value:byte(url_e) == 44 do
                url_e = url_e - 1
                ended = true
            end
            local descriptors = ""
            if not ended then
                local d_s, depth = i, 0
                while i <= n do
                    local d = value:byte(i)
                    if d == 40 then -- '('
                        depth = depth + 1
                    elseif d == 41 and depth > 0 then -- ')'
                        depth = depth - 1
                    elseif d == 44 and depth == 0 then
                        break
                    end
                    i = i + 1
                end
                descriptors = trim_ascii_ws(value:sub(d_s, i - 1))
            end
            local url = value:sub(url_s, url_e)
            if url ~= "" then
                local resolved = M.resolve_url(base_url, url)
                if resolved then
                    changed = true
                    url = resolved
                end
                if not first then
                    join_add(j, ", ")
                end
                join_add(j, url)
                if descriptors ~= "" then
                    join_add(j, " ")
                    join_add(j, descriptors)
                end
                first = false
            end
        end
    end
    if not changed then
        return nil
    end
    return join_result(j)
end

local function escape_attribute(value)
    return replace_plain(replace_plain(value, "&", "&amp;"), '"', "&quot;")
end

-- Attributes that load a resource. In the main document's shadow root a
-- relative URL would resolve against the Host page's URL, so every relative
-- reference becomes absolute. On other elements (navigation such as <a>) only
-- `./` and `../` references are made absolute.
local RESOURCE_ATTRS: {[string]: {[string]: boolean}} = {
    link = { href = true }, script = { src = true }, img = { src = true }, source = { src = true },
    video = { src = true, poster = true }, audio = { src = true }, track = { src = true },
    embed = { src = true }, iframe = { src = true }, input = { src = true }, object = { data = true },
    image = { href = true, ["xlink:href"] = true }, use = { href = true, ["xlink:href"] = true },
    feimage = { href = true, ["xlink:href"] = true },
}

-- Attributes that hold a comma-separated list of candidate URLs.
local SRCSET_ATTRS: {[string]: {[string]: boolean}} = {
    img = { srcset = true }, source = { srcset = true }, link = { imagesrcset = true },
}

local function directory_relative(value)
    local v = clean_ref(value)
    return v:sub(1, 2) == "./" or v:sub(1, 3) == "../"
end

local function url_edit(tag, a, base_url)
    if a.value == nil or a.value == "" then
        return nil
    end
    local value = M.decode_attribute(a.value)
    local resolved
    local lists = SRCSET_ATTRS[tag.name]
    if lists ~= nil and lists[a.name] == true then
        resolved = srcset_rewrite(value, base_url)
    else
        local attrs = RESOURCE_ATTRS[tag.name]
        local resource = attrs ~= nil and attrs[a.name] == true
        if not resource and not ((a.name == "href" or a.name == "src") and directory_relative(value)) then
            return nil
        end
        resolved = M.resolve_url(base_url, value)
    end
    if not resolved then
        return nil
    end
    return { s = a.raw_s, e = a.raw_e, text = '"' .. escape_attribute(resolved) .. '"' }
end

local function apply_edits(html, edits)
    table.sort(edits, function(x, y)
        if x.s ~= y.s then
            return x.s < y.s
        end
        return (x.e - x.s) < (y.e - y.s) -- an insertion (e < s) goes before a replacement at the same place
    end)
    local j, pos = joiner(), 1
    for _, ed in ipairs(edits) do
        if ed.s < pos then
            error("fragment_html: overlapping edits at byte " .. tostring(ed.s))
        end
        join_add(j, html:sub(pos, ed.s - 1))
        join_add(j, ed.text)
        pos = ed.e + 1
    end
    join_add(j, html:sub(pos))
    return join_result(j)
end

local WF = { html = "wf-html", head = "wf-head", body = "wf-body" }

--- Transform a view.page document for the fragment realm:
---   * remove every import map (the realm stub registers the page map) and the
---     `@wippy/scripts` dev-proxy placeholder;
---   * make relative resource URLs absolute against `options.base_url`;
---   * insert `options.head_prepend` at the start of <head> (after <html>, or
---     at the document start, when there is no <head> tag);
---   * rename html/head/body tags to wf-html/wf-head/wf-body.
--- Returns the new document and the raw text of the page import map (or nil).
function M.transform_document(html, options)
    local tokens = M.tokenize(html)
    local page_map = M.page_import_map(html, tokens)
    local edits = {}
    local head_tag, html_tag, doctype = nil, nil, nil
    for _, t in ipairs(tokens) do
        if t.type == "start" then
            if M.is_import_map(t) or is_wippy_scripts_placeholder(t) then
                local last = t.end_token and t.end_token.e or #html
                table.insert(edits, { s = t.s, e = last, text = "" })
            else
                if options.base_url and options.base_url ~= "" then
                    -- Only the first of duplicate attributes counts, as in the parser.
                    local seen = {}
                    for _, a in ipairs(t.attrs) do
                        if not seen[a.name] then
                            seen[a.name] = true
                            local ed = url_edit(t, a, options.base_url)
                            if ed then
                                table.insert(edits, ed)
                            end
                        end
                    end
                end
                if WF[t.name] then
                    table.insert(edits, { s = t.name_s, e = t.name_e, text = WF[t.name] })
                end
                if t.name == "head" and not head_tag then
                    head_tag = t
                elseif t.name == "html" and not html_tag then
                    html_tag = t
                end
            end
        elseif t.type == "end" then
            if WF[t.name] then
                table.insert(edits, { s = t.name_s, e = t.name_e, text = WF[t.name] })
            end
        elseif t.type == "doctype" and not doctype then
            doctype = t
        end
    end
    if options.head_prepend and options.head_prepend ~= "" then
        local at = (head_tag and head_tag.e + 1) or (html_tag and html_tag.e + 1) or (doctype and doctype.e + 1) or 1
        table.insert(edits, { s = at, e = at - 1, text = options.head_prepend })
    end
    return apply_edits(html, edits), page_map
end

return M
