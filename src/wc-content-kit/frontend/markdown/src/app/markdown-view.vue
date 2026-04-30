<script setup lang="ts">
import { computed } from 'vue'
import MarkdownIt from 'markdown-it'
import sanitizeHtml from 'sanitize-html'
import { useContent } from '@wippy-fe/webcomponent-vue'
import { useComponentProps } from '../constants'
import { defaultAllowedTags, defaultAllowedAttributes } from '../markdown-defaults'

const props = useComponentProps()
const content = useContent()

const md = new MarkdownIt({
  html: false,
  breaks: true,
  linkify: true,
  typographer: false,
})

const markdownSource = computed(() =>
  props.value.content || content.value || ''
)

const allowedTags = computed(() => {
  const custom = props.value.allowedTags
  return (custom && custom.length > 0) ? custom : defaultAllowedTags
})

const allowedAttributes = computed(() => {
  const raw = props.value.allowedAttributes
  if (raw) {
    try {
      return JSON.parse(raw) as Record<string, string[]>
    } catch {
      // Fall through to defaults
    }
  }
  return defaultAllowedAttributes
})

const renderedHtml = computed(() => {
  if (!markdownSource.value) return ''

  const rawHtml = md.render(markdownSource.value)

  return sanitizeHtml(rawHtml, {
    allowedTags: allowedTags.value,
    allowedAttributes: allowedAttributes.value,
    allowedClasses: {
      code: ['language-*'],
      pre: ['language-*'],
      span: ['language-*'],
    },
    transformTags: {
      a: sanitizeHtml.simpleTransform('a', { rel: 'noopener noreferrer' }),
    },
  })
})
</script>

<template>
  <article
    v-if="renderedHtml"
    class="data-body markdown-container"
    v-html="renderedHtml"
  />
  <div
    v-else
    class="markdown-empty"
  >
    No markdown content provided.
  </div>
</template>
