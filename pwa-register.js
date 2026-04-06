(() => {
	if (!("serviceWorker" in navigator) || window.location.protocol === "file:") {
		return;
	}

	const scriptEl =
		document.currentScript ||
		document.querySelector('script[src$="pwa-register.js"]');

	if (!scriptEl) {
		return;
	}

	const scriptUrl = new URL(scriptEl.getAttribute("src"), window.location.href);
	const scriptDir = scriptUrl.href.replace(/[^/]*$/, "");
	const swUrl = new URL("service-worker.js", scriptDir);

	window.addEventListener("load", () => {
		navigator.serviceWorker.register(swUrl.pathname)
			.then((registration) => registration.update())
			.catch((error) => console.warn("Service worker registration failed", error));
	});
})();