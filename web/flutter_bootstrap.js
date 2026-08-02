{{flutter_js}}
{{flutter_build_config}}

function showStartupError(error) {
  const message = error instanceof Error ? `${error.name}: ${error.message}` : String(error);
  document.body.innerHTML = `
    <main dir="rtl" style="min-height:100vh;background:#1e1a19;color:#fff;display:flex;align-items:center;justify-content:center;padding:24px;font-family:Arial,sans-serif">
      <section style="width:min(560px,100%);background:#2a2422;border:1px solid #6b4a4a;border-radius:20px;padding:24px">
        <h1 style="margin:0 0 12px;font-size:22px">تعذر تشغيل تطبيق بيننا</h1>
        <p style="margin:0 0 12px;line-height:1.7">ظهرت مشكلة أثناء بدء التطبيق. صوّر هذه الرسالة وأرسلها.</p>
        <pre dir="ltr" style="white-space:pre-wrap;overflow-wrap:anywhere;background:#171312;padding:12px;border-radius:12px;color:#ffb4ab">${message.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</pre>
      </section>
    </main>`;
}

window.addEventListener('error', (event) => showStartupError(event.error || event.message));
window.addEventListener('unhandledrejection', (event) => showStartupError(event.reason));

(async function () {
  try {
    if ('serviceWorker' in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.map((registration) => registration.unregister()));
    }

    if ('caches' in window) {
      const cacheNames = await caches.keys();
      await Promise.all(cacheNames.map((cacheName) => caches.delete(cacheName)));
    }

    await _flutter.loader.load();
  } catch (error) {
    showStartupError(error);
  }
})();
