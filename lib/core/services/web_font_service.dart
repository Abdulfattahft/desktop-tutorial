import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Loads an Arabic-capable font into the Flutter web engine before rendering.
///
/// CanvasKit cannot use operating-system fonts directly. When its remote
/// fallback font request is blocked, the UI shapes still render but Arabic text
/// disappears. Loading Cairo explicitly prevents that failure mode.
class WebFontService {
  WebFontService._();

  static const String family = 'BaynanaCairo';
  static const String _fontUrl =
      'https://raw.githubusercontent.com/google/fonts/main/ofl/cairo/'
      'Cairo%5Bslnt,wght%5D.ttf';

  static Future<void> load() async {
    if (!kIsWeb) return;

    try {
      final response = await http
          .get(Uri.parse(_fontUrl))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return;

      final data = ByteData.sublistView(Uint8List.fromList(response.bodyBytes));
      final loader = FontLoader(family)..addFont(Future.value(data));
      await loader.load().timeout(const Duration(seconds: 8));
    } catch (_) {
      // Keep startup resilient. The app can still attempt Flutter's fallback.
    }
  }
}
