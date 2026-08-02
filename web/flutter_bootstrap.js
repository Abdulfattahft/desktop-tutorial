{{flutter_js}}
{{flutter_build_config}}

(async function () {
  const host = document.getElementById('flutter-host');

  function fitHostToViewport() {
    if (!host) return;

    const viewport = window.visualViewport;
    const width = Math.max(1, Math.round(viewport?.width || window.innerWidth || document.documentElement.clientWidth));
    const height = Math.max(1, Math.round(viewport?.height || window.innerHeight || document.documentElement.clientHeight));

    host.style.position = 'fixed';
    host.style.left = '0px';
    host.style.top = '0px';
    host.style.right = 'auto';
    host.style.bottom = 'auto';
    host.style.width = `${width}px`;
    host.style.height = `${height}px`;
    host.style.minWidth = `${width}px`;
    host.style.maxWidth = `${width}px`;
    host.style.minHeight = `${height}px`;
    host.style.maxHeight = `${height}px`;
    host.style.margin = '0';
    host.style.padding = '0';
    host.style.overflow = 'hidden';
  }

  fitHostToViewport();
  window.addEventListener('resize', fitHostToViewport, { passive: true });
  window.addEventListener('orientationchange', () => setTimeout(fitHostToViewport, 120), { passive: true });
  window.visualViewport?.addEventListener('resize', fitHostToViewport, { passive: true });
  window.visualViewport?.addEventListener('scroll', fitHostToViewport, { passive: true });

  try {
    if ('serviceWorker' in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.map((registration) => registration.unregister()));
    }

    if ('caches' in window) {
      const cacheNames = await caches.keys();
      await Promise.all(cacheNames.map((cacheName) => caches.delete(cacheName)));
    }
  } catch (error) {
    console.warn('Could not clear an old Flutter cache:', error);
  }

  _flutter.loader.load({
    serviceWorkerSettings: null,
    onEntrypointLoaded: async function (engineInitializer) {
      fitHostToViewport();

      const appRunner = await engineInitializer.initializeEngine({
        hostElement: host,
      });

      await appRunner.runApp();
      fitHostToViewport();

      requestAnimationFrame(() => {
        fitHostToViewport();
        const flutterView = host?.querySelector('flutter-view');
        if (flutterView) {
          flutterView.style.position = 'absolute';
          flutterView.style.inset = '0';
          flutterView.style.width = '100%';
          flutterView.style.height = '100%';
          flutterView.style.maxWidth = 'none';
        }
      });
    },
  });
})();
