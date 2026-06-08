<p align="center">
    <a href="https://wippy.ai" target="_blank">
        <picture>
            <source media="(prefers-color-scheme: dark)" srcset="https://github.com/wippyai/.github/blob/main/logo/wippy-text-dark.svg?raw=true">
            <img width="30%" align="center" src="https://github.com/wippyai/.github/blob/main/logo/wippy-text-light.svg?raw=true" alt="Wippy logo">
        </picture>
    </a>
</p>
<h1 align="center">Views Module</h1>
<div align="center">

[![Latest Release](https://img.shields.io/github/v/release/wippyai/module-views?style=flat-square)][releases-page]
[![License](https://img.shields.io/github/license/wippyai/module-views?style=flat-square)](LICENSE)
[![Documentation](https://img.shields.io/badge/Wippy-Documentation-brightgreen.svg?style=flat-square)][wippy-documentation]

</div>

> [!NOTE]
> This repository is read-only.
> The code is generated from the [wippyai/framework][wippy-framework] repository.

[wippy-documentation]: https://docs.wippy.ai
[releases-page]: https://github.com/wippyai/module-views/releases
[wippy-framework]: https://github.com/wippyai/framework

---

## Migrating to 0.4.32: bundled `wippy-meta.json` (Web Host ≥ 1.0.31)

Starting in `wippy/views@0.4.32`, the three view-metadata endpoints
(`/pages/content/{id}`, `/components/list`, `/components/by-tag/{tag}`)
read the consumer build's `wippy-meta.json` as the source for fields the
FE author owns. The YAML registry entry remains the **authoritative
abstraction**: it is read first, field by field, and bundled meta fills
only the gaps. The pre-0.4.32 YAML-only synthesis path stays in place as
a fallback — entries that ship no `wippy-meta.json` continue to work
unchanged.

### Resolution rule

**YAML always wins on a field-by-field basis.** Bundled meta is the
fallback for fields YAML omits. For every field below, the lookup order
is `YAML → bundled wippy-meta.json → legacy default`.

This means you can:
- **Slim a YAML entry** by removing fields the consumer's `package.json`
  already declares — the bundled meta will fill them in transparently.
- **Override any field from YAML** by setting it explicitly in the
  registry entry — operators always retain the last word.
- **Compose a themed variant** by re-pointing a registry entry at an
  existing artifact's URL and adding `meta.config_overrides` for the
  per-variant customization payload — the overlay deep-merges over the
  bundled `wippy.configOverrides`.

### Bundled `wippy-meta.json` — how to produce it

Use [`@wippy-fe/vite-plugin`][wippy-fe-vite-plugin] ≥ 0.0.31 in the
consumer's `vite.config.ts`:

```ts
import { wippyPagePlugin } from '@wippy-fe/vite-plugin'      // for view.page
// OR
import { wippyComponentPlugin } from '@wippy-fe/vite-plugin' // for view.component

export default defineConfig({
  plugins: [/* ... */, wippyPagePlugin()],
})
```

Both plugins emit `dist/wippy-meta.json` — the consumer's `package.json`
with every `file://<relative-path>` reference resolved at build time.
Non-Vite consumers (rollup, esbuild, hand-built) can produce the same
file by any equivalent build step — see
[`web_components.spec.md`][spec] § "Package metadata: source of truth"
for the contract.

[wippy-fe-vite-plugin]: https://www.npmjs.com/package/@wippy-fe/vite-plugin
[spec]: https://github.com/wippyai/gen-2-chat/blob/main/web_components.spec.md

### Field-by-field mapping

#### `view.page` → `GET /pages/content/{id}` (wippy-component-1.0 spec response)

| Response field | YAML source (priority 1) | Bundled meta source (priority 2) | Legacy default (priority 3) |
|---|---|---|---|
| `name` | `meta.name` | `<pkg>.name` (e.g. `@org/my-page`) | entry id |
| `version` | — | `<pkg>.version` | `"1.0.0"` |
| `specification` | — | `<pkg>.specification` | `"wippy-component-1.0"` |
| `title` | `meta.title` | `<pkg>.wippy.title` → `<pkg>.title` | `""` |
| `baseUrl` | (always computed from `meta.url` + `meta.base_path` + `PUBLIC_API_URL` — operator/routing decision) | | |
| `wippy.type` | (always `"page"`) | | |
| `wippy.path` | `meta.entry_point` | `<pkg>.wippy.path` | `"index.html"` |
| `wippy.proxy` | `meta.proxy` (camelCase, deep-merged ON TOP of bundled; YAML wins per nested key) | `<pkg>.wippy.proxy` (whole block) | `synthesize_from_registry` sends `meta.proxy` or a minimal `{enabled=true}` — the **FE** (`proxy.js`) defaults every injection ON |
| `wippy.configOverrides` | `meta.config_overrides` deep-merged ON TOP of bundled (YAML wins per nested key) | `<pkg>.wippy.configOverrides` | `nil` |

#### `view.component` → `GET /components/list` and `GET /components/by-tag/{tag}`

The response is a nested **camelCase** wippy-component-1.0 ESM descriptor (a valid
`PackageJsonESM`) — the FE consumes it directly, no re-assembly. Response keys:

| Response field | YAML source (priority 1) | Bundled meta source (priority 2) | Legacy default (priority 3) |
|---|---|---|---|
| `id` | (always the registry entry id) | | |
| `name` | `meta.name` | `<pkg>.name` | `""` |
| `version`, `specification` | — | `<pkg>.version` / `<pkg>.specification` | `"1.0.0"` / `"wippy-component-1.0"` |
| `title` | `meta.title` | `<pkg>.wippy.title` → `<pkg>.title` | `""` |
| `description` | `meta.description` | `<pkg>.wippy.description` → `<pkg>.description` | `nil` |
| `baseUrl` | (always computed from `meta.url` + `meta.base_path` — operator/routing decision) | | |
| `browser` | `meta.entry_point` | `<pkg>.browser` (the wippy-component-1.0 spec entry for ESM module / component packages) | `"index.js"` |
| `wippy.tagName` | `meta.tag_name` | `<pkg>.wippy.tagName` | `nil` |
| `wippy.props` | `meta.props` | `<pkg>.wippy.props` | `nil` |
| `wippy.events` | `meta.events` | `<pkg>.wippy.events` | `nil` |
| `wippy.autoRegister` | (always from `meta.auto_register` — deployment policy; bundle `wippy.autoRegister` ignored) | | |

### What to keep in YAML vs what to drop

#### YAML MUST keep (registry routing + deployment policy)

These are decisions the operator makes at registration time. They are not
in the consumer build:
- `name:` (the registry entry id — short slug, e.g. `iframe-demo`)
- `kind: registry.entry`
- `meta.type` (`view.page` / `view.component`)
- `meta.url`, `meta.base_path` (where to serve the bundle from)
- `meta.announced`, `meta.secure` (visibility + auth)
- `meta.auto_register` (component-only; deployment policy)
- `meta.mountRoute` (page-only; gen-2-chat routing)
- `meta.icon`, `meta.order`, `meta.group*` (UI metadata)
- `meta.config_overrides` (variant overlay payload — see below)

#### YAML CAN drop (covered by bundled `wippy-meta.json`)

If your build emits `wippy-meta.json`, these YAML fields are redundant
and can be removed:
- `meta.title` → comes from `package.json` `wippy.title` or top-level `title`
- `meta.tag_name` → comes from `package.json` `wippy.tagName`
- `meta.entry_point` → comes from `package.json` `wippy.path` (for `view.page`) or top-level `browser` (for `view.component`). Per [wippy-component-1.0 spec][spec], these are the canonical fields per package kind — `browser` is for ESM module / component entries, `wippy.path` is for HTML page entries. They are NOT interchangeable.
- `meta.props`, `meta.events` → come from `package.json` `wippy.props` / `wippy.events`
- proxy injections → come from `package.json` `wippy.proxy` (camelCase). For a per-entry override, set **`meta.proxy`** (camelCase payload) on the registry entry — it deep-merges ON TOP of the bundle's `wippy.proxy`, YAML winning per nested key (same overlay model as `meta.config_overrides`). `meta.proxy` is the **single** proxy field — the older snake-case `data.proxy` block has been removed. **The FE owns injection defaults:** `proxy.js` (`getProxyConfig`) defaults every injection ON when the field is absent, so an empty/minimal proxy means "all injections on". To DISABLE an injection, set it `false` in `meta.proxy` (or the bundle's `wippy.proxy`) — absence never disables. Server-rendered jet/template pages don't read a descriptor proxy; to override their injections, emit the config server-side in the page's YAML/template.

#### YAML overlay pattern (variants)

To declare a themed variant that reuses an artifact, point the registry
entry at the same `url` + `base_path` and add `meta.config_overrides` with
the per-variant customization. The YAML keys MUST be camelCase to merge
correctly with the bundled `wippy.configOverrides`:

```yaml
- name: iframe-demo-themed
  kind: registry.entry
  meta:
    type: view.page
    name: iframe-demo-themed
    title: Iframe Demo (Custom Palette)
    url: /app
    base_path: app/iframe-demo
    mountRoute: /demo-themed/:part(.*)*
    # Variant overlay — deep-merged ON TOP of bundled wippy.configOverrides.
    # YAML wins per nested key (override-only the colors you care about).
    config_overrides:
      customization:
        cssVariables:
          "--p-primary": "#7c9ed9"
          "--p-secondary": "#b4a7d6"
        customCSS: |
          @import url('https://fonts.googleapis.com/css2?family=Quicksand:wght@400;500;600;700&display=swap');
          :root, body, * { font-family: 'Quicksand', sans-serif !important; }
```

### Deprecation warnings

On the first request that observes an entry without a bundled
`wippy-meta.json`, the views module logs (once per `wippy.views`
process via a shared memory store):

> `[wippy.views] {kind} '{entry-id}' has no wippy-meta.json at {url} — falling back to YAML synthesis. Adopt @wippy-fe/vite-plugin so the consumer's package.json wippy block is the canonical source.`

The synthesis fallback is preserved indefinitely for legacy entries,
but the warning is your signal to migrate the consumer.

### Layer boundaries: who owns what

This is the principle the rest of the migration follows:

- **`package.json` is the FE-author's view. Source-relative, BE/router/FS agnostic.**
  - `wippy.path: "dist/app.html"` (for pages) and `browser: "dist/index.js"` (for components) are CORRECT — they describe where the file lives in the build output, relative to the package root. The consumer doesn't know (and shouldn't need to know) where the operator will serve it.
- **YAML is the operator's view. Deployment-aware.**
  - The operator knows the served layout (e.g. vite's `--outDir static/wc/foo/` flattens away the `dist/` prefix), and YAML's `meta.entry_point` is where the operator declares that adjustment. YAML overrides bundled meta on this field — the typical pattern is `meta.entry_point: app.html` when the package.json says `wippy.path: "dist/app.html"`.

This separation is what lets a single consumer build ship to multiple operator deployments with different served-layout shapes without rebuilding.

### Migration checklist (per registered entry)

1. Update the consumer's `vite.config.ts` to add `wippyPagePlugin()` (page) or `wippyComponentPlugin()` (component).
2. **Leave `package.json` entry paths source-relative** — `wippy.path: "dist/app.html"` for pages, top-level `browser: "dist/index.js"` for components. The FE author shouldn't encode the operator's deployment layout in their package manifest.
3. Build the consumer — confirm `dist/wippy-meta.json` is emitted.
4. Deploy the new build (the published wippy module or the served static dir).
5. **Set `meta.entry_point` in YAML to match the SERVED layout.** If your build pipeline strips the `dist/` prefix (typical with vite's `--outDir <served-path>`), declare it in YAML: `meta.entry_point: app.html` (for pages) or `meta.entry_point: index.js` (for components). YAML wins, bundled meta is the fallback for fields YAML omits — so this works regardless of what `package.json` declared.
6. Restart wippy and observe that the deprecation warning for this entry stops firing.
7. Slim the YAML registry entry — you can drop fields covered by bundled meta (`title`, `props`, `events`). Keep routing + policy fields, and keep `meta.entry_point` for the deployment-aware path adjustment. **`tag_name` for components**: optional — if omitted, views falls back to a scan of bundled meta files matching `wippy.tagName`. Keep it in YAML if you want the O(1) registry index lookup; drop it if the consumer's `wippy.tagName` is the only source of truth you want.
8. Restart wippy. Probe the API endpoint and confirm the response shape is unchanged from before slimming.

### What's NOT in scope for 0.4.32

- **No structural changes to YAML schema.** Existing YAML entries keep working without any edit.
- **No removal of the synthesize fallback.** Legacy entries (no `wippy-meta.json`) render exactly as before.
- **No automatic case conversion.** YAML `meta.config_overrides.*` and bundled `wippy.configOverrides.*` are merged key-for-key; both sides MUST use camelCase for the customization payload (already the convention in both layers).

[releases-page]: https://github.com/wippyai/module-views/releases
[wippy-documentation]: https://docs.wippy.ai
[wippy-framework]: https://github.com/wippyai/framework
