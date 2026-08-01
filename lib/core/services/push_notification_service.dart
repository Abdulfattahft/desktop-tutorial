import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// معالج رسائل الخلفية — يجب أن يكون دالة عليا (top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // الرسالة تصل لدرج الإشعارات تلقائيًا؛ لا نحتاج عملًا إضافيًا هنا
  debugPrint('إشعار في الخلفية: ${message.messageId}');
}

/// خدمة الإشعارات الفورية (FCM)
/// - طلب الإذن (مطلوب على iOS)
/// - جلب الرمز وتحديثه
/// - التعامل مع الضغط على الإشعار (Deep Linking)
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// يُستدعى عند الضغط على إشعار — نمرره للراوتر
  void Function(String route, Map<String, dynamic> data)? onNotificationTap;

  /// رسالة وصلت والتطبيق مفتوح — لعرض شريط داخل التطبيق
  final StreamController<RemoteMessage> foregroundMessages =
      StreamController<RemoteMessage>.broadcast();

  StreamSubscription? _tokenSub;
  StreamSubscription? _foregroundSub;
  StreamSubscription? _openedSub;

  /// تهيئة الخدمة — تُستدعى بعد تسجيل الدخول
  /// [onToken] لحفظ الرمز في Firestore
  Future<void> init({
    required Future<void> Function(String token) onToken,
  }) async {
    // 1) الإذن (إلزامي على iOS)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('المستخدم رفض إذن الإشعارات');
      return;
    }

    // 2) عرض الإشعارات أثناء فتح التطبيق على iOS
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3) الرمز الحالي + التحديثات
    const webVapidKey = String.fromEnvironment('FIREBASE_WEB_VAPID_KEY');
    final token = await _fcm.getToken(
      vapidKey: kIsWeb && webVapidKey.isNotEmpty ? webVapidKey : null,
    );
    if (token != null) await onToken(token);
    _tokenSub?.cancel();
    _tokenSub = _fcm.onTokenRefresh.listen(onToken);

    // 4) رسالة والتطبيق مفتوح
    _foregroundSub?.cancel();
    _foregroundSub =
        FirebaseMessaging.onMessage.listen(foregroundMessages.add);

    // 5) ضغط على الإشعار والتطبيق في الخلفية
    _openedSub?.cancel();
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // 6) فتح التطبيق من إشعار وهو مغلق تمامًا
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      // تأخير بسيط حتى يجهز الراوتر
      Future.delayed(const Duration(milliseconds: 600),
          () => _handleTap(initial));
    }
  }

  void _handleTap(RemoteMessage message) {
    final route = message.data['actionRoute'] as String?;
    if (route != null && route.isNotEmpty) {
      onNotificationTap?.call(route, message.data);
    }
  }

  Future<void> deleteToken() async {
    await _fcm.deleteToken();
    await _tokenSub?.cancel();
    _tokenSub = null;
  }

  /// تنظيف الموارد — تُستدعى عند تسجيل الخروج
  Future<void> dispose() async {
    await _tokenSub?.cancel();
    _tokenSub = null;
    _foregroundSub?.cancel();
    _openedSub?.cancel();
  }
}
