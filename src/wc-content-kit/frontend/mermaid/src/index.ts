import { WippyVueElement, define } from '@wippy-fe/webcomponent-vue'
import type { WippyElementConfig, WippyPropsSchema } from '@wippy-fe/webcomponent-vue'
import type { ComponentProps } from './types.ts'
import type { Events } from './constants.ts'
import MermaidDiagram from './app/mermaid-diagram.vue'
import stylesText from './styles.css?inline'
import pkg from '../package.json'

class MermaidElement extends WippyVueElement<ComponentProps, Events> {
  static get wippyConfig(): WippyElementConfig<ComponentProps> {
    return {
      propsSchema: pkg.wippy.props as WippyPropsSchema,
      hostCssKeys: ['themeConfigUrl'] as const,
      inlineCss: stylesText,
      contentTemplate: 'text/vnd.mermaid',
    }
  }

  static get vueConfig() {
    return {
      rootComponent: MermaidDiagram,
    }
  }
}

export async function webComponent() {
  return MermaidElement
}

// `define(import.meta.url, …)` reads the `?declare-tag=` query the
// autoload script appends to the entry URL. With dynamic imports in
// the entry graph (mermaid fallback), Vite lib mode would normally
// emit a 175-byte facade re-exporting from a sub-chunk that owns this
// statement — and `import.meta.url` would resolve to the sub-chunk URL
// without the query. `preserveEntrySignatures: false` in vite.config
// suppresses that facade so this call lives in the entry itself.
define(import.meta.url, MermaidElement)
