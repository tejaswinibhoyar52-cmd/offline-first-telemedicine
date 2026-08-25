import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
import './index.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>
)

// Register the custom service worker (public/sw.js) for offline app-shell
// caching and the background-sync trigger bridge. Registered here (rather
// than via vite-plugin-pwa's auto-register) so we can log status clearly
// during a college demo.
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker
      .register('/sw.js')
      .then((reg) => {
        // eslint-disable-next-line no-console
        console.log('[MediCare Offline] Service worker registered:', reg.scope)
      })
      .catch((err) => {
        // eslint-disable-next-line no-console
        console.warn('[MediCare Offline] Service worker registration failed:', err)
      })
  })
}
