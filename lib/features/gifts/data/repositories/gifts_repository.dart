import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../notifications/data/repositories/notification_events.dart';
import '../../../notifications/data/repositories/notifications_repository.dart';
import '../content/gifts_content.dart';
import '../models/gift_models.dart';

class GiftException implements Exception {
  final String message;
  const GiftException(this.message);
}

/// مستودع الهدايا
/// - الكتالوج من Firestore (giftCatalog) مع افتراضي مدمج عند الفراغ
/// - الشراء والفتح داخل Transactions بحُرّاس
class GiftsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationEvents _notify =
      NotificationEvents(NotificationsRepository());

  CollectionReference<Map<String, dynamic>> get _catalogRef =>
      _db.collection(AppConstants.giftCatalogCollection);

  DocumentReference<Map<String, dynamic>> _coupleRef(String coupleId) =>
      _db.collection(AppConstants.couplesCollection).doc(coupleId);

  CollectionReference<Map<String, dynamic>> _giftsRef(String coupleId) =>
      _coupleRef(coupleId).collection(AppConstants.giftsCollection);

  /// تيار الكتالوج — إضافة هدية موسمية = مستند جديد في Console بلا تحديث تطبيق
  Stream<List<GiftCatalogItem>> catalogStream() =>
      _catalogRef.snapshots().map((snap) {
        final items = snap.docs.isEmpty
            ? GiftsContent.defaultCatalog
            : snap.docs.map((d) {
                // نضمن وجود id حتى لو لم يُكتب داخل المستند
                final data = Map<String, dynamic>.from(d.data());
                data['id'] = data['id'] ?? d.id;
                return GiftCatalogItem.fromMap(data);
              }).toList();
        final available = items.where((g) => g.isAvailable).toList()
          ..sort((a, b) {
            final byOrder = a.sortOrder.compareTo(b.sortOrder);
            return byOrder != 0 ? byOrder : a.price.compareTo(b.price);
          });
        return available;
      });

  /// شراء وإرسال هدية — Transaction واحدة تتحقق من:
  /// التوفر الزمني، شروط المستوى/الستريك/الإنجاز، حد الشراء اليومي، الرصيد
  Future<void> sendGift({
    required String coupleId,
    required String fromUid,
    required String toUid,
    required GiftCatalogItem gift,
    String? message,
  }) async {
    final senderRef =
        _db.collection(AppConstants.usersCollection).doc(fromUid);
    final receiverRef =
        _db.collection(AppConstants.usersCollection).doc(toUid);
    final coupleRef = _coupleRef(coupleId);
    final giftRef = _giftsRef(coupleId).doc();

    // حد الشراء اليومي يُحسب خارج المعاملة (الاستعلامات لا تعمل داخلها)
    var todayCount = 0;
    if (gift.maxPurchasesPerDay > 0) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final snap = await _giftsRef(coupleId)
          .where('fromUid', isEqualTo: fromUid)
          .where('giftId', isEqualTo: gift.id)
          .where('sentAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();
      todayCount = snap.docs.length;
    }

    var senderName = '';
    await _db.runTransaction((tx) async {
      final senderDoc = await tx.get(senderRef);
      final receiverDoc = await tx.get(receiverRef);
      final coupleDoc = await tx.get(coupleRef);
      if (!senderDoc.exists || !coupleDoc.exists) {
        throw const GiftException('حدث خطأ، حاول مرة أخرى');
      }
      final sender = senderDoc.data()!;
      final receiver = receiverDoc.data() ?? {};
      final couple = coupleDoc.data()!;

      // 1) التوفر الزمني والتفعيل
      if (!gift.isAvailable) {
        throw const GiftException('هذه الهدية غير متاحة حاليًا');
      }

      // 2) شروط الفتح
      final lock = gift.lockFor(
        coupleLevel: (couple['level'] as num?)?.toInt() ?? 1,
        coupleStreak: (couple['streak'] as num?)?.toInt() ?? 0,
        achievements:
            List<String>.from(couple['achievements'] as List? ?? const []),
      );
      if (lock != null) {
        throw GiftException('هذه الهدية مقفلة: ${lock.reason}');
      }

      // 3) حد الشراء اليومي
      if (gift.maxPurchasesPerDay > 0 &&
          todayCount >= gift.maxPurchasesPerDay) {
        throw GiftException(
            'وصلت الحد اليومي لهذه الهدية (${gift.maxPurchasesPerDay} يوميًا) — جرّب بكرة 😊');
      }

      // 4) الرصيد
      final coins = (sender['coins'] as num?)?.toInt() ?? 0;
      if (coins < gift.price) {
        throw GiftException(
            'عملاتك ما تكفي 😅 تحتاج ${gift.price - coins} عملة إضافية — العب أو أكمل تحديات!');
      }

      // ===== التنفيذ =====
      tx.update(senderRef, {'coins': coins - gift.price});
      tx.set(
        giftRef,
        SentGift(
          id: giftRef.id,
          giftId: gift.id,
          name: gift.name,
          emoji: gift.emoji,
          price: gift.price,
          category: gift.category,
          rarity: gift.rarity,
          fromUid: fromUid,
          toUid: toUid,
          sentAt: DateTime.now(),
          message:
              message?.trim().isEmpty == true ? null : message?.trim(),
          opened: false,
          deliveryStatus: GiftDeliveryStatus.sent,
          senderSnapshot: GiftUserSnapshot(
            uid: fromUid,
            name: sender['name'] as String? ?? '',
            photoUrl: sender['photoUrl'] as String?,
            level: (sender['level'] as num?)?.toInt() ?? 1,
          ),
          receiverSnapshot: GiftUserSnapshot(
            uid: toUid,
            name: receiver['name'] as String? ?? '',
            photoUrl: receiver['photoUrl'] as String?,
            level: (receiver['level'] as num?)?.toInt() ?? 1,
          ),
          animationType: gift.animationType,
          thumbnailImage: gift.thumbnailImage,
        ).toMap(),
      );
      senderName = sender['name'] as String? ?? '';
    });

    // إشعار للطرف الآخر (خارج المعاملة — الفشل غير حرج)
    try {
      await _notify.giftReceived(
        toUid: toUid,
        fromUid: fromUid,
        senderName: senderName,
        giftName: gift.name,
        giftEmoji: gift.emoji,
        giftId: giftRef.id,
      );
    } catch (_) {}
  }

  /// تيار كل هدايا العلاقة (الأحدث أولًا)
  Stream<List<SentGift>> giftsStream(String coupleId) => _giftsRef(coupleId)
      .orderBy('sentAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) {
            final data = Map<String, dynamic>.from(d.data());
            data['id'] = data['id'] ?? d.id;
            return SentGift.fromMap(data);
          }).toList());

  /// تعليم الهدية كـ"شوهدت" (وصلت لصندوق الوارد دون فتح)
  Future<void> markSeen({
    required String coupleId,
    required String giftId,
    required String uid,
  }) async {
    final ref = _giftsRef(coupleId).doc(giftId);
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) return;
      final gift = SentGift.fromMap(doc.data()!);
      if (gift.toUid != uid || gift.opened || gift.seenAt != null) return;
      tx.update(ref, {
        'seenAt': Timestamp.now(),
        'deliveryStatus': GiftDeliveryStatus.seen.name,
      });
    });
  }

  /// فتح هدية — المستلم فقط، ومرة واحدة
  Future<void> openGift({
    required String coupleId,
    required String giftId,
    required String uid,
  }) async {
    final ref = _giftsRef(coupleId).doc(giftId);
    SentGift? openedGift;
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) return;
      final gift = SentGift.fromMap(doc.data()!);
      if (gift.toUid != uid || gift.opened) return;
      final now = Timestamp.now();
      tx.update(ref, {
        'opened': true,
        'openedAt': now,
        'seenAt': gift.seenAt == null ? now : Timestamp.fromDate(gift.seenAt!),
        'deliveryStatus': GiftDeliveryStatus.opened.name,
      });
      openedGift = gift;
    });

    // إشعار للمرسل بأن هديته فُتحت
    if (openedGift != null) {
      try {
        await _notify.giftOpened(
          toUid: openedGift!.fromUid,
          fromUid: uid,
          openerName: openedGift!.receiverSnapshot?.name ?? 'شريكك',
          giftName: openedGift!.name,
          giftId: openedGift!.id,
        );
      } catch (_) {}
    }
  }

  /// رد فعل على هدية — المستلم فقط
  Future<void> reactToGift({
    required String coupleId,
    required String giftId,
    required String uid,
    required String reaction,
  }) async {
    final ref = _giftsRef(coupleId).doc(giftId);
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) return;
      final gift = SentGift.fromMap(doc.data()!);
      if (gift.toUid != uid) return;
      tx.update(ref, {'reaction': reaction});
    });
  }
}
