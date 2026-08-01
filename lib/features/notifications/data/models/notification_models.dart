import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// أنواع الإشعارات — أضف نوعًا جديدًا هنا وسيعمل تلقائيًا
/// (القيمة غير المعروفة ترجع إلى system بدل الانهيار)
enum NotificationType {
  giftReceived,
  giftOpened,
  gameStarted,
  gameInvite,
  challengeCompleted,
  rewardClaimed,
  streakWarning,
  memoryAdded,
  commentAdded,
  likeAdded,
  weddingCountdown,
  specialOccasion,
  aiSuggestion, // مستقبلًا
  campaign, // حملات موسمية جماعية
  system,
}

/// فئات الإشعارات — عليها تُبنى إعدادات التفعيل/التعطيل
enum NotificationCategory {
  gifts,
  games,
  memories,
  comments,
  likes,
  challenges,
  occasions,
  system,
}

extension NotificationCategoryX on NotificationCategory {
  String get label => switch (this) {
        NotificationCategory.gifts => 'الهدايا',
        NotificationCategory.games => 'الألعاب',
        NotificationCategory.memories => 'الذكريات',
        NotificationCategory.comments => 'التعليقات',
        NotificationCategory.likes => 'الإعجابات',
        NotificationCategory.challenges => 'التحديات',
        NotificationCategory.occasions => 'المناسبات',
        NotificationCategory.system => 'إشعارات النظام',
      };

  String get emoji => switch (this) {
        NotificationCategory.gifts => '🎁',
        NotificationCategory.games => '🎮',
        NotificationCategory.memories => '📸',
        NotificationCategory.comments => '💬',
        NotificationCategory.likes => '❤️',
        NotificationCategory.challenges => '🔥',
        NotificationCategory.occasions => '🎉',
        NotificationCategory.system => '🔔',
      };

  /// مفتاح التخزين في users/{uid}.notificationPrefs
  String get prefKey => name;
}

extension NotificationTypeX on NotificationType {
  /// كل نوع ينتمي لفئة — الفئة تحدد هل يُرسل الإشعار أم لا
  NotificationCategory get category => switch (this) {
        NotificationType.giftReceived ||
        NotificationType.giftOpened =>
          NotificationCategory.gifts,
        NotificationType.gameStarted ||
        NotificationType.gameInvite =>
          NotificationCategory.games,
        NotificationType.challengeCompleted ||
        NotificationType.rewardClaimed ||
        NotificationType.streakWarning =>
          NotificationCategory.challenges,
        NotificationType.memoryAdded => NotificationCategory.memories,
        NotificationType.commentAdded => NotificationCategory.comments,
        NotificationType.likeAdded => NotificationCategory.likes,
        NotificationType.weddingCountdown ||
        NotificationType.specialOccasion =>
          NotificationCategory.occasions,
        NotificationType.aiSuggestion ||
        NotificationType.campaign ||
        NotificationType.system =>
          NotificationCategory.system,
      };

  IconData get icon => switch (this) {
        NotificationType.giftReceived ||
        NotificationType.giftOpened =>
          Icons.card_giftcard_rounded,
        NotificationType.gameStarted ||
        NotificationType.gameInvite =>
          Icons.videogame_asset_rounded,
        NotificationType.challengeCompleted ||
        NotificationType.rewardClaimed =>
          Icons.emoji_events_rounded,
        NotificationType.streakWarning =>
          Icons.local_fire_department_rounded,
        NotificationType.memoryAdded => Icons.photo_library_rounded,
        NotificationType.commentAdded => Icons.chat_bubble_rounded,
        NotificationType.likeAdded => Icons.favorite_rounded,
        NotificationType.weddingCountdown => Icons.favorite_border_rounded,
        NotificationType.specialOccasion => Icons.celebration_rounded,
        NotificationType.aiSuggestion => Icons.auto_awesome_rounded,
        NotificationType.campaign => Icons.campaign_rounded,
        NotificationType.system => Icons.notifications_rounded,
      };

  Color get color => switch (category) {
        NotificationCategory.gifts => AppColors.secondary,
        NotificationCategory.games => AppColors.primary,
        NotificationCategory.memories => const Color(0xFF9C7BB8),
        NotificationCategory.comments => const Color(0xFF5EA3A3),
        NotificationCategory.likes => AppColors.primaryDark,
        NotificationCategory.challenges => const Color(0xFFE08E45),
        NotificationCategory.occasions => AppColors.secondaryLight,
        NotificationCategory.system => AppColors.textSecondary,
      };
}

/// أولوية الإشعار — تؤثر على الترتيب وصوت الـ Push مستقبلًا
enum NotificationPriority { low, normal, high }

/// إشعار مخزن في users/{uid}/notifications/{id}
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic> data; // حمولة مرنة (giftId, memoryId…)
  final String? actionRoute; // للـ Deep Linking
  final NotificationPriority priority;
  final String? imageUrl;
  final DateTime? expiresAt;
  final String? dedupeKey; // منع تكرار نفس الحدث
  final String? fromUid;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.data = const {},
    this.actionRoute,
    this.priority = NotificationPriority.normal,
    this.imageUrl,
    this.expiresAt,
    this.dedupeKey,
    this.fromUid,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'category': type.category.name, // مفيد للاستعلامات والـ Function
        'title': title,
        'body': body,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': isRead,
        'data': data,
        'actionRoute': actionRoute,
        'priority': priority.name,
        'imageUrl': imageUrl,
        'expiresAt':
            expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
        'dedupeKey': dedupeKey,
        'fromUid': fromUid,
        'pushSent': false, // تضبطها Cloud Function بعد الإرسال
      };

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    NotificationType parseType(String? v) {
      try {
        return NotificationType.values.byName(v ?? 'system');
      } catch (_) {
        return NotificationType.system;
      }
    }

    NotificationPriority parsePriority(String? v) {
      try {
        return NotificationPriority.values.byName(v ?? 'normal');
      } catch (_) {
        return NotificationPriority.normal;
      }
    }

    return AppNotification(
      id: map['id'] as String? ?? '',
      type: parseType(map['type'] as String?),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
      data: Map<String, dynamic>.from(map['data'] as Map? ?? const {}),
      actionRoute: map['actionRoute'] as String?,
      priority: parsePriority(map['priority'] as String?),
      imageUrl: map['imageUrl'] as String?,
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      dedupeKey: map['dedupeKey'] as String?,
      fromUid: map['fromUid'] as String?,
    );
  }
}

/// تفضيلات الإشعارات لكل مستخدم — الافتراضي: كل الفئات مفعّلة
class NotificationPrefs {
  final Map<String, bool> categories;

  const NotificationPrefs(this.categories);

  factory NotificationPrefs.fromMap(Map<String, dynamic>? map) =>
      NotificationPrefs(Map<String, bool>.from(map ?? const {}));

  /// أي فئة غير مذكورة = مفعّلة (سلوك آمن للمستخدمين القدامى)
  bool isEnabled(NotificationCategory c) => categories[c.prefKey] ?? true;

  Map<String, dynamic> toMap() => categories;
}
