const CACHE_NAME = "instructor-practice-v6";

const CORE_ASSETS = [
	"./",
	"./index.html",
	"./contact.html",
	"./style.css",
	"./manifest.json",
	"./pwa-register.js",
	"./test_page_theme.css",
	"./test_page_theme.js",
	// Officer 1
	"./officer1/index.html",
	"./officer1/practice_officer1.html",
	"./officer1/bank_officer1.json",
	"./officer1/officer1_v1.html",
	"./officer1/officer1_v2.html",
	"./officer1/officer1_v3.html",
	"./officer1/officer1_v4.html",
	"./officer1/officer1_v5.html",
	"./officer1/officer1_v6.html",
	// Officer 2
	"./officer2/index.html",
	"./officer2/practice_officer2.html",
	"./officer2/bank_officer2.json",
	"./officer2/officer2_v1.html",
	"./officer2/officer2_v2.html",
	"./officer2/officer2_v3.html",
	"./officer2/officer2_v4.html",
	"./officer2/officer2_v5.html",
	// Instructor 1
	"./instructor1/index.html",
	"./instructor1/practice_instructor1.html",
	"./instructor1/bank_instructor1.json",
	"./instructor1/instructor_v1.html",
	"./instructor1/instructor_v2.html",
	"./instructor1/instructor_v3.html",
	"./instructor1/instructor_v4.html",
	// Firefighter
	"./firefighter/index.html",
	"./firefighter/practice_firefighter.html",
	"./firefighter/bank_firefighter.json",
	"./firefighter/Chapter_01.html",
	"./firefighter/Chapter_02.html",
	"./firefighter/Chapter_03.html",
	"./firefighter/Chapter_04.html",
	"./firefighter/Chapter_05.html",
	"./firefighter/Chapter_06.html",
	"./firefighter/Chapter_07.html",
	"./firefighter/Chapter_08.html",
	"./firefighter/Chapter_09.html",
	"./firefighter/Chapter_10.html",
	"./firefighter/Chapter_11.html",
	"./firefighter/Chapter_12.html",
	"./firefighter/Chapter_13.html",
	"./firefighter/Chapter_14.html",
	"./firefighter/Chapter_15.html",
	"./firefighter/Chapter_16.html",
	"./firefighter/Chapter_17.html",
	"./firefighter/Chapter_18.html",
	"./firefighter/Chapter_19.html",
	"./firefighter/Chapter_20.html",
	"./firefighter/Chapter_21.html",
	"./firefighter/Chapter_22.html",
	"./firefighter/Chapter_23.html",
	"./firefighter/Chapter_24.html",
	"./firefighter/Chapter_26.html",
	"./firefighter/Chapter_27.html",
	"./firefighter/Chapter_28.html",
	// PDO
	"./PDO/index.html",
	"./PDO/practice_pdo.html",
	"./PDO/bank_pdo.json",
	"./PDO/Chapter_01.html",
	"./PDO/Chapter_02.html",
	"./PDO/Chapter_03.html",
	"./PDO/Chapter_04.html",
	"./PDO/Chapter_05.html",
	"./PDO/Chapter_06.html",
	"./PDO/Chapter_07.html",
	"./PDO/Chapter_08.html",
	"./PDO/Chapter_09.html",
	"./PDO/Chapter_10.html",
	"./PDO/Chapter_11.html",
	"./PDO/Chapter_12.html",
	"./PDO/Chapter_13.html",
	"./PDO/Chapter_14.html",
	"./PDO/Chapter_15.html",
	"./PDO/Chapter_Addendum.html",
	"./PDO/Chapter_01_Quiz.html",
	"./PDO/Chapter_02_Quiz.html",
	"./PDO/Chapter_03_Quiz.html",
	"./PDO/Chapter_04_Quiz.html",
	"./PDO/Chapter_05_Quiz.html",
	"./PDO/Chapter_06_Quiz.html",
	"./PDO/Chapter_07_Quiz.html",
	"./PDO/Chapter_08_Quiz.html",
	"./PDO/Chapter_09_Quiz.html",
	"./PDO/Chapter_10_Quiz.html",
	"./PDO/Chapter_11_Quiz.html",
	"./PDO/Chapter_12_Quiz.html",
	"./PDO/Chapter_13_Quiz.html",
	"./PDO/Chapter_14_Quiz.html",
	"./PDO/Chapter_15_Quiz.html",
	"./PDO/Chapter_Addendum_Quiz.html",
	// Hazmat
	"./hazmat/index.html",
	"./hazmat/practice_hazmat.html",
	"./hazmat/bank_hazmat.json",
	"./hazmat/Chapter_01.html",
	"./hazmat/Chapter_02.html",
	"./hazmat/Chapter_03.html",
	"./hazmat/Chapter_04.html",
	"./hazmat/Chapter_05.html",
	"./hazmat/Chapter_06.html",
	"./hazmat/Chapter_07.html",
	"./hazmat/Chapter_08.html",
	"./hazmat/Chapter_09.html",
	"./hazmat/Chapter_10.html",
	"./hazmat/Chapter_11.html",
	"./hazmat/Chapter_12.html",
	"./hazmat/Chapter_13.html",
	"./hazmat/Chapter_14.html",
	"./hazmat/Chapter_15.html",
	"./hazmat/Chapter_16.html",
	// Appstore images
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