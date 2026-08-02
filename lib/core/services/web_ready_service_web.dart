import 'dart:html' as html;

void markWebAppReady({String screen = 'app'}) {
  final root = html.document.documentElement;
  root?.dataset['baynanaReady'] = 'true';
  root?.dataset['baynanaScreen'] = screen;
  html.window.dispatchEvent(html.Event('baynana-ready'));
}
