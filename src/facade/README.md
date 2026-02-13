# wippy/facade

Portable iframe facade for the Wippy frontend. Serves a thin HTML shell that loads the Wippy frontend bundle from a CDN via iframe, with all configuration driven through `ns.requirement` entries.

## How it works

1. `index.html` is served as a static file via `http.static`
2. On load, it fetches `GET /api/public/facade/config` to get runtime configuration
3. Checks `localStorage` for an auth token, redirects to `login_path` if missing
4. Creates an iframe pointing to the CDN-hosted frontend bundle
5. Bridges auth and routing between the host page and the iframe via `postMessage`

API URL and WebSocket URL are derived from the `domain` requirement. If `domain` is empty, the browser falls back to `window.location`.

## Requirements

### Infrastructure

| Requirement | Default | Description |
|---|---|---|
| `server` | _(required)_ | HTTP server for static serving |
| `router` | _(required)_ | Public router for config endpoint |

### Core

| Requirement | Default | Description |
|---|---|---|
| `domain` | _(empty)_ | Canonical app domain (e.g. `localhost:8085`, `app.wippy.ai`). Derives API and WS URLs. |
| `fe_facade_url` | `https://web-host.wippy.ai/webcomponents-2026.01.14-010` | CDN base URL for frontend bundle |
| `fe_entry_path` | `/iframe.html` | Entry point path within the bundle |

### App Identity

| Requirement | Default | Description |
|---|---|---|
| `app_title` | `Wippy` | Sidebar title |
| `app_name` | `Wippy AI` | Full app name |
| `app_icon` | `wippy:logo` | Iconify icon reference |

### Feature Flags

| Requirement | Default | Description |
|---|---|---|
| `show_admin` | `true` | Show admin panel and keeper controls in the sidebar |
| `start_nav_open` | `false` | Navigation drawer open by default (collapsed shows icons only) |
| `hide_nav_bar` | `false` | Completely hide the left navigation sidebar |
| `disable_right_panel` | `false` | Disable the right sidebar panel |
| `allow_select_model` | `false` | Allow LLM model selection |
| `session_type` | `non-persistent` | Chat session persistence (`non-persistent` or `persistent`) |
| `history_mode` | `hash` | Browser history mode (`hash` or `history`) |

### Auth & Theming

| Requirement | Default | Description |
|---|---|---|
| `login_path` | `/login.html` | Unauthenticated redirect path |
| `custom_css` | Poppins font import | Custom CSS injected into iframe config |

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
    - name: domain
      value: localhost:8085
```

Only override what differs from defaults.

### Page-only app (no chat sidebar)

```yaml
    - name: hide_nav_bar
      value: "true"
    - name: disable_right_panel
      value: "true"
    - name: show_admin
      value: "false"
```

## Config Response

`GET /api/public/facade/config` returns:

```json
{
  "facade_url": "https://web-host.wippy.ai/webcomponents-2026.01.14-010",
  "iframe_origin": "https://web-host.wippy.ai",
  "iframe_url": "https://web-host.wippy.ai/webcomponents-2026.01.14-010/iframe.html?waitForCustomConfig",
  "api_url": "http://localhost:8086",
  "ws_url": "ws://localhost:8086",
  "feature": {
    "session_type": "non-persistent",
    "history_mode": "hash",
    "show_admin": false,
    "allow_select_model": false,
    "start_nav_open": false,
    "hide_nav_bar": false,
    "disable_right_panel": false
  },
  "customization": {
    "custom_css": "...",
    "css_variables": [],
    "i18n": { "app": { "title": "...", "icon": "...", "appName": "..." } },
    "icons": []
  },
  "login_path": "/api/public/auth/login"
}
```

## Publishing

```bash
cd src/facade && wippy publish
```

The `wippy.yaml` includes `embed: ["public_files"]` to bundle `index.html` into the wapp package.
