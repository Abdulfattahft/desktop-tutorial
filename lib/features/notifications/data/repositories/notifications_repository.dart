import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/notification_models.dart';

/// مستودع الإشعارات
/// - إنشاء إشعار داخل التطبيق (والـ Cloud Function ترسل الـ Push)
/// - منع التكرار عبر dedupeKey كمعرّف للمستند
class NotificationsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notifsRef(String uid) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.notificationsCollection);

  /// إنشاء إشعار لمستخدم
  /// dedupeKey: إذا مُرِّر، يصبح معرّف المستند فلا يتكرر نفس الحدث أبدًا
  Future<void> create({
    required String toUid,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String? actionRoute,
    NotificationPriority priority = NotificationPriority.normal,
    String? imageUrl,
    DateTime? expiresAt,
    String? dedupeKey,
    String? fromUid,
  }) async {
    final ref = dedupeKey != null
        ? _notifsRef(toUid).doc(dedupeKey)
        : _notifsRef(toUid).doc();

    final notif = AppNotification(
      id: ref.id,
      type: type,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      data: data,
      actionRoute: actionRoute,
      priority: priority,
      imageUrl: imageUrl,
      expiresAt: expiresAt,
      dedupeKey: dedupeKey,
      fromUid: fromUid,
    );

    if (dedupeKey != null) {
      // لا نكتب فوق إشعار موجود بنفس المفتاح
      final existing = await ref.get();
      if (existing.exists) return;
    }
    await ref.set(notif.toMap());
  }

  /// تيار الإشعارات (الأحدث أولًا)
  Stream<List<AppNotification>> notificationsStream(String uid) =>
      _notifsRef(uid)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => AppNotification.fromMap(d.data()))
              .where((n) => !n.isExpired)
              .toList());

  /// عدد غير المقروء — للشارة على أيقونة الجرس
  Stream<int> unreadCountStream(String uid) => _notifsRef(uid)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snap) => snap.docs.length);

  Future<void> markAsRead(String uid, String notifId) =>
      _notifsRef(uid).doc(notifId).update({'isRead': true});

  /// تحديد الكل كمقروء (دفعة واحدة)
  Future<void> markAllAsRead(String uid) async {
    final unread =
        await _notifsRef(uid).where('isRead', isEqualTo: false).get();
    if (unread.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> delete(String uid, String notifId) =>
      _notifsRef(uid).doc(notifId).delete();

  Future<void> deleteAll(String uid) async {
    final all = await _notifsRef(uid).get();
    final batch = _db.batch();
    for (final doc in all.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ===== التفضيلات =====
  Stream<NotificationPrefs> prefsStream(String uid) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .snapshots()
      .map((doc) => NotificationPrefs.fromMap(
          doc.data()?['notificationPrefs'] as Map<String, dynamic>?));

  Future<void> setPref({
    required String uid,
    required NotificationCategory category,
    required bool enabled,
  }) =>
      _db.collection(AppConstants.usersCollection).doc(uid).update({
        'notificationPrefs.${category.prefKey}': enabled,
      });

  /// حفظ رمز FCM للجهاز
  Future<void> saveFcmToken(String uid, String token) =>
      _db.collection(AppConstants.usersCollection).doc(uid).update({
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]), // دعم أجهزة متعددة
      });
}
