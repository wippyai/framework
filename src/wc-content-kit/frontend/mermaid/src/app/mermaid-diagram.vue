<script setup lang="ts">
import { computed, ref, useTemplateRef, watchEffect } from 'vue'
import { renderMermaidSVG } from 'beautiful-mermaid'
import { useContent } from '@wippy-fe/webcomponent-vue'
import { useComponentProps } from '../constants'

type Render =
  | { kind: 'empty' }
  | { kind: 'svg', svg: string }
  | { kind: 'error', message: string }
  | { kind: 'loading' }

const props = useComponentProps()
const content = useContent()
const rootEl = useTemplateRef<HTMLElement>('rootEl')

const definition = computed(() =>
  (props.value.definition || content.value || '').trim()
)

const render = ref<Render>({ kind: 'empty' })

function beautifulOpts() {
  return {
    bg: 'var(--p-content-background)',
    fg: 'var(--p-text-color)',
    accent: 'var(--p-primary-500)',
    line: 'var(--p-surface-400)',
    muted: 'var(--p-text-muted-color)',
    surface: 'var(--p-content-background)',
    border: 'var(--p-content-border-color)',
    transparent: props.value.transparent ?? true,
  }
}

watchEffect(async (onCleanup) => {
  const def = definition.value
  if (!def) {
    render.value = { kind: 'empty' }
    return
  }

  // Tier 1: beautiful-mermaid (sync, already in this bundle).
  try {
    render.value = { kind: 'svg', svg: renderMermaidSVG(def, beautifulOpts()) }
    return
  }
  catch {
    // Fall through to async fallback.
  }

  // Tier 2: official mermaid, lazy-loaded via dynamic import.
  // The fallback module ITSELF is dynamically imported so its
  // `import('mermaid')` graph stays entirely off the entry's static
  // graph — otherwise mermaid + beautiful-mermaid's shared deps force
  // Rollup to emit an entry facade, which moves
  // `define(import.meta.url, …)` into a sub-chunk whose URL lacks the
  // `?declare-tag=` query and silently breaks WC registration.
  let stale = false
  onCleanup(() => { stale = true })
  render.value = { kind: 'loading' }
  try {
    // rootEl is non-null here — this branch only fires after first render.
    const host = rootEl.value ?? document.documentElement
    const { renderWithMermaid } = await import('./mermaid-fallback')
    const svg = await renderWithMermaid(def, host)
    if (!stale)
      render.value = { kind: 'svg', svg }
  }
  catch (err) {
    if (!stale) {
      const message = err instanceof Error ? err.message : String(err)
      render.value = { kind: 'error', message }
    }
  }
})
</script>

<template>
  <div ref="rootEl">
    <div
      v-if="render.kind === 'loading'"
      class="mermaid-loading"
      role="status"
    >
      Rendering diagram…
    </div>
    <div
      v-else-if="render.kind === 'error'"
      class="mermaid-error"
      role="alert"
    >
      {{ render.message }}
    </div>
    <div
      v-else-if="render.kind === 'svg'"
      class="mermaid-container"
      role="img"
      aria-label="Mermaid diagram"
      v-html="render.svg"
    />
  </div>
</template>
