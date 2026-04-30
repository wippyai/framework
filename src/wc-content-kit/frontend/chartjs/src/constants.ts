import { useProps, useEvents, usePropsErrors } from '@wippy-fe/webcomponent-vue'
import type { ComponentProps } from './types.ts'

export interface Events {
  load: undefined
  unload: undefined
  error: { message: string, error: unknown }
  invalid: { message: string }
}

export const useComponentProps = () => useProps<ComponentProps>()
export const useComponentEvents = () => useEvents<Events>()
export const useComponentPropsErrors = usePropsErrors

export const DEFAULT_TYPE = 'doughnut'
export const DEFAULT_DATA = JSON.stringify({
  labels: ['Red', 'Blue', 'Yellow'],
  datasets: [{ data: [300, 50, 100] }],
})
