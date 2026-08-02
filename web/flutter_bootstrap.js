{{flutter_js}}
{{flutter_build_config}}

let baynanaStartupStage = 'تهيئة صفحة الويب';

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
}

function showStartupError(error) {
  const name = error instanceof Error ? error.name : 'Error';
  const message = error instanceof Error ? error.message : String(error);
  const stack = error instanceof Error && error.stack ? error.stack : '';
  const details = [
    `${name}: ${message}`,
    `المرحلة: ${baynanaStartupStage}`,
    stack,
  ].filter(Boolean).join('\n\n');

  document.body.innerHTML = `
    <main dir="rtl" style="min-height:100vh;background:#1e1a19;color:#fff;display:flex;align-items:center;justify-content:center;padding:24px;font-family:Arial,sans-serif">
      <section style="width:min(620px,100%);background:#2a2422;border:1px solid #6b4a4a;border-radius:20px;padding:24px">
        <h1 style="margin:0 0 12px;font-size:22px">تعذر تشغيل تطبيق بيننا</h1>
        <p style="margin:0 0 12px;line-height:1.7">ظهرت مشكلة أثناء بدء التطبيق. صوّر هذه الرسالة وأرسلها.</p>
        <pre dir="ltr" style="white-space:pre-wrap;overflow-wrap:anywhere;background:#171312;padding:12px;border-radius:12px;color:#ffb4ab;font-size:12px;line-height:1.55">${escapeHtml(details)}</pre>
      </section>
    </main>`;
}

window.addEventListener('error', (event) => {
  showStartupError(event.error || event.message);
});
window.addEventListener('unhandledrejection', (event) => {
  showStartupError(event.reason);
});

(async function () {
  try {
    baynanaStartupStage = 'تنظيف النسخ القديمة';
    if ('serviceWorker' in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.map((registration) => registration.unregister()));
    }

    if ('caches' in window) {
      const cacheNames = await caches.keys();
      await Promise.all(cacheNames.map((cacheName) => caches.delete(cacheName)));
    }

    baynanaStartupStage = 'تحميل محرك Flutter وتشغيل التطبيق';
    await _flutter.loader.load();
    baynanaStartupStage = 'اكتمل تشغيل Flutter';
  } catch (error) {
    showStartupError(error);
  }
})();
