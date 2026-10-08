const CACHE_NAME = 'spiritofstar-cache-v1';
const ASSETS_TO_CACHE = [
  '/',
  '/blog.html',
  '/assessment-over-authority.html',
  '/responding-to-criticism.html',
  '/404.html',
  '/favicon.svg',
  '/manifest.json',
  '/fonts/Lora-VariableFont_wght.ttf',
  '/fonts/Lora-Italic-VariableFont_wght.ttf',
  '/fonts/Fraunces-VariableFont_SOFT,WONK,opsz,wght.ttf',
  '/fonts/Fraunces-Italic-VariableFont_SOFT,WONK,opsz,wght.ttf',
  '/fonts/InstrumentSerif-Regular.ttf',
  '/fonts/InstrumentSerif-Italic.ttf',
  '/fonts/Newsreader-VariableFont_opsz,wght.ttf',
  '/fonts/Newsreader-Italic-VariableFont_opsz,wght.ttf',
  '/fonts/EBGaramond-VariableFont_wght.ttf',
  '/fonts/EBGaramond-Italic-VariableFont_wght.ttf'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS_TO_CACHE);
    })
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            return caches.delete(key);
          }
        })
      );
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  // Only handle GET requests
  if (event.request.method !== 'GET') return;

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        // Return cached response and fetch update in background
        event.waitUntil(
          fetch(event.request).then((networkResponse) => {
            if (networkResponse && networkResponse.status === 200) {
              caches.open(CACHE_NAME).then((cache) => {
                cache.put(event.request, networkResponse);
              });
            }
          }).catch(() => {})
        );
        return cachedResponse;
      }

      return fetch(event.request).then((networkResponse) => {
        if (!networkResponse || networkResponse.status !== 200 || networkResponse.type !== 'basic') {
          return networkResponse;
        }
        const responseToCache = networkResponse.clone();
        caches.open(CACHE_NAME).then((cache) => {
          cache.put(event.request, responseToCache);
        });
        return networkResponse;
      }).catch(() => {
        // Fallback for navigation requests when offline
        if (event.request.mode === 'navigate') {
          return caches.match('/');
        }
      });
    })
  );
});
