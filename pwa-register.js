(() => {
    if (!("serviceWorker" in navigator) || window.location.protocol === "file:") {
        return;
    }

    const CACHE_VERSION = "2026-04-20-2";
    const scriptEl =
        document.currentScript ||
        document.querySelector('script[src$="pwa-register.js"]');

    if (!scriptEl) {
        return;
    }

    const scriptUrl = new URL(scriptEl.getAttribute("src"), window.location.href);
    const swUrl = new URL(`service-worker.js?v=${CACHE_VERSION}`, scriptUrl);

    window.addEventListener("load", async () => {
        try {
            const registration = await navigator.serviceWorker.register(swUrl.pathname + swUrl.search, {
                updateViaCache: "none"
            });
            await registration.update();
        } catch (error) {
            console.warn("Service worker registration failed", error);
        }
    });

    navigator.serviceWorker.addEventListener("controllerchange", () => {
        window.location.reload();
    });
})();