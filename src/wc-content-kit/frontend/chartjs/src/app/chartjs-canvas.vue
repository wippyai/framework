<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { Chart, registerables, type ChartConfiguration } from 'chart.js'
import { DEFAULT_DATA, DEFAULT_TYPE, useComponentProps } from '../constants'

// Register every controller, scale, element, and built-in plugin so the
// component can render any Chart.js v4 chart type without per-type setup.
// Idempotency guard: Chart.register warns on duplicate registration; we skip
// the call when something is already registered (the registerables collection
// always includes BarController, so it's a reliable sentinel).
if (!Chart.registry.controllers.get('bar'))
  Chart.register(...registerables)

const props = useComponentProps()

const canvasRef = ref<HTMLCanvasElement | null>(null)
const buildErr = ref<string | null>(null)
let chart: Chart | null = null

const PIE_LIKE = new Set(['pie', 'doughnut', 'polarArea'])

// Pull the host theme palette so charts respect the user's brand colors
// when datasets omit `backgroundColor` / `borderColor`. Falls back to the
// hardcoded indigo/red/yellow set if CSS variables aren't defined.
function getThemeColors(): string[] {
  // Read theme vars from the shadow root host (where @wippy-fe/theme/theme-config.css
  // is inlined) with documentElement as a fallback for non-shadow contexts.
  // Guard: getRootNode() returns the canvas itself if it's not yet connected.
  const root = canvasRef.value?.getRootNode()
  const host = root instanceof ShadowRoot
    ? root.host
    : root instanceof Document
      ? root.documentElement
      : document.documentElement
  const cs = getComputedStyle(host)
  const get = (v: string, fallback: string) => cs.getPropertyValue(v).trim() || fallback
  return [
    get('--p-primary-500', '#6366f1'),
    get('--p-danger-500', '#ef4444'),
    get('--p-warn-500', '#eab308'),
    get('--p-secondary-500', '#64748b'),
    get('--p-accent-500', '#a855f7'),
    get('--p-primary-300', '#a5b4fc'),
    get('--p-danger-300', '#fca5a5'),
    get('--p-warn-300', '#fde047'),
    get('--p-secondary-300', '#cbd5e1'),
    get('--p-accent-300', '#d8b4fe'),
  ]
}

function applyThemeFallback(cfg: ChartConfiguration, palette: string[]): void {
  const datasets = (cfg.data?.datasets ?? []) as Array<Record<string, unknown>>
  const isPieLike = PIE_LIKE.has(String(cfg.type))
  for (let i = 0; i < datasets.length; i++) {
    const ds = datasets[i]
    if (isPieLike) {
      if (ds.backgroundColor === undefined) {
        const n = Array.isArray(ds.data) ? ds.data.length : 0
        ds.backgroundColor = Array.from({ length: n }, (_, j) => palette[j % palette.length])
      }
    }
    else {
      const color = palette[i % palette.length]
      if (ds.backgroundColor === undefined)
        ds.backgroundColor = color
      if (ds.borderColor === undefined)
        ds.borderColor = color
    }
  }
}

interface ParseResult {
  cfg: ChartConfiguration | null
  error: string | null
}

const config = computed<ParseResult>(() => {
  const type = (props.value.type ?? DEFAULT_TYPE) as ChartConfiguration['type']
  const dataStr = props.value.data ?? DEFAULT_DATA
  let data: ChartConfiguration['data']
  let options: ChartConfiguration['options'] = {}
  let plugins: ChartConfiguration['plugins'] = []
  try {
    data = JSON.parse(dataStr)
  }
  catch (e) {
    return { cfg: null, error: `Invalid data JSON: ${(e as Error).message}` }
  }
  if (props.value.options) {
    try {
      options = JSON.parse(props.value.options)
    }
    catch (e) {
      return { cfg: null, error: `Invalid options JSON: ${(e as Error).message}` }
    }
  }
  if (props.value.plugins) {
    try {
      plugins = JSON.parse(props.value.plugins)
    }
    catch (e) {
      return { cfg: null, error: `Invalid plugins JSON: ${(e as Error).message}` }
    }
  }
  return { cfg: { type, data, options, plugins }, error: null }
})

// Show parse errors immediately on first paint and Chart.js errors after build.
const errorMsg = computed(() => buildErr.value ?? config.value.error)

function build() {
  buildErr.value = null
  const parsed = config.value.cfg
  if (!canvasRef.value || !parsed)
    return
  // Shallow-clone the cfg and deep-clone only the data graph so the theme
  // fallback never mutates the agent-supplied JSON. Note: `plugins` here
  // are inline plugin definitions parsed from the JSON attribute — they
  // contain only declarative fields (no functions), since JSON can't carry
  // function values. Pass-through-by-reference is fine.
  // Defaults: responsive + maintainAspectRatio:false so the chart fills the
  // host-sized wrapper instead of locking to canvas's natural aspect ratio.
  // Both are caller-overridable via props.options.
  const cfg: ChartConfiguration = {
    ...parsed,
    data: JSON.parse(JSON.stringify(parsed.data)),
    options: {
      responsive: true,
      maintainAspectRatio: false,
      ...(parsed.options ?? {}),
    },
  }
  applyThemeFallback(cfg, getThemeColors())
  try {
    chart = new Chart(canvasRef.value, cfg)
  }
  catch (e) {
    buildErr.value = `Chart.js error: ${(e as Error).message}`
  }
}

function destroy() {
  chart?.destroy()
  chart = null
}

onMounted(build)
onUnmounted(destroy)
watch(config, () => {
  destroy()
  build()
})
</script>

<template>
  <div class="chartjs-container">
    <div v-if="errorMsg" class="chartjs-error" role="alert">
      {{ errorMsg }}
    </div>
    <div v-else class="chartjs-canvas-wrapper">
      <canvas
        ref="canvasRef"
        role="img"
      />
    </div>
  </div>
</template>
