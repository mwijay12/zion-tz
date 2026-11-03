const CACHE_NAME = 'sayuni-admin-pwa-v3';

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.map((key) => caches.delete(key)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) return;

  // Never intercept Vite dev server / HMR requests
  if (
    url.pathname.startsWith('/src/') ||
    url.pathname.startsWith('/@') ||
    url.pathname.startsWith('/node_modules/') ||
    url.search.includes('t=') ||
    url.search.includes('import')
  ) {
    return;
  }

  // Network-first strategy with offline cache fallback for production PWA
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        if (response && response.status === 200 && url.pathname.startsWith('/assets/')) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
        }
        return response;
      })
      .catch(() => caches.match(event.request))
  );
});
