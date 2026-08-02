import 'dart:html' as html;

void markWebAppReady() {
  html.document.documentElement?.dataset['baynanaReady'] = 'true';
  html.window.dispatchEvent(html.Event('baynana-ready'));
}
