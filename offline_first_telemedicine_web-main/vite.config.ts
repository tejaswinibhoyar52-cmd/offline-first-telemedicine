import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// MediCare Offline — Vite config
//
// PWA note: this project intentionally hand-writes its own service worker
// (public/sw.js) and manifest (public/manifest.json) instead of using
// vite-plugin-pwa, so the offline caching + background-sync logic stays
// fully readable and easy to explain in a project demo/viva. Vite copies
// everything in public/ to the build output automatically, and the worker
// is registered manually in src/main.tsx.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173
  },
  resolve: {
    alias: {
      '@': '/src'
    }
  }
})
