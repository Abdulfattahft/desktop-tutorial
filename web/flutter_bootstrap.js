{{flutter_js}}
{{flutter_build_config}}

(async function () {
  const host = document.getElementById('flutter-host');

  function fitHostToLayoutViewport() {
    if (!host) return;

    // لا نستخدم visualViewport هنا؛ لأنه يصغر عند تكبير الصفحة على iPhone
    // ويجعل Flutter يرسم التطبيق في جزء من الشاشة فقط.
    const width = Math.max(
      1,
      Math.round(
        window.innerWidth ||
        document.documentElement.clientWidth ||
        window.screen.width ||
        1
      )
    );
    const height = Math.max(
      1,
      Math.round(
        window.innerHeight ||
        document.documentElement.clientHeight ||
        window.screen.height ||
        1
      )
    );

    host.style.position = 'fixed';
    host.style.inset = '0';
    host.style.width = `${width}px`;
    host.style.height = `${height}px`;
    host.style.minWidth = `${width}px`;
    host.style.minHeight = `${height}px`;
    host.style.maxWidth = 'none';
    host.style.maxHeight = 'none';
    host.style.margin = '0';
    host.style.padding = '0';
    host.style.overflow = 'hidden';
    host.style.transform = 'none';
  }

  function showViewportDebug() {
    if (!new URLSearchParams(location.search).has('debugViewport')) return;

    let badge = document.getElementById('viewport-debug');
    if (!badge) {
      badge = document.createElement('div');
      badge.id = 'viewport-debug';
      badge.style.cssText = [
        'position:fixed',
        'z-index:999999',
        'left:6px',
        'top:6px',
        'direction:ltr',
        'background:#000',
        'color:#0f0',
        'font:12px monospace',
        'padding:5px',
        'border-radius:4px',
        'pointer-events:none'
      ].join(';');
      document.body.appendChild(badge);
    }

    const rect = host?.getBoundingClientRect();
    badge.textContent = [
      `inner:${window.innerWidth}x${window.innerHeight}`,
      `visual:${window.visualViewport?.width || 0}x${window.visualViewport?.height || 0}`,
      `scale:${window.visualViewport?.scale || 1}`,
      `screen:${window.screen.width}x${window.screen.height}`,
      `host:${Math.round(rect?.width || 0)}x${Math.round(rect?.height || 0)}`
    ].join(' | ');
  }

  function fitAndReport() {
    fitHostToLayoutViewport();
    showViewportDebug();
  }

  fitAndReport();
  window.addEventListener('resize', fitAndReport, { passive: true });
  window.addEventListener(
    'orientationchange',
    () => setTimeout(fitAndReport, 150),
    { passive: true }
  );

  try {
    if ('serviceWorker' in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(
        registrations.map((registration) => registration.unregister())
      );
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
      fitAndReport();

      const appRunner = await engineInitializer.initializeEngine({
        hostElement: host,
      });

      await appRunner.runApp();

      requestAnimationFrame(() => {
        fitAndReport();
        const flutterView = host?.querySelector('flutter-view');
        if (flutterView) {
          flutterView.style.position = 'absolute';
          flutterView.style.inset = '0';
          flutterView.style.width = '100%';
          flutterView.style.height = '100%';
          flutterView.style.minWidth = '100%';
          flutterView.style.minHeight = '100%';
          flutterView.style.maxWidth = 'none';
          flutterView.style.maxHeight = 'none';
          flutterView.style.transform = 'none';
        }
        showViewportDebug();
      });
    },
  });
})();
