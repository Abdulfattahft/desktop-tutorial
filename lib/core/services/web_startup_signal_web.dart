import 'dart:html' as html;

void markFlutterReady() {
  html.document.documentElement?.dataset['flutterReady'] = 'true';
}
