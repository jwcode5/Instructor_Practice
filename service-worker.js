const CACHE_NAME = "instructor-practice-v2";

const CORE_ASSETS = [
	"./",
	"./index.html",
	"./contact.html",
	"./style.css",
	"./manifest.json",
	"./pwa-register.js",
	"./test_page_theme.css",
	"./test_page_theme.js",
	"./officer1/index.html",
	"./officer1/practice_officer1.html",
	"./officer1/bank_officer1.json",
	"./officer2/index.html",
	"./officer2/practice_officer2.html",
	"./officer2/bank_officer2.json",
	"./instructor1/index.html",
	"./instructor1/practice_instructor1.html",
	"./instructor1/bank_instructor1.json",
	"./PDO/index.html",
	"./PDO/practice_pdo.html",
	"./PDO/pdo_fixed_test.css",
	"./PDO/pdo_fixed_test.js",
	"./PDO/pdo_v1.html",
	"./PDO/pdo_v2.html",
	"./PDO/pdo_v3.html",
	"./PDO/pdo_v4.html",
	"./PDO/bank_pdo.json",
	"./appstore-images/android/launchericon-192x192.png",
	"./appstore-images/android/launchericon-512x512.png",
	"./appstore-images/ios/180.png"
];

self.addEventListener("install", (event) => {
	event.waitUntil(
		caches.open(CACHE_NAME).then((cache) => cache.addAll(CORE_ASSETS))
	);
	self.skipWaiting();
});

self.addEventListener("activate", (event) => {
	event.waitUntil(
		caches.keys().then((keys) => Promise.all(
			keys
				.filter((key) => key !== CACHE_NAME)
				.map((key) => caches.delete(key))
		))
	);
	self.clients.claim();
});

self.addEventListener("fetch", (event) => {
	if (event.request.method !== "GET") {
		return;
	}

	const requestUrl = new URL(event.request.url);
	if (requestUrl.origin !== self.location.origin) {
		return;
	}

	if (event.request.mode === "navigate") {
		event.respondWith(
			fetch(event.request)
				.then((networkResponse) => {
					const responseClone = networkResponse.clone();
					caches.open(CACHE_NAME).then((cache) => cache.put(event.request, responseClone));
					return networkResponse;
				})
				.catch(() => caches.match(event.request).then((cachedPage) => cachedPage || caches.match("./index.html")))
		);
		return;
	}

	event.respondWith(
		caches.match(event.request).then((cachedResponse) => {
			if (cachedResponse) {
				return cachedResponse;
			}

			return fetch(event.request)
				.then((networkResponse) => {
					if (!networkResponse || networkResponse.status !== 200) {
						return networkResponse;
					}

					const responseClone = networkResponse.clone();
					caches.open(CACHE_NAME).then((cache) => cache.put(event.request, responseClone));
					return networkResponse;
				})
				.catch(() => {
					if (event.request.mode === "navigate") {
						return caches.match("./index.html");
					}
					return new Response("Offline. Please reconnect to refresh this content.", {
						headers: { "Content-Type": "text/plain" }
					});
				});
		})
	);
});