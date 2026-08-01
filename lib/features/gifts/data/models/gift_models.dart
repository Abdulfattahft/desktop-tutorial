import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// تصنيفات الهدايا
enum GiftCategory { roses, chocolate, coffee, messages, occasions, special }

extension GiftCategoryX on GiftCategory {
  String get label => switch (this) {
        GiftCategory.roses => 'ورود',
        GiftCategory.chocolate => 'شوكولاتة',
        GiftCategory.coffee => 'قهوة',
        GiftCategory.messages => 'رسائل',
        GiftCategory.occasions => 'مناسبات',
        GiftCategory.special => 'مميزة',
      };

  String get emoji => switch (this) {
        GiftCategory.roses => '🌹',
        GiftCategory.chocolate => '🍫',
        GiftCategory.coffee => '☕',
        GiftCategory.messages => '💌',
        GiftCategory.occasions => '🎉',
        GiftCategory.special => '👑',
      };
}

/// ندرة الهدية
enum GiftRarity { common, rare, legendary }

extension GiftRarityX on GiftRarity {
  String get label => switch (this) {
        GiftRarity.common => 'عادية',
        GiftRarity.rare => 'نادرة',
        GiftRarity.legendary => 'أسطورية',
      };

  Color get defaultColor => switch (this) {
        GiftRarity.common => AppColors.textSecondary,
        GiftRarity.rare => const Color(0xFF5B8DEF),
        GiftRarity.legendary => AppColors.secondary,
      };
}

/// حالة تسليم الهدية — للمزامنة والإشعارات مستقبلًا
enum GiftDeliveryStatus { sent, delivered, seen, opened }

/// سبب قفل الهدية (للعرض في الواجهة)
class GiftLock {
  final String reason;
  const GiftLock(this.reason);
}

/// ===== عنصر كتالوج الهدايا =====
/// كل الحقول الاختيارية لها قيم افتراضية آمنة، فالمستندات القديمة
/// (أو الناقصة الحقول) تعمل بدون أي تعديل
class GiftCatalogItem {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int price;
  final GiftCategory category;
  final GiftRarity rarity;

  // ===== حقول التحكم والجدولة =====
  final bool enabled; // افتراضي: true
  final int sortOrder; // افتراضي: 100
  final DateTime? startDate; // متاحة من
  final DateTime? endDate; // متاحة حتى
  final bool isLimited; // شارة "لفترة محدودة"
  final bool isSeasonal; // هدية موسمية
  final bool isNew; // شارة "جديد"

  // ===== شروط الفتح =====
  final int requiredLevel; // افتراضي: 0 (بدون شرط)
  final int requiredStreak; // افتراضي: 0
  final String? requiredAchievement; // معرّف إنجاز مستقبلي
  final int maxPurchasesPerDay; // افتراضي: 0 = بلا حد

  // ===== العرض والتوسعة =====
  final List<String> tags; // للبحث/التجميع مستقبلًا
  final String animationType; // افتراضي: 'default'
  final String? rarityColorHex; // لون مخصص يتجاوز لون الندرة
  final String? previewImage; // صورة كبيرة (URL)
  final String? thumbnailImage; // صورة مصغرة (URL)
  final Map<String, dynamic> extra; // أي حقول مستقبلية غير معروفة

  const GiftCatalogItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.price,
    required this.category,
    required this.rarity,
    this.enabled = true,
    this.sortOrder = 100,
    this.startDate,
    this.endDate,
    this.isLimited = false,
    this.isSeasonal = false,
    this.isNew = false,
    this.requiredLevel = 0,
    this.requiredStreak = 0,
    this.requiredAchievement,
    this.maxPurchasesPerDay = 0,
    this.tags = const [],
    this.animationType = 'default',
    this.rarityColorHex,
    this.previewImage,
    this.thumbnailImage,
    this.extra = const {},
  });

  /// اللون المعروض: المخصص إن وُجد، وإلا لون الندرة
  Color get displayColor {
    if (rarityColorHex != null) {
      final hex = rarityColorHex!.replaceAll('#', '');
      final value = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
      if (value != null) return Color(value);
    }
    return rarity.defaultColor;
  }

  /// هل الهدية ضمن نافذتها الزمنية ومفعّلة؟
  bool get isAvailable {
    if (!enabled) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  /// هل انتهت صلاحيتها قريبًا؟ (لعرض العد التنازلي)
  bool get endsSoon =>
      endDate != null &&
      endDate!.difference(DateTime.now()).inDays <= 7 &&
      endDate!.isAfter(DateTime.now());

  /// التحقق من شروط الفتح — يعيد null إذا كانت متاحة للشراء
  GiftLock? lockFor({
    required int coupleLevel,
    required int coupleStreak,
    required List<String> achievements,
  }) {
    if (requiredLevel > 0 && coupleLevel < requiredLevel) {
      return GiftLock('تُفتح عند المستوى $requiredLevel');
    }
    if (requiredStreak > 0 && coupleStreak < requiredStreak) {
      return GiftLock('تحتاج ستريك $requiredStreak أيام 🔥');
    }
    if (requiredAchievement != null &&
        !achievements.contains(requiredAchievement)) {
      return const GiftLock('تحتاج إنجازًا خاصًا 🏅');
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'description': description,
        'price': price,
        'category': category.name,
        'rarity': rarity.name,
        'enabled': enabled,
        'sortOrder': sortOrder,
        'startDate':
            startDate == null ? null : Timestamp.fromDate(startDate!),
        'endDate': endDate == null ? null : Timestamp.fromDate(endDate!),
        'isLimited': isLimited,
        'isSeasonal': isSeasonal,
        'isNew': isNew,
        'requiredLevel': requiredLevel,
        'requiredStreak': requiredStreak,
        'requiredAchievement': requiredAchievement,
        'maxPurchasesPerDay': maxPurchasesPerDay,
        'tags': tags,
        'animationType': animationType,
        'rarityColor': rarityColorHex,
        'previewImage': previewImage,
        'thumbnailImage': thumbnailImage,
        ...extra,
      };

  /// كل قراءة محمية بقيمة افتراضية — حقل ناقص لا يكسر شيئًا
  factory GiftCatalogItem.fromMap(Map<String, dynamic> map) {
    const known = {
      'id', 'name', 'emoji', 'description', 'price', 'category', 'rarity',
      'enabled', 'sortOrder', 'startDate', 'endDate', 'isLimited',
      'isSeasonal', 'isNew', 'requiredLevel', 'requiredStreak',
      'requiredAchievement', 'maxPurchasesPerDay', 'tags', 'animationType',
      'rarityColor', 'previewImage', 'thumbnailImage',
    };

    GiftCategory parseCategory(String? v) {
      try {
        return GiftCategory.values.byName(v ?? 'special');
      } catch (_) {
        return GiftCategory.special; // نوع غير معروف → لا ينهار التطبيق
      }
    }

    GiftRarity parseRarity(String? v) {
      try {
        return GiftRarity.values.byName(v ?? 'common');
      } catch (_) {
        return GiftRarity.common;
      }
    }

    return GiftCatalogItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'هدية',
      emoji: map['emoji'] as String? ?? '🎁',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      category: parseCategory(map['category'] as String?),
      rarity: parseRarity(map['rarity'] as String?),
      enabled: map['enabled'] as bool? ?? true,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 100,
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      isLimited: map['isLimited'] as bool? ?? (map['endDate'] != null),
      isSeasonal: map['isSeasonal'] as bool? ?? false,
      isNew: map['isNew'] as bool? ?? false,
      requiredLevel: (map['requiredLevel'] as num?)?.toInt() ?? 0,
      requiredStreak: (map['requiredStreak'] as num?)?.toInt() ?? 0,
      requiredAchievement: map['requiredAchievement'] as String?,
      maxPurchasesPerDay:
          (map['maxPurchasesPerDay'] as num?)?.toInt() ?? 0,
      tags: List<String>.from(map['tags'] as List? ?? const []),
      animationType: map['animationType'] as String? ?? 'default',
      rarityColorHex: map['rarityColor'] as String?,
      previewImage: map['previewImage'] as String?,
      thumbnailImage: map['thumbnailImage'] as String?,
      // أي حقول مستقبلية نضيفها في Console تُحفظ ولا تُفقد
      extra: Map<String, dynamic>.fromEntries(
          map.entries.where((e) => !known.contains(e.key))),
    );
  }
}

/// لقطة مختصرة عن طرف وقت الإرسال (للسجل والإحصائيات)
class GiftUserSnapshot {
  final String uid;
  final String name;
  final String? photoUrl;
  final int level;

  const GiftUserSnapshot({
    required this.uid,
    required this.name,
    this.photoUrl,
    this.level = 1,
  });

  Map<String, dynamic> toMap() =>
      {'uid': uid, 'name': name, 'photoUrl': photoUrl, 'level': level};

  factory GiftUserSnapshot.fromMap(Map<String, dynamic> map) =>
      GiftUserSnapshot(
        uid: map['uid'] as String? ?? '',
        name: map['name'] as String? ?? '',
        photoUrl: map['photoUrl'] as String?,
        level: (map['level'] as num?)?.toInt() ?? 1,
      );
}

/// ===== هدية مرسلة =====
/// Snapshot من بيانات الهدية وقت الإرسال + حقول مستقبلية
class SentGift {
  final String id;
  final String giftId;
  final String name;
  final String emoji;
  final int price;
  final GiftCategory category;
  final GiftRarity rarity;
  final String fromUid;
  final String toUid;
  final DateTime sentAt;

  // ===== حقول التفاعل والمزامنة =====
  final String? message; // رسالة شخصية مع الهدية
  final bool opened;
  final DateTime? openedAt;
  final DateTime? seenAt; // شاهد الإشعار/الوارد دون فتح
  final String? reaction; // رد فعل (إيموجي) على الهدية
  final GiftDeliveryStatus deliveryStatus;
  final GiftUserSnapshot? senderSnapshot;
  final GiftUserSnapshot? receiverSnapshot;
  final String animationType;
  final String? thumbnailImage;
  final Map<String, dynamic> extra;

  const SentGift({
    required this.id,
    required this.giftId,
    required this.name,
    required this.emoji,
    required this.price,
    required this.category,
    required this.rarity,
    required this.fromUid,
    required this.toUid,
    required this.sentAt,
    this.message,
    this.opened = false,
    this.openedAt,
    this.seenAt,
    this.reaction,
    this.deliveryStatus = GiftDeliveryStatus.sent,
    this.senderSnapshot,
    this.receiverSnapshot,
    this.animationType = 'default',
    this.thumbnailImage,
    this.extra = const {},
  });

  String senderNameOr(String fallback) => senderSnapshot?.name ?? fallback;

  Map<String, dynamic> toMap() => {
        'id': id,
        'giftId': giftId,
        'name': name,
        'emoji': emoji,
        'price': price,
        'category': category.name,
        'rarity': rarity.name,
        'fromUid': fromUid,
        'toUid': toUid,
        'sentAt': Timestamp.fromDate(sentAt),
        'message': message,
        'opened': opened,
        'openedAt': openedAt == null ? null : Timestamp.fromDate(openedAt!),
        'seenAt': seenAt == null ? null : Timestamp.fromDate(seenAt!),
        'reaction': reaction,
        'deliveryStatus': deliveryStatus.name,
        'senderSnapshot': senderSnapshot?.toMap(),
        'receiverSnapshot': receiverSnapshot?.toMap(),
        'animationType': animationType,
        'thumbnailImage': thumbnailImage,
        ...extra,
      };

  factory SentGift.fromMap(Map<String, dynamic> map) {
    const known = {
      'id', 'giftId', 'name', 'emoji', 'price', 'category', 'rarity',
      'fromUid', 'toUid', 'sentAt', 'message', 'opened', 'openedAt',
      'seenAt', 'reaction', 'deliveryStatus', 'senderSnapshot',
      'receiverSnapshot', 'animationType', 'thumbnailImage',
    };

    GiftDeliveryStatus parseStatus(String? v, bool opened) {
      try {
        if (v != null) return GiftDeliveryStatus.values.byName(v);
      } catch (_) {}
      // توافق مع المستندات القديمة التي لا تحمل الحقل
      return opened ? GiftDeliveryStatus.opened : GiftDeliveryStatus.sent;
    }

    final opened = map['opened'] as bool? ?? false;
    final sender = map['senderSnapshot'];
    final receiver = map['receiverSnapshot'];

    return SentGift(
      id: map['id'] as String? ?? '',
      giftId: map['giftId'] as String? ?? '',
      name: map['name'] as String? ?? 'هدية',
      emoji: map['emoji'] as String? ?? '🎁',
      price: (map['price'] as num?)?.toInt() ?? 0,
      category: (() {
        try {
          return GiftCategory.values
              .byName(map['category'] as String? ?? 'special');
        } catch (_) {
          return GiftCategory.special;
        }
      })(),
      rarity: (() {
        try {
          return GiftRarity.values
              .byName(map['rarity'] as String? ?? 'common');
        } catch (_) {
          return GiftRarity.common;
        }
      })(),
      fromUid: map['fromUid'] as String? ?? '',
      toUid: map['toUid'] as String? ?? '',
      sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      message: map['message'] as String?,
      opened: opened,
      openedAt: (map['openedAt'] as Timestamp?)?.toDate(),
      seenAt: (map['seenAt'] as Timestamp?)?.toDate(),
      reaction: map['reaction'] as String?,
      deliveryStatus:
          parseStatus(map['deliveryStatus'] as String?, opened),
      senderSnapshot: sender == null
          ? null
          : GiftUserSnapshot.fromMap(Map<String, dynamic>.from(sender)),
      receiverSnapshot: receiver == null
          ? null
          : GiftUserSnapshot.fromMap(Map<String, dynamic>.from(receiver)),
      animationType: map['animationType'] as String? ?? 'default',
      thumbnailImage: map['thumbnailImage'] as String?,
      extra: Map<String, dynamic>.fromEntries(
          map.entries.where((e) => !known.contains(e.key))),
    );
  }
}

/// إحصائيات محسوبة من سجل الهدايا
class GiftStats {
  final int sentCount;
  final int receivedCount;
  final GiftCategory? topSentCategory;
  final int totalCoinsSpent;

  const GiftStats({
    required this.sentCount,
    required this.receivedCount,
    required this.topSentCategory,
    required this.totalCoinsSpent,
  });

  factory GiftStats.compute(List<SentGift> all, String myUid) {
    final sent = all.where((g) => g.fromUid == myUid).toList();
    final received = all.where((g) => g.toUid == myUid).toList();

    GiftCategory? top;
    var best = 0;
    for (final c in GiftCategory.values) {
      final count = sent.where((g) => g.category == c).length;
      if (count > best) {
        best = count;
        top = c;
      }
    }
    return GiftStats(
      sentCount: sent.length,
      receivedCount: received.length,
      topSentCategory: top,
      totalCoinsSpent: sent.fold(0, (acc, g) => acc + g.price),
    );
  }
}
