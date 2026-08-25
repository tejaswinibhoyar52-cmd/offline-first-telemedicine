/**
 * MediCare Offline — Service Worker
 * -----------------------------------------------------------------------
 * Responsibilities:
 *  1. Precache the app shell so the SPA loads even with zero connectivity.
 *  2. Runtime-cache same-origin GET requests (cache-first for static
 *     assets, network-first with cache fallback for navigation requests).
 *  3. Never intercept Supabase API/auth calls — those are handled by the
 *     app's own offline queue (src/offline) so we don't fight IndexedDB
 *     writes with an opaque service-worker cache.
 *  4. Listen for a 'sync-request' message from the app and rebroadcast a
 *     'trigger-sync' message to all open clients when connectivity is
 *     restored (used together with the Background Sync API when available,
 *     and as a manual fallback otherwise).
 */

const CACHE_VERSION = 'medicare-offline-v1';
const APP_SHELL = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icons/icon.svg',
  '/offline.html'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_VERSION).then((cache) => cache.addAll(APP_SHELL)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_VERSION).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

function isSupabaseRequest(url) {
  return url.hostname.endsWith('supabase.co') || url.hostname.endsWith('supabase.in');
}

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Never cache/intercept API calls to Supabase — those are the domain of
  // the app-level sync queue, not the service worker.
  if (isSupabaseRequest(url)) return;

  // Only handle same-origin GET requests.
  if (event.request.method !== 'GET' || url.origin !== self.location.origin) return;

  // Navigation requests: try network first, fall back to cached shell/offline page.
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request)
        .then((res) => {
          const clone = res.clone();
          caches.open(CACHE_VERSION).then((cache) => cache.put(event.request, clone));
          return res;
        })
        .catch(() =>
          caches.match(event.request).then((cached) => cached || caches.match('/index.html'))
        )
    );
    return;
  }

  // Static assets: cache-first, update cache in background.
  event.respondWith(
    caches.match(event.request).then((cached) => {
      const networkFetch = fetch(event.request)
        .then((res) => {
          if (res && res.status === 200) {
            const clone = res.clone();
            caches.open(CACHE_VERSION).then((cache) => cache.put(event.request, clone));
          }
          return res;
        })
        .catch(() => cached);
      return cached || networkFetch;
    })
  );
});

// Background Sync API (where supported) — fires when the browser regains
// connectivity even if the app tab isn't open. We just notify open clients;
// the actual sync logic lives in src/offline/syncService.ts so it can use
// the authenticated Supabase client already held in memory/IndexedDB.
self.addEventListener('sync', (event) => {
  if (event.tag === 'medicare-sync-queue') {
    event.waitUntil(broadcastTriggerSync());
  }
});

self.addEventListener('message', (event) => {
  if (event.data?.type === 'REQUEST_SYNC') {
    broadcastTriggerSync();
  }
});

async function broadcastTriggerSync() {
  const clientsList = await self.clients.matchAll({ type: 'window' });
  clientsList.forEach((client) => client.postMessage({ type: 'TRIGGER_SYNC' }));
}
