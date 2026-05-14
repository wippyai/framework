/**
 * Lazy-loaded fallback renderer using the official `mermaid` package.
 *
 * Only fetched when `beautiful-mermaid` throws on an unsupported diagram
 * type (pie, gantt, mindmap, journey, gitGraph, quadrant, timeline,
 * sankey, c4, requirement, packet, …). The dynamic `import('mermaid')`
 * is code-split by Vite into its own chunk, so the primary bundle stays
 * lean and the heavy lib only downloads when actually needed. Cached
 * module-level so all `<wippy-mermaid>` instances share one fetch.
 *
 * Safe to use here because the entry's `define(pkg.wippy.tagName, …)` no
 * longer depends on `import.meta.url`, so Vite's code-splitting can move
 * dynamic chunks freely without breaking custom-element registration.
 */

let mermaidPromise: Promise<typeof import('mermaid').default> | null = null

function loadMermaid() {
  if (!mermaidPromise) {
    mermaidPromise = import('mermaid').then(m => m.default)
  }
  return mermaidPromise
}

/**
 * Read Wippy theme tokens off the host element's computed style and map
 * them to mermaid's `themeVariables`. Mermaid bakes the resolved colors
 * into the SVG output, so we must hand it concrete strings —
 * `var(--p-…)` doesn't propagate inside the rendered SVG.
 *
 * CSS custom properties cross the shadow-DOM boundary, so any element
 * inside the WC's shadow root resolves the same `--p-*` values that the
 * outer page declared at `:root`.
 */
function readThemeVars(hostEl: HTMLElement): Record<string, string> {
  const cs = getComputedStyle(hostEl)
  const v = (name: string) => cs.getPropertyValue(name).trim()
  const fontFamily = v('font-family') || 'inherit'
  return {
    background: v('--p-content-background'),
    primaryColor: v('--p-primary-500'),
    primaryTextColor: v('--p-text-color'),
    primaryBorderColor: v('--p-content-border-color'),
    lineColor: v('--p-surface-400'),
    secondaryColor: v('--p-surface-100'),
    tertiaryColor: v('--p-surface-50'),
    secondaryTextColor: v('--p-text-muted-color'),
    tertiaryTextColor: v('--p-text-muted-color'),
    noteBkgColor: v('--p-surface-100'),
    noteTextColor: v('--p-text-color'),
    noteBorderColor: v('--p-content-border-color'),
    fontFamily,
  }
}

export async function renderWithMermaid(definition: string, hostEl: HTMLElement): Promise<string> {
  const mermaid = await loadMermaid()
  // `base` is the only built-in theme that respects `themeVariables`.
  // `securityLevel: 'strict'` disables HTML labels — content treated as
  // plain text. Re-initialize on every render so theme changes propagate
  // (cheap; mermaid stores config on a singleton).
  mermaid.initialize({
    startOnLoad: false,
    theme: 'base',
    securityLevel: 'strict',
    themeVariables: readThemeVars(hostEl),
  })
  const id = `m-${Math.random().toString(36).slice(2, 10)}`
  const { svg } = await mermaid.render(id, definition)
  return svg
}
