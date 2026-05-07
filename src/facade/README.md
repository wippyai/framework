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
| `fe_facade_url` | `https://web-host.wippy.ai/webcomponents-1.0.28` | CDN base URL for the Web Host frontend bundle |
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
| `api_routes` | `{}` | `hostConfig.apiRoutes` | API route overrides (e.g. `{"agents":{"list":"/custom/agents"}}`) |
| `additional_nav_items` | `[]` | `hostConfig.additionalNavItems` | Extra sidebar nav items as JSON array |
| `state_cache` | `{}` | `hostConfig.stateCache` | Child state LRU config (e.g. `{"maxPages":50,"maxSizePerPage":1048576}`) |
| `allow_additional_tags` | `{}` | `hostConfig.allowAdditionalTags` | HTML sanitizer tag whitelist (e.g. `{"w-chart":["data","type"]}`) |
| `chat` | `{}` | `hostConfig.chat` | Chat config (e.g. `{"convertPasteToFile":{"enabled":true,"minFileSize":1024,"allowHtml":false}}`) |
| `axios_defaults` | `{}` | `axiosDefaults` | HTTP client defaults (e.g. `{"timeout":30000}`) — top-level, not under hostConfig |
| `extra_scripts` | `[]` | `extraScripts` | External `<script>` tags injected into `index.html` before the Web Host bundle loads. See [Extra scripts](#extra-scripts). |

### Auth

| Requirement | Default | Description |
|---|---|---|
| `login_path` | `/login.html` | Path to redirect unauthenticated users (no token in localStorage) |

### Theming

Three theming scopes control which layers see which styles:

#### Global scope (`theming.global`) — applied to host AND children

| Requirement | Default | Config path | Description |
|---|---|---|---|
| `custom_css` | Poppins font `@import` | `theming.global.customCSS` | CSS applied everywhere — host chrome and child iframes |
| `css_variables` | `{}` | `theming.global.cssVariables` | CSS variables applied everywhere. Supports `@dark`/`@light` variants. |
| `icon_sets` | `{}` | `theming.global.iconSets` | Iconify icon sets as `{prefix: {name: {body,width,height}}}` (e.g. `{"custom":{"logo":{...}}}`) |

#### Host scope (`theming.host`) — applied to host chrome ONLY

| Requirement | Default | Config path | Description |
|---|---|---|---|
| `host_custom_css` | _(empty)_ | `theming.host.customCSS` | CSS for sidebar, chat, nav — NOT applied to child iframes |
| `host_css_variables` | `{}` | `theming.host.cssVariables` | CSS variables for host chrome only — override global vars |
| `host_icon_sets` | `{}` | `theming.host.iconSets` | Icon sets for host chrome only (same format as global `icon_sets`) |

#### Children scope (`theming.children`) — applied to child iframes ONLY

| Requirement | Default | Config path | Description |
|---|---|---|---|
| `children_custom_css` | _(empty)_ | `theming.children.customCSS` | CSS for child iframes only — NOT applied to host chrome |
| `children_css_variables` | `{}` | `theming.children.cssVariables` | CSS variables for children only — override global vars |

> **Merge rules:** Host sees `global + host` merged. Children see `global + children` merged. Host-scope styles never leak to children and vice versa. Icons are only in `global` and `host` scopes (children don't get their own icon sets).

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

### Custom icons

```yaml
    - name: icon_sets
      value: '{"custom":{"logo":{"body":"<svg viewBox=\"0 0 24 24\"><path d=\"M12 2L2 22h20L12 2z\"/></svg>","width":24,"height":24}}}'
    - name: app_icon
      value: "custom:logo"
```

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

## Config Response

`GET /api/public/facade/config` returns (wippy-context-2.0 format):

```json
{
  "facade_url": "https://web-host.wippy.ai/webcomponents-1.0.28",
  "iframe_origin": "https://web-host.wippy.ai",
  "iframe_url": "https://web-host.wippy.ai/webcomponents-1.0.28/iframe.html?waitForCustomConfig",
  "login_path": "/login.html",
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
