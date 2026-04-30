import { WippyVueElement, define } from '@wippy-fe/webcomponent-vue'
import type { WippyElementConfig, WippyPropsSchema } from '@wippy-fe/webcomponent-vue'
import type { ComponentProps } from './types.ts'
import type { Events } from './constants.ts'
import MarkdownView from './app/markdown-view.vue'
import stylesText from './styles.css?inline'
import pkg from '../package.json'

class MarkdownElement extends WippyVueElement<ComponentProps, Events> {
  static get wippyConfig(): WippyElementConfig<ComponentProps> {
    return {
      propsSchema: pkg.wippy.props as WippyPropsSchema,
      hostCssKeys: ['themeConfigUrl', 'markdownCssUrl'] as const,
      inlineCss: stylesText,
      contentTemplate: 'text/markdown',
    }
  }

  static get vueConfig() {
    return {
      rootComponent: MarkdownView,
    }
  }
}

export async function webComponent() {
  return MarkdownElement
}

define(import.meta.url, MarkdownElement)
