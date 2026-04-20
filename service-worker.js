const CACHE_VERSION = new URL(self.location.href).searchParams.get("v") || "2026-04-20-1";
const CACHE_NAME = `hfd-site-${CACHE_VERSION}`;

const CORE_ASSETS = [
    "./",
    "./index.html",
    "./education_request.html",
    "./style.css",
    "./manifest.json",
    "./pwa-register.js",
    "./icon.svg",
    "./Education Request Form.pdf"
];

self.addEventListener("install", (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME).then((cache) => cache.addAll(CORE_ASSETS))
    );
    self.skipWaiting();
});

self.addEventListener("activate", (event) => {
    event.waitUntil((async () => {
        const keys = await caches.keys();
        await Promise.all(
            keys
                .filter((key) => key !== CACHE_NAME)
                .map((key) => caches.delete(key))
        );
        await self.clients.claim();
    })());
});

function isCacheableRequest(request) {
    if (request.method !== "GET") {
        return false;
    }

    const url = new URL(request.url);
    return url.origin === self.location.origin;
}

self.addEventListener("fetch", (event) => {
    const { request } = event;

    if (!isCacheableRequest(request)) {
        return;
    }

    event.respondWith((async () => {
        const cache = await caches.open(CACHE_NAME);

        try {
            const networkResponse = await fetch(request);
            if (networkResponse && networkResponse.ok) {
                cache.put(request, networkResponse.clone());
            }
            return networkResponse;
        } catch (error) {
            const cachedResponse = await cache.match(request);
            if (cachedResponse) {
                return cachedResponse;
            }

            if (request.mode === "navigate") {
                return cache.match("./index.html");
            }

            return new Response("Offline. Please reconnect to refresh this content.", {
                headers: { "Content-Type": "text/plain" }
            });
        }
    })());
});