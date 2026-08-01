import '../models/notification_models.dart';
import 'notifications_repository.dart';

/// طبقة وسيطة: تحوّل أحداث التطبيق إلى إشعارات جاهزة
/// كل دالة هنا = حدث واحد، فالنصوص والمسارات في مكان واحد
class NotificationEvents {
  final NotificationsRepository _repo;
  const NotificationEvents(this._repo);

  /// وصول هدية
  Future<void> giftReceived({
    required String toUid,
    required String fromUid,
    required String senderName,
    required String giftName,
    required String giftEmoji,
    required String giftId,
  }) =>
      _repo.create(
        toUid: toUid,
        fromUid: fromUid,
        type: NotificationType.giftReceived,
        title: 'وصلتك هدية! $giftEmoji',
        body: '$senderName أرسل لك $giftName — افتحها الحين',
        data: {'giftId': giftId},
        actionRoute: '/gifts',
        priority: NotificationPriority.high,
        dedupeKey: 'gift_$giftId',
      );

  /// فتح الهدية (للمرسل)
  Future<void> giftOpened({
    required String toUid,
    required String fromUid,
    required String openerName,
    required String giftName,
    required String giftId,
  }) =>
      _repo.create(
        toUid: toUid,
        fromUid: fromUid,
        type: NotificationType.giftOpened,
        title: 'فتح هديتك 🥹',
        body: '$openerName فتح $giftName اللي أرسلته',
        data: {'giftId': giftId},
        actionRoute: '/gifts',
        dedupeKey: 'gift_opened_$giftId',
      );

  /// بدء لعبة / دعوة للعب
  Future<void> gameStarted({
    required String toUid,
    required String fromUid,
    required String partnerName,
    required String gameTitle,
    required String gameType,
  }) =>
      _repo.create(
        toUid: toUid,
        fromUid: fromUid,
        type: NotificationType.gameStarted,
        title: 'شريكك بدأ لعبة! 🎮',
        body: '$partnerName ينتظرك في "$gameTitle" — يلا الحقه',
        data: {'gameType': gameType},
        actionRoute: '/games/$gameType',
        priority: NotificationPriority.high,
        // مفتاح باليوم والساعة: لا يتكرر لنفس الجلسة
        dedupeKey:
            'game_${gameType}_${DateTime.now().toIso8601String().substring(0, 13)}',
      );

  /// اكتمال تحدٍ
  Future<void> challengeCompleted({
    required String toUid,
    required String fromUid,
    required String challengeTitle,
    required String challengeId,
  }) =>
      _repo.create(
        toUid: toUid,
        fromUid: fromUid,
        type: NotificationType.challengeCompleted,
        title: 'اكتمل التحدي! 🎯',
        body: '"$challengeTitle" جاهز — استلما المكافأة',
        data: {'challengeId': challengeId},
        actionRoute: '/challenges',
        dedupeKey: 'challenge_done_$challengeId',
      );

  /// استلام مكافأة
  Future<void> rewardClaimed({
    required String toUid,
    required String fromUid,
    required String claimerName,
    required int points,
    required int coins,
    required String challengeId,
  }) =>
      _repo.create(
        toUid: toUid,
        fromUid: fromUid,
        type: NotificationType.rewardClaimed,
        title: 'استلمتما المكافأة 🎁',
        body: '$claimerName استلم +$points نقطة و +$coins عملة لكما',
        data: {'challengeId': challengeId},
        actionRoute: '/challenges',
        dedupeKey: 'reward_$challengeId',
      );

  /// ذكرى جديدة
  Future<void> memoryAdded({
    required String toUid,
    required String fromUid,
    required String authorName,
    required String memoryTitle,
    required String memoryId,
  }) =>
      _repo.create(
        toUid: toUid,
        fromUid: fromUid,
        type: NotificationType.memoryAdded,
        title: 'ذكرى جديدة 📸',
        body: '$authorName أضاف "$memoryTitle"',
        data: {'memoryId': memoryId},
        actionRoute: '/memories',
        dedupeKey: 'memory_$memoryId',
      );

  /// تعليق جديد
  Future<void> commentAdded({
    required String toUid,
    required String fromUid,
    required String authorName,
    required String memoryTitle,
    required String memoryId,
    required String commentAt,
  }) =>
      _repo.create(
        toUid: toUid,
        fromUid: fromUid,
        type: NotificationType.commentAdded,
        title: 'تعليق جديد 💬',
        body: '$authorName علّق على "$memoryTitle"',
        data: {'memoryId': memoryId},
        actionRoute: '/memories',
        dedupeKey: 'comment_${memoryId}_$commentAt',
      );

  /// إعجاب جديد
  Future<void> likeAdded({
    required String toUid,
    required String fromUid,
    required String likerName,
    required String memoryTitle,
    required String memoryId,
  }) =>
      _repo.create(
        toUid: toUid,
        fromUid: fromUid,
        type: NotificationType.likeAdded,
        title: 'أعجبته ذكراكما ❤️',
        body: '$likerName أعجب بـ"$memoryTitle"',
        data: {'memoryId': memoryId},
        actionRoute: '/memories',
        priority: NotificationPriority.low,
        dedupeKey: 'like_${memoryId}_$fromUid',
      );

  /// تحذير انقطاع الستريك (يُنشأ من Cloud Function المجدولة)
  Future<void> streakWarning({
    required String toUid,
    required int streak,
  }) =>
      _repo.create(
        toUid: toUid,
        type: NotificationType.streakWarning,
        title: 'ستريككما بخطر! 🔥',
        body: '$streak أيام متتالية… العبا لعبة اليوم قبل ما ينكسر',
        actionRoute: '/games',
        priority: NotificationPriority.high,
        dedupeKey:
            'streak_${DateTime.now().toIso8601String().substring(0, 10)}',
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
      );

  /// اقتراب موعد الزواج
  Future<void> weddingCountdown({
    required String toUid,
    required int daysLeft,
  }) =>
      _repo.create(
        toUid: toUid,
        type: NotificationType.weddingCountdown,
        title: 'باقي $daysLeft يوم على زواجكما! 💍',
        body: 'العد التنازلي مستمر… استعدا للحظة الكبيرة',
        actionRoute: '/home',
        dedupeKey: 'wedding_$daysLeft',
      );
}
