import { resolve } from 'node:path'
import vue from '@vitejs/plugin-vue'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [
    vue(),
  ],
  build: {
    target: 'esnext',
    lib: {
      entry: resolve(__dirname, 'src/index.ts'),
      name: 'MermaidDiagram',
      fileName: 'index',
      formats: ['es'],
    },
    rollupOptions: {
      input: {
        index: resolve(__dirname, 'src/index.ts'),
      },
      external: [
        'vue',
        'pinia',

        '@iconify/vue',
        '@wippy-fe/proxy',
      ],
      output: {
        entryFileNames: '[name].js',
        chunkFileNames: '[name]-[hash].js',
        assetFileNames: '[name]-[hash][extname]',
      },
      // No constraint on entry signatures — entry chunk can absorb its
      // dependencies instead of being split into a facade + sub-chunk.
      // This matters because `src/index.ts` calls
      // `define(import.meta.url, …)`; if that statement is moved into a
      // sub-chunk, `import.meta.url` resolves to the sub-chunk URL,
      // which lacks the `?declare-tag=` query the autoload script
      // appends to the entry — registration silently no-ops.
      preserveEntrySignatures: false,
    },
    sourcemap: false,
  },
})
