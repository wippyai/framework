# wippy/facade

Portable iframe facade for the Wippy frontend. Serves a thin HTML shell that loads the Wippy frontend bundle from a CDN via iframe, with all configuration driven through `ns.requirement` entries.

## How it works

1. `index.html` is served as a static file via `http.static`
2. On load, it fetches `GET /api/public/facade/config` to get runtime configuration
3. Checks `localStorage` for an auth token, redirects to `login_path` if missing
4. Loads the Web Host bundle from CDN — picks the module file based on `fe_mode`:
   - `compat` (default) → `module.js` — full Wippy host chrome
   - `managed` → `managed-layout.js` — declarative multi-panel host driven by `hostConfig.layout`
5. Calls `window.initWippyApp(config)` — both entries expose the same symbol; the mounted shell is the only difference
6. Shows `<wippy-loading>` / `<wippy-error>` during initialization (vendored from Wippy Web Host CDN)

## Modes

| Mode | Entry loaded | Mounted shell | Use case |
|---|---|---|---|
| `compat` _(default)_ | `module.js` | Full Wippy chrome (sidebar + chat + pages + right panel) | Backwards-compatible — existing facades keep working unchanged |
| `managed` | `managed-layout.js` | Declarative multi-panel layout — no default chrome, every panel declared via `hostConfig.layout` | IDE-style apps, dashboards, Adobe-style multi-pane tools |

Both entries expose the same `window.initWippyApp(config, rootContainer?)` signature — the parent integration code does not change between modes. Set via the `fe_mode` requirement; unknown values normalize to `compat`.

### When to switch to `managed` mode

- You want a multi-panel app with separator-drag resizing
- You want to embed a custom panel configuration driven by config (not by the standard sidebar/chat layout)
- You want breakpoint-responsive layouts (desktop vs mobile)

Leave `fe_mode` at `compat` unless you have a specific reason to opt in — the managed shell omits every piece of default Wippy chrome (no sidebar, no chat wrapper, no right panel) and expects the declaration to provide equivalents.

## Vendored CDN files

`public/@wippy-fe/` contains files copied from the Wippy Web Host CDN. These are loaded before the CDN URL is known (pre-config-fetch), so they must be vendored locally.

**After every Wippy Web Host version bump**, run:

```
make sync
```

This downloads fresh copies from the CDN. Update `WEB_HOST_CDN` in the Makefile when the version changes.

## Derived values

These fields are NOT configurable via requirements — they are computed at runtime:

| Field | Source | Description |
|---|---|---|
| `env.APP_API_URL` | `PUBLIC_API_URL` env var | Base URL for API calls. Falls back to `window.location.origin` in the browser if empty. |
| `env.APP_WEBSOCKET_URL` | Derived from `APP_API_URL` | WebSocket URL — `http://` → `ws://`, `https://` → `wss://` |
| `iframe_origin` | Extracted from `fe_facade_url` | Origin portion of facade URL (e.g. `https://web-host.wippy.ai`), used for `postMessage` security |
| `iframe_url` | `fe_facade_url` + `fe_entry_path` + `?waitForCustomConfig` | Full iframe URL passed to the Web Host |

## Requirements

### Infrastructure

| Requirement | Default | Description |
|---|---|---|
| `server` | _(required)_ | HTTP server for static serving |
| `router` | _(required)_ | Public router for config endpoint |

### Core

| Requirement | Default | Description |
|---|---|---|
| `fe_facade_url` | `https://web-host.wippy.ai/webcomponents-1.0.39` | CDN base URL for the Web Host frontend bundle |
| `fe_entry_path` | `/iframe.html` | Iframe HTML entry point path (appended to `fe_facade_url`) |
| `fe_mode` | `compat` | `compat` (default — loads `module.js`) or `managed` (loads `managed-layout.js` for declarative multi-panel apps). See [Modes](#modes) above |

### App Identity

Passed to the Web Host as `theming.host.i18n.app` — controls branding in sidebar and navigation.

| Requirement | Default | Config path | Description |
|---|---|---|---|
| `app_title` | `Wippy` | `theming.host.i18n.app.title` | Short title shown in sidebar header |
| `app_name` | `Wippy AI` | `theming.host.i18n.app.appName` | Full application name |
| `app_icon` | `wippy:logo` | `theming.host.i18n.app.icon` | Iconify icon reference (e.g. `custom:logo`, `tabler:home`) |

### Host Config (hostConfig)

Host-only UI flags — NOT sent to child iframes.

| Requirement | Default | Type | Description |
|---|---|---|---|
| `show_admin` | `true` | bool (`~= "false"`) | Show admin panel and keeper controls in the sidebar |
| `start_nav_open` | `false` | bool (`== "true"`) | Navigation drawer open by default (collapsed shows icons only) |
| `hide_nav_bar` | `false` | bool (`== "true"`) | Completely hide the left navigation sidebar |
| `disable_right_panel` | `false` | bool (`== "true"`) | Disable the right sidebar panel |
| `allow_select_model` | `false` | bool (`== "true"`) | Allow LLM model selection dropdown in chat |
| `hide_session_selector` | `false` | bool (`== "true"`) | Hide the chat session selector dropdown |
| `session_type` | `non-persistent` | string | Chat session persistence (`non-persistent` or `cookie`) |
| `history_mode` | `hash` | string | Browser history mode (`hash` or `browser`) |

> **Boolean parsing:** `show_admin` defaults to `true` (any value except `"false"` is truthy). All other boolean flags default to `false` (only `"true"` is truthy).

#### Advanced hostConfig (JSON)

These accept JSON strings for complex configuration:

| Requirement | Default | Config path | Description |
|---|---|---|---|
| `api_routes` | `{}` | `apiRoutes` | API route overrides — top-level, not under hostConfig (e.g. `{"agents":{"list":"/custom/agents"}}`) |
| `additional_nav_items` | `[]` | `hostConfig.additionalNavItems` | Extra sidebar nav items as JSON array |
| `state_cache` | `{}` | `hostConfig.stateCache` | Child state LRU config (e.g. `{"maxPages":50,"maxSizePerPage":1048576}`) |
| `allow_additional_tags` | `{}` | `hostConfig.allowAdditionalTags` | HTML sanitizer tag whitelist (e.g. `{"w-chart":["data","type"]}`) |
| `chat` | `{}` | `hostConfig.chat` | Chat config (e.g. `{"convertPasteToFile":{"enabled":true,"minFileSize":1024,"allowHtml":false}}`) |
| `axios_defaults` | `{}` | `axiosDefaults` | HTTP client defaults (e.g. `{"timeout":30000}`) — top-level, not under hostConfig |
| `tanstack` | `{}` | `tanstack` | TanStack Query defaults — top-level, not under hostConfig. `{ default?, content?, lists? }`: `default` applies to all queries, `content` to single-resource renders, `lists` to navigation/index queries. Host default is `refetchOnWindowFocus:false` (e.g. `{"lists":{"refetchOnWindowFocus":true}}`) |
| `extra_scripts` | `[]` | `extraScripts` | External `<script>` tags injected into `index.html` before the Web Host bundle loads. See [Extra scripts](#extra-scripts). |

### Auth

| Requirement | Default | Description |
|---|---|---|
| `login_path` | `/login.html` | Path to redirect unauthenticated users (no token in localStorage) |
| `login_redirect_param` | `""` _(off)_ | Query param name appended to `login_path` carrying the user's current relative URL, so the login flow can return them after auth. Empty disables. See [Post-login redirect](#post-login-redirect). |

### Theming

Three theming scopes control which layers see which styles:

#### File system for `fs://` references

| Requirement | Default | Description |
|---|---|---|
| `content_fs` | _(empty)_ | `fs.directory` entry ID whose files can be referenced via `fs://` in CSS and JSON requirements. When set, any value like `fs://custom-css.facade.css` or `fs://css-variables.facade.json` is resolved to that file's content at request time. Empty disables file resolution. Example: `"app:app_fs"`. |

When `content_fs` is configured, CSS requirements (`custom_css`, `host_custom_css`, `children_custom_css`) and JSON variable requirements (`css_variables`, `host_css_variables`, `children_css_variables`) all accept `fs://path` values in addition to inline strings.

> **Why `fs://` and not `file://`?** The wippy registry loader reserves `file://` for its OWN load-time interpolation — it reads a `file://` value relative to the `_index.yaml` that contains it and inlines the file content at boot, so a `file://` written in a YAML requirement param never reaches the facade (and a path that doesn't resolve from the YAML's own directory fails the whole file). `fs://` is passed through untouched, so the facade resolves it at request time against `content_fs`. (`file://` is still accepted for values set via non-YAML paths — env vars, `-o` overrides, runtime registry edits — where the loader does not interpolate.)

The same `fs.directory` can be served as a static endpoint (`http.static`) so pages like `login.html` can `<link>` the same CSS files directly. See [File-based theming](#file-based-theming) below.

#### Global scope (`theming.global`) — applied to host AND children

| Requirement | Default | Config path | Description |
|---|---|---|---|
| `custom_css` | Poppins font `@import` | `theming.global.customCSS` | CSS applied everywhere — host chrome and child iframes. Accepts inline CSS or `fs://path` (requires `content_fs`). |
| `css_variables` | `{}` | `theming.global.cssVariables` | CSS variables applied everywhere. Supports `@dark`/`@light` variants. Accepts inline JSON or `fs://path`. |
| `icon_sets` | `{}` | `theming.global.iconSets` | Iconify icon sets as `{prefix: {name: {body,width,height}}}` (e.g. `{"custom":{"logo":{...}}}`) |

#### Host scope (`theming.host`) — applied to host chrome ONLY

| Requirement | Default | Config path | Description |
|---|---|---|---|
| `host_custom_css` | _(empty)_ | `theming.host.customCSS` | CSS for sidebar, chat, nav — NOT applied to child iframes. Accepts inline CSS or `fs://path`. |
| `host_css_variables` | `{}` | `theming.host.cssVariables` | CSS variables for host chrome only — override global vars. Accepts inline JSON or `fs://path`. |
| `host_icon_sets` | `{}` | `theming.host.iconSets` | Icon sets for host chrome only (same format as global `icon_sets`) |

#### Children scope (`theming.children`) — applied to child iframes ONLY

| Requirement | Default | Config path | Description |
|---|---|---|---|
| `children_custom_css` | _(empty)_ | `theming.children.customCSS` | CSS for child iframes only — NOT applied to host chrome. Accepts inline CSS or `fs://path`. |
| `children_css_variables` | `{}` | `theming.children.cssVariables` | CSS variables for children only — override global vars. Accepts inline JSON or `fs://path`. |

> **Merge rules:** Host sees `global + host` merged. Children see `global + children` merged. Host-scope styles never leak to children and vice versa. Icons are only in `global` and `host` scopes (children don't get their own icon sets).

### Managed-layout

| Requirement | Default | Config path | Description |
|---|---|---|---|
| `host_config_layout` | `{}` | `hostConfig.layout` | Managed-layout `HostLayoutDeclaration` as JSON string. Only relevant when `fe_mode = "managed"`. Empty (default) leaves `hostConfig.layout` unset, so the host falls back to URL-param / parent-SetConfig configuration paths. See [`gen-2-chat/managed-layout.md`](https://github.com/wippyai/gen-2-chat/blob/webcomponents/managed-layout.md) for the schema. |

Example — minimal 2-panel layout:

```yaml
    - name: fe_mode
      value: managed
    - name: host_config_layout
      value: |
        {
          "layouts": {
            "default": {
              "direction": "horizontal",
              "children": [
                { "panel": "nav", "size": "240px" },
                { "panel": "main", "size": "1fr", "main": true }
              ]
            }
          },
          "panels": {
            "nav":  { "kind": "builtin", "id": "@HOST/nav-sidebar" },
            "main": { "kind": "page",    "id": "home", "route": "/" }
          }
        }
```

## Usage

```yaml
- name: facade
  kind: ns.dependency
  component: wippy/facade
  version: "*"
  parameters:
    - name: server
      value: app:gateway
    - name: router
      value: app:api.public
```

Only override what differs from defaults.

### Themed page-only app (no chat sidebar)

```yaml
    - name: hide_nav_bar
      value: "true"
    - name: disable_right_panel
      value: "true"
    - name: show_admin
      value: "false"
    - name: custom_css
      value: "@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap'); body { font-family: 'Inter', sans-serif; }"
    - name: css_variables
      value: '{"--p-primary":"#6366f1"}'
```

### Host-only styling (chat area gets custom look, children stay default)

```yaml
    - name: host_custom_css
      value: ".chat-message { border-radius: 0; } .chat-input { font-size: 15px; }"
    - name: host_css_variables
      value: '{"--wippy-host-message-bg":"#f8f9fa","--wippy-host-input-bg":"#ffffff"}'
```

### Children-only styling (embedded pages get branded, host stays default)

```yaml
    - name: children_css_variables
      value: '{"--p-primary":"#dc2626"}'
    - name: children_custom_css
      value: "body { font-family: 'Comic Sans MS', cursive; }"
```

### File-based theming

Instead of inlining CSS or JSON in YAML, store theming files in an `fs.directory` and reference them with `fs://path`. Keep them in the **same folder you already serve static assets from** (next to `login.html`), so one place backs both the facade config and the page `<link>`s.

**Naming** — name each file after the requirement it fills, with a `.facade.` infix:
`custom-css.facade.css`, `css-variables.facade.json`, `host-custom-css.facade.css`, … It keeps them self-documenting and easy to spot among other static assets.

**Step 1** — reuse the static dir you already serve. For example an app that serves `./static` at `/app`:

```yaml
- name: app_fs
  kind: fs.directory
  directory: ./static
  auto_init: true

- name: app_static
  kind: http.static
  meta:
    server: app:gateway
  fs: app:app_fs
  path: /app
```

**Step 2** — place the theming files in that folder, next to `login.html`:

```
static/
  login.html
  custom-css.facade.css       # @import url(...); :root { ... }
  css-variables.facade.json   # {"--p-primary":"#6366f1","@dark":{"--p-primary":"#818cf8"}}
```

**Step 3** — point `content_fs` at that `fs.directory` and reference the files with `fs://`:

```yaml
- name: content_fs
  value: app:app_fs
- name: custom_css
  value: "fs://custom-css.facade.css"
- name: css_variables
  value: "fs://css-variables.facade.json"
```

**Result:**
- `GET /api/public/facade/config` → `theming.global.customCSS` contains the file content, `theming.global.cssVariables` contains the parsed JSON object (resolved at request time from `content_fs`)
- `GET /api/public/facade/variables.css` → generates CSS from `css-variables.facade.json`
- `GET /app/custom-css.facade.css` → serves the raw file (via `app_static`)
- `login.html` can use both:

```html
<link rel="stylesheet" href="/app/custom-css.facade.css">
<link rel="stylesheet" href="/api/public/facade/variables.css">
```

To relocate the assets later, change the one `directory:` line on the `fs.directory` — the `fs://` references and `content_fs` follow it.

### Custom icons

```yaml
    - name: icon_sets
      value: '{"custom":{"logo":{"body":"<svg viewBox=\"0 0 24 24\"><path d=\"M12 2L2 22h20L12 2z\"/></svg>","width":24,"height":24}}}'
    - name: app_icon
      value: "custom:logo"
```

### Post-login redirect

Off by default. When enabled, the facade appends the current page's relative URL to `login_path` so the login flow can return the user to where they were after authenticating.

```yaml
    - name: login_redirect_param
      value: "redirect_to"
```

A user opening a deep link like `/c/abc-123` without a valid token will be sent to:

```
/login.html?redirect_to=%2Fc%2Fabc-123
```

The login page reads `redirect_to` from the query string and navigates the user there after successful auth.

### Extra scripts

Inject external `<script>` tags into the facade `index.html` before the Web Host bundle loads. Useful for host-context integrations (analytics, third-party bridges) that need to run in the top-level window, not inside child iframes.

Each entry is either a string (shorthand for `{ src }`) or an object with any of: `src` (required), `async`, `defer`, `type`, `noModule`, `crossorigin`, `integrity`.

```yaml
    - name: extra_scripts
      value: '["/bridge.js"]'
```

Object form:

```yaml
    - name: extra_scripts
      value: '[{"src":"/bridge.js"},{"src":"https://cdn.example.com/analytics.js","defer":true}]'
```

Scripts are fetched in parallel and awaited before the Web Host bundle is imported, so any globals they define are available to the bundle. Load failures are logged to `console.warn` and do NOT block app startup.

> **Security:** entries come from `ns.requirement` defaults — i.e. from the application owner, not from end users — so arbitrary URLs in this list are trusted. Still, prefer `integrity` hashes for third-party CDN scripts.

## Endpoints

### `GET /api/public/facade/config`

Returns the full facade configuration as JSON (wippy-context-2.0 format). Used by `index.html` on load; see [Config Response](#config-response) below.

### `GET /api/public/facade/variables.css`

Returns the global CSS variables (`css_variables` requirement) as a `text/css` stylesheet. Useful for non-Wippy-Host pages (e.g. `login.html`) that need the same brand variables without embedding the full Web Host.

The CSS follows the same algorithm as the Web Host's `createCssVariables()`:
- Flat string keys → `:root { --key: value; }`
- `@dark` object → `@media (prefers-color-scheme: dark) { :root { ... } }`
- `@light` object → `@media (prefers-color-scheme: light) { :root { ... } }`
- Keys without `--` prefix get `--` prepended automatically

Returns an empty body (200 OK) when no variables are configured. Response has `Cache-Control: public, max-age=3600`.

**Usage in `login.html`:**
```html
<link rel="stylesheet" href="/api/public/facade/variables.css">
```

## Config Response

`GET /api/public/facade/config` returns (wippy-context-2.0 format):

```json
{
  "facade_url": "https://web-host.wippy.ai/webcomponents-1.0.39",
  "iframe_origin": "https://web-host.wippy.ai",
  "iframe_url": "https://web-host.wippy.ai/webcomponents-1.0.39/iframe.html?waitForCustomConfig",
  "login_path": "/login.html",
  "login_redirect_param": null,
  "env": {
    "APP_API_URL": "http://localhost:8085",
    "APP_AUTH_API_URL": "http://localhost:8085",
    "APP_WEBSOCKET_URL": "ws://localhost:8085"
  },
  "routePrefix": "http://localhost:8085",
  "theming": {
    "global": {
      "customCSS": "@import url('https://fonts.googleapis.com/css2?family=Poppins...');"
    },
    "host": {
      "i18n": { "app": { "title": "Wippy", "icon": "wippy:logo", "appName": "Wippy AI" } }
    },
    "children": null
  },
  "hostConfig": {
    "session": { "type": "non-persistent" },
    "history": "hash",
    "showAdmin": true,
    "allowSelectModel": false,
    "startNavOpen": false,
    "hideNavBar": false,
    "disableRightPanel": false,
    "hideSessionSelector": false
  },
  "extraScripts": null
}
```

### How `index.html` uses the config

```
fetch /api/public/facade/config
  → check localStorage for auth token → redirect to login_path if missing
  → import(facade_url + '/module.js') → load Web Host bundle from CDN
  → initWippyApp({ $schema, auth, env, routePrefix, theming, hostConfig, context }, '#app')
  → listen for 'authExpired' and 'error' events → redirect to login_path
```

The backend returns config in wippy-context-2.0 shape. `index.html` only adds `$schema` (from `facade_url`), `auth` (from localStorage), and `context` (empty default). All other fields pass through from the backend unchanged.

If any step fails (config fetch, CDN import, missing `initWippyApp`), the page shows a themed `<wippy-error>` screen with title and details. No external CSS is required — both `<wippy-loading>` and `<wippy-error>` are self-contained web components with Shadow DOM styles.

## Publishing

```bash
cd src/facade && wippy publish
```

The `wippy.yaml` includes `embed: ["public_files"]` to bundle `index.html` into the wapp package.
