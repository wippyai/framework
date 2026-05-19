# wc-content-kit

**Three auto-registered Wippy web components for rendering rich content.**

This module ships:

- `<wippy-mermaid>` — renders any Mermaid v11 diagram
- `<wippy-markdown>` — renders GitHub-Flavored Markdown to safe HTML
- `<wippy-chartjs>` — renders any Chart.js v4 chart from a single tag

Drop the module into any Wippy app via `kind: ns.dependency`. On next start the three custom elements are auto-registered and survive the chat sanitizer — no copy-paste, no per-app wiring.

---

## Integration

Add the dependency to your app's `_index.yaml` (or wherever you declare module deps):

```yaml
- name: wc-content-kit
  kind: ns.dependency
  component: wippy/wc-content-kit
  version: ">=v0.1.0"
  parameters:
    - name: server
      value: app:gateway
```

After restart:

- `GET /components/list?auto_register=true` includes `wippy-mermaid`, `wippy-markdown`, `wippy-chartjs`
- The host injects a `<script type="module">` per component on page load, calling `customElements.define(...)`
- Sanitize-html in chat content is fed each component's prop names so authored tags survive sanitization
- The static bundles are served at `/wippy/wc-content-kit/{mermaid,markdown,chartjs}/`

That's it. Authored tags (e.g. `<wippy-mermaid definition="...">`) work everywhere chat content is rendered.

---

## `<wippy-mermaid>` — Mermaid diagram renderer

Renders any Mermaid v11 diagram from a `definition` attribute.

### Attributes

| Attribute | Type | Default | Required | Description |
|---|---|---|---|---|
| `definition` | string | `""` | yes | Mermaid v11 diagram source. Newlines must be real LF characters in the attribute value. |
| `transparent` | boolean | `true` | no | Whether the diagram background is transparent. Set `"false"` to render on a solid card. |

### Supported diagram types

`flowchart`, `sequenceDiagram`, `classDiagram`, `stateDiagram`, `erDiagram`, `journey`, `gantt`, `pie`, `mindmap`, `timeline`, `gitGraph`, `quadrantChart`, `requirementDiagram`, `sankey`, `xychart`, `block`, `packet`, `kanban`, `architecture`, `radar`.

The fast primary engine handles flowchart / sequence / class / state / ER / xychart. Less common types load a heavier renderer on first use (one-time delay).

### Examples

**Flowchart:**

```html
<wippy-mermaid definition="flowchart LR
  Start([User opens app]) --> Auth{Token present?}
  Auth -- yes --> Home[Home screen]
  Auth -- no --> Login[Login form]
  Login --> Auth" />
```

**Sequence diagram (3 actors):**

```html
<wippy-mermaid definition="sequenceDiagram
  participant U as User
  participant H as Host
  participant C as Child iframe
  U->>H: load page
  H->>C: SetConfig
  C-->>H: GetConfig
  H-->>U: render" />
```

**Class diagram:**

```html
<wippy-mermaid definition="classDiagram
  class Animal {
    +String name
    +int age
    +makeSound()
  }
  class Dog {
    +bark()
  }
  class Cat {
    +meow()
  }
  Animal <|-- Dog
  Animal <|-- Cat" />
```

**State diagram:**

```html
<wippy-mermaid definition="stateDiagram-v2
  [*] --> Idle
  Idle --> Loading: fetch
  Loading --> Ready: success
  Loading --> Error: failure
  Ready --> [*]
  Error --> Idle: retry" />
```

**ER diagram (one-to-many):**

```html
<wippy-mermaid definition="erDiagram
  CUSTOMER ||--o{ ORDER : places
  ORDER ||--|{ LINE-ITEM : contains
  CUSTOMER {
    string name
    string email
  }
  ORDER {
    int orderNumber
    date createdAt
  }" />
```

**Gantt chart (with sections):**

```html
<wippy-mermaid definition="gantt
  title Project schedule
  dateFormat YYYY-MM-DD
  section Design
  Mockups       :a1, 2026-05-01, 7d
  Review        :a2, after a1, 3d
  section Build
  Implementation :b1, after a2, 14d
  QA             :b2, after b1, 5d" />
```

**Pie chart:**

```html
<wippy-mermaid definition='pie title Where time goes
  "Sleep" : 33
  "Work"  : 30
  "Other" : 37' />
```

The example above uses a single-quoted attribute (`definition='...'`) so the inner double quotes pass through literally. If you wrap with double quotes instead (`definition="..."`), replace the inner `"` with `&quot;`.

**Mindmap:**

```html
<wippy-mermaid definition="mindmap
  root((wc-content-kit))
    mermaid
      flowchart
      sequence
      pie
    markdown
      GFM
      sanitization
    chartjs
      line
      bar
      doughnut" />
```

**gitGraph:**

```html
<wippy-mermaid definition="gitGraph
  commit
  commit
  branch feature
  checkout feature
  commit
  commit
  checkout main
  merge feature
  commit" />
```

### Newlines in attributes

The `definition` attribute must contain real LF characters. Both forms work:

- Literal newlines in the source HTML (e.g. inside an HTML file):
  ```html
  <wippy-mermaid definition="flowchart LR
    A --> B" />
  ```
- HTML numeric character reference `&#10;` (useful when emitting from code):
  ```html
  <wippy-mermaid definition="flowchart LR&#10;  A --> B" />
  ```

Both decode to identical attribute values. Don't emit literal `\n` (backslash-n) — that becomes the two-character sequence in the attribute, not a newline, and Mermaid won't parse it.

### Errors

Render errors surface as an inline error banner — the host never throws. JSON-style malformed source produces a small red banner with the parser message.

### Theming

`transparent="false"` renders the SVG against a solid card background. The `themeConfigUrl` host CSS is auto-loaded so palette tokens (`--p-primary-500`, etc.) are available to themed Mermaid diagrams.

---

## `<wippy-markdown>` — Markdown renderer

Renders GitHub-Flavored Markdown to safe HTML.

### Attributes

| Attribute | Type | Default | Required | Description |
|---|---|---|---|---|
| `content` | string | `""` | yes | Markdown source text to render (GFM). |
| `allowed-tags` | array (JSON string) | `[]` | no | Override the sanitizer's tag whitelist. Empty = built-in defaults. |
| `allowed-attributes` | string (JSON object) | `""` | no | JSON-stringified `{tag: [attr,...]}` map for sanitize-html. Empty = defaults. |

### GFM features supported

Headings, bold/italic, ordered/bulleted lists (nested), tables with column alignment, fenced code blocks (with `language-*` class preserved on `<code>` for host-side highlighting; no highlighter is bundled — bring your own), inline code, blockquotes, links, images, autolinks, strikethrough, horizontal rules.

> Not enabled by default: GFM task lists (`- [x]`) and footnotes — both require markdown-it plugins not bundled here.


### Examples

**Basic prose:**

```html
<wippy-markdown content="# Hello
This is **bold** and *italic* with [a link](https://example.com).

A second paragraph follows." />
```

**Heading hierarchy + inline code:**

```html
<wippy-markdown content="# Title

## Subtitle

Use `npm install` to install. Run `npm test` to test.

### Sub-subtitle

Anything `monospace` is rendered inline." />
```

**Lists (bulleted + ordered, nested):**

```html
<wippy-markdown content="### Things
- First
- Second
  - Nested
  - Also nested
- Third

### Steps
1. First
2. Second
   1. Sub-step
   2. Sub-step
3. Third" />
```

**Table with column alignment:**

```html
<wippy-markdown content="| Column A | Column B | Column C |
|:---------|:--------:|---------:|
| left     | center   | right    |
| 1        | 2        | 3        |" />
```

**Fenced code block with language:**

The `content` attribute should contain a real Markdown source string with literal triple-backtick fences. Inside an HTML attribute, JS/Python keyword characters are unescaped — only the outer attribute quote needs to be escaped.

````html
<wippy-markdown content="Here's some Python:

```python
def hello(name):
    print(f'Hello, {name}!')
```

And some JavaScript:

```js
const greet = (name) => console.log(`Hi ${name}`)
```" />
````

**Blockquote:**

```html
<wippy-markdown content="> This is a quote.
> It can span multiple lines.
>
> > And nested quotes work too." />
```

**Image:**

```html
<wippy-markdown content="![Alt text describing the image](https://example.com/image.png)" />
```

**Mermaid alongside Markdown:**

Markdown does not auto-render fenced ` ```mermaid ` blocks as embedded `<wippy-mermaid>` — they're rendered as a normal `<pre><code>` code block. To embed a diagram, sit a `<wippy-mermaid>` next to the markdown in the same DOM:

```html
<wippy-markdown content="## My Diagram

The diagram below shows the auth flow." />

<wippy-mermaid definition="flowchart LR
  A --> B --> C"></wippy-mermaid>
```

**Mixed (blog-post-shaped):**

```html
<wippy-markdown content="# Release notes — 1.0.26

Two main changes this release:

1. **Deep capture** — clipboard handling now uses capture-phase listeners.
2. **Loading components** — `<wippy-loading>` is now standardized.

| Component | Version |
|-----------|--------:|
| host      | 1.0.26  |
| proxy     | 0.0.26  |

> See the full changelog at [CHANGELOG.md](./CHANGELOG.md)." />
```

### Sanitization model

The component runs the parsed HTML through [sanitize-html](https://github.com/apostrophecms/sanitize-html) with a conservative default allowlist. The `allowed-tags` / `allowed-attributes` props widen what survives sanitization for tags markdown-it emits (e.g. enabling extra inline tags or attributes on existing ones):

```html
<wippy-markdown
  content="Some markdown with **bold** and inline code..."
  allowed-attributes='{"a":["href","title","target","rel"],"code":["class","data-lang"]}' />
```

> **Note:** raw HTML embedded in the markdown source (e.g. `<details>` inside the `content`) is stripped at the parser stage by markdown-it (we run with `html: false`); widening `allowed-tags` does NOT re-enable raw HTML pass-through.

> **Security caveat:** widening the allowlist is a security decision. **Do not widen it for untrusted markdown** — anything you allow can be emitted by the source, including JS-bearing attributes and tags. The default allowlist is safe for arbitrary input.

---

## `<wippy-chartjs>` — Chart.js (universal)

Renders any Chart.js v4 chart from a single tag. All controllers, scales, elements, and built-in plugins are pre-registered so any chart type works without per-type setup.

### Attributes

| Attribute | Type | Default | Required | Description |
|---|---|---|---|---|
| `type` | enum | `"doughnut"` | yes | One of: `line`, `bar`, `doughnut`, `pie`, `radar`, `polarArea`, `scatter`, `bubble`. |
| `data` | string (JSON) | `""` | yes | JSON-stringified Chart.js Data object: `{ labels?, datasets: [{label?, data, ...}] }`. |
| `options` | string (JSON) | `""` | no | JSON-stringified Chart.js Options object. |
| `plugins` | string (JSON) | `""` | no | JSON-stringified array of Chart.js plugin definitions. |

### Supported chart types

| Type | Best for |
|---|---|
| `line` | Trends over time |
| `bar` | Categorical comparison |
| `doughnut` | Parts of a whole (≤7 categories), with a hole |
| `pie` | Parts of a whole (≤7 categories), full slice |
| `radar` | Multi-axis comparison of 1-N entities |
| `polarArea` | Categorical with magnitude (radial) |
| `scatter` | x/y point clouds |
| `bubble` | x/y/r 3-dimensional data |

### Examples

**Line — month-over-month revenue:**

```html
<wippy-chartjs
  type="line"
  data='{
    "labels": ["Jan","Feb","Mar","Apr","May","Jun"],
    "datasets": [
      {"label":"2025","data":[100,150,180,210,240,260]},
      {"label":"2026","data":[130,170,200,240,290,320]}
    ]
  }'
  options='{"responsive":true,"plugins":{"title":{"display":true,"text":"Monthly revenue"}}}' />
```

**Bar — category comparison with two datasets:**

```html
<wippy-chartjs
  type="bar"
  data='{
    "labels": ["Q1","Q2","Q3","Q4"],
    "datasets": [
      {"label":"Revenue","data":[12,19,7,22]},
      {"label":"Cost",   "data":[ 6, 8,5,11]}
    ]
  }' />
```

**Doughnut — market share with 4 segments:**

```html
<wippy-chartjs
  type="doughnut"
  data='{
    "labels": ["Chrome","Safari","Firefox","Edge"],
    "datasets": [{"data":[63,18,4,15]}]
  }' />
```

**Pie — same data, full-slice form:**

```html
<wippy-chartjs
  type="pie"
  data='{
    "labels": ["Chrome","Safari","Firefox","Edge"],
    "datasets": [{"data":[63,18,4,15]}]
  }' />
```

**Radar — skill ratings on 5 axes:**

```html
<wippy-chartjs
  type="radar"
  data='{
    "labels": ["Speed","Reliability","Comfort","Safety","Efficiency"],
    "datasets": [
      {"label":"Model A","data":[8,9,7,8,6]},
      {"label":"Model B","data":[7,8,9,7,8]}
    ]
  }' />
```

**Polar area — value-driven categorical:**

```html
<wippy-chartjs
  type="polarArea"
  data='{
    "labels": ["Read","Write","Discuss","Build"],
    "datasets": [{"data":[11, 16, 7, 14]}]
  }' />
```

**Scatter — point cloud with two series:**

```html
<wippy-chartjs
  type="scatter"
  data='{
    "datasets": [
      {"label":"Set A","data":[{"x":1,"y":2},{"x":2,"y":4},{"x":3,"y":3},{"x":4,"y":5}]},
      {"label":"Set B","data":[{"x":1,"y":3},{"x":2,"y":3},{"x":3,"y":4}]}
    ]
  }' />
```

**Bubble — 3-dimensional data (x, y, r):**

```html
<wippy-chartjs
  type="bubble"
  data='{
    "datasets": [
      {"label":"Population","data":[
        {"x":10,"y":20,"r":15},
        {"x":20,"y":10,"r":8},
        {"x":30,"y":30,"r":22}
      ]}
    ]
  }' />
```

### Data shape primer

`data` is the standard Chart.js v4 [Data object](https://www.chartjs.org/docs/latest/general/data-structures.html). `options` follows [Chart.js Options](https://www.chartjs.org/docs/latest/configuration/). `plugins` is the standard Chart.js [plugins array](https://www.chartjs.org/docs/latest/developers/plugins.html). All three pass straight through after JSON.parse.

### Theme integration

When a dataset omits `backgroundColor` (and `borderColor` for line/bar/radar/scatter/bubble), the component fills it from the host's CSS palette:

- Primary: `--p-primary-500` → `--p-primary-300`
- Danger: `--p-danger-500` → `--p-danger-300`
- Warning: `--p-warn-500` → `--p-warn-300`
- Secondary: `--p-secondary-500` → `--p-secondary-300`
- Accent: `--p-accent-500` → `--p-accent-300`

Falls back to a hardcoded indigo/red/yellow palette if the CSS variables aren't defined. Override per-dataset to force exact colors:

```html
<wippy-chartjs
  type="bar"
  data='{
    "labels": ["A","B","C"],
    "datasets": [{"label":"Custom","data":[10,20,30],"backgroundColor":"#3b82f6"}]
  }' />
```

### Sizing

The canvas is responsive by default. Control the chart's dimensions by sizing the wrapping element:

```html
<div style="height: 300px;">
  <wippy-chartjs type="bar" data='...'></wippy-chartjs>
</div>
```

### Custom plugins

The component bundles only Chart.js's built-in registerables. The `plugins` attribute carries inline plugin definitions parsed from JSON — useful only for declarative plugin config (no functions). To use a functional third-party plugin (e.g. `chartjs-plugin-datalabels`), the consumer must `Chart.register(plugin)` from another script that runs before the chart mounts. There is no way to pass a function-bearing plugin through this attribute.

---

## AI agent prompting notes

When emitting these tags from an AI agent into chat content:

- **Escape JSON properly in `data` / `options` / `plugins`.** These are HTML attributes containing JSON strings — outer quotes are single, inner quotes are double, and inner double quotes inside string values must be HTML-escaped or the markup breaks.
- **Keep `definition` short on Mermaid.** Diagrams over ~50 nodes can take noticeable time to render. Prefer multiple smaller diagrams over one giant one.
- **Prefer `<wippy-chartjs>` over inlining ASCII bar charts** in chat. The chart is interactive (tooltips, legend toggles) and respects the user's theme.
- **Prefer real LF characters in `definition`** over `&#10;`. Both work, but real newlines are easier for humans to read.
- **`<wippy-markdown content="...">` is the right tool for any rich text** — headings, lists, tables. Don't manually emit `<h1>` / `<table>` HTML; let the component do it.

---

## Build / develop

```bash
make build          # build all three components
make clean          # remove node_modules and built bundles
make clean-build    # full rebuild from scratch

make build-mermaid  # per-component
make build-markdown
make build-chartjs
```

Build outputs land in `public/{mermaid,markdown,chartjs}/`. The `http.static` entry in `_index.yaml` serves them at `/wippy/wc-content-kit/{name}/`.

Source code is under `frontend/{name}/src/`. Each component is a standard Vite-built Vue web component using `@wippy-fe/webcomponent-vue` as the base class.
