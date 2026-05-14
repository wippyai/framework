import { WippyVueElement, define } from '@wippy-fe/webcomponent-vue'
import type { WippyElementConfig, WippyPropsSchema } from '@wippy-fe/webcomponent-vue'
import type { ComponentProps } from './types.ts'
import type { Events } from './constants.ts'
import ChartJsCanvas from './app/chartjs-canvas.vue'
import stylesText from './styles.css?inline'
import pkg from '../package.json'

class ChartJsElement extends WippyVueElement<ComponentProps, Events> {
  static get wippyConfig(): WippyElementConfig<ComponentProps> {
    return {
      propsSchema: pkg.wippy.props as WippyPropsSchema,
      hostCssKeys: ['themeConfigUrl'] as const,
      inlineCss: stylesText,
    }
  }

  static get vueConfig() {
    return {
      rootComponent: ChartJsCanvas,
    }
  }
}

export async function webComponent() {
  return ChartJsElement
}

define(import.meta.url, ChartJsElement)
