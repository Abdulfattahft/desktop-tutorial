import 'package:flutter/foundation.dart';

/// إعداد الخط في نسخة الويب.
///
/// نستخدم خط النظام حاليًا بدل تحميل خط متغيّر عن بُعد قبل تشغيل Flutter.
/// التحميل الديناميكي المبكر كان يعرّض WebKit لتعارض أنواع في بعض الإصدارات.
class WebFontService {
  WebFontService._();

  /// null يجعل Flutter يستخدم أفضل خط متاح في الجهاز مع دعم العربية.
  static const String? family = null;

  static Future<void> load() async {
    if (!kIsWeb) return;
  }
}
