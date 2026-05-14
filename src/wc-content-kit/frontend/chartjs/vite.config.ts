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
      name: 'ChartJs',
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
      // src/index.ts calls `define(import.meta.url, …)`; if that statement
      // gets moved into a sub-chunk, `import.meta.url` resolves to the
      // sub-chunk URL — which lacks the `?declare-tag=` query the autoload
      // script appends to the entry — and registration silently no-ops.
      preserveEntrySignatures: false,
    },
    sourcemap: false,
  },
})
