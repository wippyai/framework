# wippy/facade

Portable iframe facade for the Wippy frontend. Serves a thin HTML shell that loads the Wippy frontend bundle from a CDN via iframe, with all configuration driven through `ns.requirement` entries.

## How it works

1. `index.html` is served as a static file via `http.static`
2. On load, it fetches `GET /api/public/facade/config` to get runtime configuration
3. Checks `localStorage` for an auth token, redirects to `login_path` if missing
4. Loads the Web Host bundle from CDN (`facade_url + '/module.js'`)
5. Calls `initWippyApp()` with auth, feature flags, and customization config
6. Shows inline loader/error UI during initialization (no external CSS dependencies)

## Derived values

These fields are NOT configurable via requirements — they are computed at runtime:

| Field | Source | Description |
|---|---|---|
| `api_url` | `PUBLIC_API_URL` env var | Base URL for API calls. Falls back to `window.location.origin` in the browser if empty. |
| `ws_url` | Derived from `api_url` | WebSocket URL — `http://` → `ws://`, `https://` → `wss://` |
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
| `fe_facade_url` | `https://web-host.wippy.ai/webcomponents-1.0.16` | CDN base URL for the Web Host frontend bundle |
| `fe_entry_path` | `/iframe.html` | Iframe HTML entry point path (appended to `fe_facade_url`) |

### App Identity

Passed to the Web Host as `customization.i18n.app` — controls branding in sidebar and navigation.

| Requirement | Default | Config path | Description |
|---|---|---|---|
| `app_title` | `Wippy` | `customization.i18n.app.title` | Short title shown in sidebar header |
| `app_name` | `Wippy AI` | `customization.i18n.app.appName` | Full application name |
| `app_icon` | `wippy:logo` | `customization.i18n.app.icon` | Iconify icon reference (e.g. `custom:logo`, `tabler:home`) |

### Feature Flags

Passed to the Web Host as `feature.*` — control UI behavior and visibility.

| Requirement | Default | Type | Description |
|---|---|---|---|
| `show_admin` | `true` | bool (`~= "false"`) | Show admin panel and keeper controls in the sidebar |
| `start_nav_open` | `false` | bool (`== "true"`) | Navigation drawer open by default (collapsed shows icons only) |
| `hide_nav_bar` | `false` | bool (`== "true"`) | Completely hide the left navigation sidebar |
| `disable_right_panel` | `false` | bool (`== "true"`) | Disable the right sidebar panel |
| `allow_select_model` | `false` | bool (`== "true"`) | Allow LLM model selection dropdown in chat |
| `session_type` | `non-persistent` | string | Chat session persistence (`non-persistent` or `cookie`) |
| `history_mode` | `hash` | string | Browser history mode (`hash` or `history`/`browser`) |

> **Boolean parsing:** `show_admin` defaults to `true` (any value except `"false"` is truthy). All other boolean flags default to `false` (only `"true"` is truthy). This is implemented in `config_handler.lua`.

### Auth

| Requirement | Default | Description |
|---|---|---|
| `login_path` | `/login.html` | Path to redirect unauthenticated users (no token in localStorage) |

### Theming & Customization

Passed to the Web Host as `customization.*` — control visual appearance across all host-rendered pages and web components.

| Requirement | Default | Config path | Description |
|---|---|---|---|
| `custom_css` | Poppins font `@import` | `customization.custom_css` | Raw CSS string injected as `<style>` into host and child iframes. Use for font imports, body font-family, and custom rules. |
| `css_variables` | `{}` | `customization.css_variables` | JSON object of CSS custom properties (e.g. `{"--p-primary":"#6366f1"}`). Injected as `:root { --key: value; }` overrides. Supports `@dark` and `@light` variants. |
| `icons` | `{}` | `customization.icons` | JSON object of custom Iconify icons (e.g. `{"logo":{"body":"<svg>...</svg>","width":24,"height":24}}`). Registered under `custom:` prefix — use as `custom:logo`. |

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

### Custom icons

```yaml
    - name: icons
      value: '{"logo":{"body":"<svg viewBox=\"0 0 24 24\"><path d=\"M12 2L2 22h20L12 2z\"/></svg>","width":24,"height":24}}'
    - name: app_icon
      value: "custom:logo"
```

## Config Response

`GET /api/public/facade/config` returns:

```json
{
  "facade_url": "https://web-host.wippy.ai/webcomponents-1.0.16",
  "iframe_origin": "https://web-host.wippy.ai",
  "iframe_url": "https://web-host.wippy.ai/webcomponents-1.0.16/iframe.html?waitForCustomConfig",
  "api_url": "http://localhost:8085",
  "ws_url": "ws://localhost:8085",
  "feature": {
    "session_type": "non-persistent",
    "history_mode": "hash",
    "show_admin": true,
    "allow_select_model": false,
    "start_nav_open": false,
    "hide_nav_bar": false,
    "disable_right_panel": false
  },
  "customization": {
    "custom_css": "@import url('https://fonts.googleapis.com/css2?family=Poppins...');",
    "css_variables": {},
    "i18n": { "app": { "title": "Wippy", "icon": "wippy:logo", "appName": "Wippy AI" } },
    "icons": {}
  },
  "login_path": "/login.html"
}
```

### How `index.html` uses the config

```
fetch /api/public/facade/config
  → check localStorage for auth token → redirect to login_path if missing
  → import(facade_url + '/module.js') → load Web Host bundle from CDN
  → initWippyApp({ auth, feature, customization }, '#app')
  → listen for 'authExpired' and 'error' events → redirect to login_path
```

If any step fails (config fetch, CDN import, missing `initWippyApp`), the page shows a styled error message with a Retry button. No external CSS is required for the loader/error UI.

## Web Host options not exposed by facade

The Web Host (`initWippyApp`) supports additional options that are intentionally not wired as facade requirements because they are advanced or context-specific:

- `hideSessionSelector` — hide session picker dropdown
- `apiRoutes` — override API endpoint paths
- `axiosDefaults` — custom HTTP client defaults
- `routePrefix` — prefix for internal route links (facade passes `api_url` as `routePrefix`)
- `chat.convertPasteToFile` — auto-convert pasted content to file uploads
- `allowAdditionalTags` — HTML sanitizer tag whitelist
- `externalEvents` — cross-origin event bridging

These can be set by directly modifying `index.html` or by creating a custom facade entry.

## Publishing

```bash
cd src/facade && wippy publish
```

The `wippy.yaml` includes `embed: ["public_files"]` to bundle `index.html` into the wapp package.
