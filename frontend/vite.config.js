import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

// On Vercel: base is '/' (root domain). On GitHub Pages: base is '/mediafourtribuannews/'
const isVercel = Boolean(process.env.VERCEL || process.env.NOW_BUILDER)
const basePath = process.env.VITE_BASE_PATH || (isVercel ? '/' : '/mediafourtribuannews/')

export default defineConfig({
  base: basePath,
  plugins: [vue(), tailwindcss()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
      '/uploads': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
})
