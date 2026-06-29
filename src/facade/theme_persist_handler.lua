local http = require("http")
local registry = require("registry")
local json = require("json")

local NS = "wippy.facade:"

local function get_req(name: string): string
    local entry, _ = registry.get(NS .. name)
    if entry and entry.data then
        return entry.data.default or ""
    end
    return ""
end

-- Body of the served script, minus the first line which injects KEY/MODE.
-- Long-bracket string so the regex backslashes need no Lua escaping.
local BODY = [==[
  function read() {
    if (MODE === 'none') return null;
    try {
      if (MODE === 'cookie') {
        var k = KEY.replace(/[.$?*|{}()[\]\\/+^]/g, '\\$&');
        var m = document.cookie.match(new RegExp('(?:^|; )' + k + '=([^;]*)'));
        return m ? decodeURIComponent(m[1]) : null;
      }
      return localStorage.getItem(KEY);
    } catch (e) { return null; }
  }
  function apply(v) {
    var el = document.documentElement;
    el.classList.toggle('w-theme-dark', v === 'dark');
    el.classList.toggle('w-theme-light', v === 'light');
    if (v === 'dark' || v === 'light') el.style.colorScheme = v;
    else el.style.removeProperty('color-scheme');
  }
  function write(mode) {
    if (MODE === 'none') return;
    try {
      if (MODE === 'cookie')
        document.cookie = KEY + '=' + encodeURIComponent(mode) + '; path=/; max-age=31536000; SameSite=Lax';
      else localStorage.setItem(KEY, mode);
    } catch (e) {}
  }
  var v = read();
  if (v === 'dark' || v === 'light') apply(v);
  window.wippyThemePersist = { mode: MODE, key: KEY, read: read, write: write, apply: apply };
})();
]==]

-- Serves /facade/theme-persist.js: a tiny, ready-to-include script with the
-- configured storage KEY and MODE baked in. On load it applies the stored
-- theme class (early-apply) and exposes `window.wippyThemePersist` with
-- read/write/apply helpers. The host shell, login pages and arbitrary
-- non-Wippy pages integrate with a single <script src> — no config object,
-- and the facade stays the single source of truth for the key + storage logic.
local function handler()
    local res = http.response()
    if not res then
        return nil, "no HTTP context"
    end

    -- Clamp the same way config_handler does, so the script and /facade/config
    -- always agree on the effective mode/key.
    local mode = get_req("theme_persist")
    if mode ~= "cookie" and mode ~= "localStorage" then
        mode = "none"
    end
    local key = get_req("theme_storage_key")
    if key == "" then
        key = "@wippy-theme-mode"
    end

    -- json.encode produces a safe double-quoted JS string literal for both values.
    local key_lit, kerr = json.encode(key)
    if kerr then
        key_lit = '"@wippy-theme-mode"'
    end
    local mode_lit, merr = json.encode(mode)
    if merr then
        mode_lit = '"none"'
    end

    local js = "(function () {\n  var KEY = " .. key_lit .. ", MODE = " .. mode_lit .. ";\n" .. BODY

    res:set_content_type("application/javascript")
    res:set_header("Cache-Control", "public, max-age=3600")
    res:set_status(http.STATUS.OK)
    res:write(js)
end

return { handler = handler }
