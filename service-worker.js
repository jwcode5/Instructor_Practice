const CACHE_VERSION = new URL(self.location.href).searchParams.get("v") || "2026-05-08-14";
const CACHE_NAME = `hfd-site-${CACHE_VERSION}`;

const CORE_ASSETS = [
    "./",
    "./index.html",
    "./education_request.html",
    "./style.css",
    "./manifest.json",
    "./browserconfig.xml",
    "./pwa-register.js",
    "./Images/android/launchericon-192x192.png",
    "./Images/android/launchericon-512x512.png",
    "./Images/ios/180.png",
    "./Images/windows/Square150x150Logo.scale-100.png",
    "./Education Request Form.pdf",
    "./protocols.html",
    "./js/pdf-viewer.js",
    "./js/pdf.min.js",
    "./js/pdf.worker.min.js",
    "./protocols/adult_protocols.pdf",
    "./protocols/pediatric_protocols.pdf",
    "./protocols/clinical_ops.pdf",
    "./protocols/medication_formulary.pdf",
    "./protocols/flowchart_adult.pdf"
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