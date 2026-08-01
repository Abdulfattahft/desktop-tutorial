import 'package:cloud_firestore/cloud_firestore.dart';

/// فترة التحدي — أضف قيمة جديدة (موسمي، مناسبة…) وسيتعامل معها النظام
enum ChallengePeriod { daily, weekly }

/// نوع هدف التحدي — كل نوع له طريقة حساب تقدم مختلفة:
/// - bothAct: كل طرف يضغط "أنجزت" (الهدف دائمًا 2)
/// - playGames: عدد الألعاب المنجزة منذ إنشاء التحدي (من عداد الزوجين)
/// - reachStreak: الوصول لستريك معين (يُقرأ مباشرة من مستند الزوجين)
enum ChallengeGoalType { bothAct, playGames, reachStreak }

/// قالب تحدٍ — منه يولَّد التحدي الفعلي
class ChallengeTemplate {
  final String templateId;
  final String title;
  final String description;
  final String emoji;
  final ChallengePeriod period;
  final ChallengeGoalType goalType;
  final int target;
  final int rewardPoints;
  final int rewardCoins;

  const ChallengeTemplate({
    required this.templateId,
    required this.title,
    required this.description,
    required this.emoji,
    required this.period,
    required this.goalType,
    required this.target,
    required this.rewardPoints,
    required this.rewardCoins,
  });
}

/// تحدٍ فعلي مخزن في couples/{coupleId}/challenges/{id}
class ChallengeModel {
  final String id; // daily_2026-08-01_1 أو weekly_2026-W31 → يمنع التكرار
  final String templateId;
  final String title;
  final String description;
  final String emoji;
  final ChallengePeriod period;
  final ChallengeGoalType goalType;
  final int target;
  final int baseCount; // قيمة عداد الألعاب لحظة الإنشاء (لنوع playGames)
  final int rewardPoints;
  final int rewardCoins;
  final Map<String, bool> completedBy; // لنوع bothAct
  final bool claimed;
  final String? claimedBy;
  final DateTime createdAt;
  final DateTime expiresAt;

  const ChallengeModel({
    required this.id,
    required this.templateId,
    required this.title,
    required this.description,
    required this.emoji,
    required this.period,
    required this.goalType,
    required this.target,
    required this.baseCount,
    required this.rewardPoints,
    required this.rewardCoins,
    required this.completedBy,
    required this.claimed,
    this.claimedBy,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// حساب التقدم الحالي (يحتاج بيانات الزوجين للأنواع المعتمدة عليها)
  int progressWith({required int coupleStreak, required int gamesTotal}) {
    switch (goalType) {
      case ChallengeGoalType.bothAct:
        return completedBy.values.where((v) => v).length;
      case ChallengeGoalType.playGames:
        return (gamesTotal - baseCount).clamp(0, target);
      case ChallengeGoalType.reachStreak:
        return coupleStreak.clamp(0, target);
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'templateId': templateId,
        'title': title,
        'description': description,
        'emoji': emoji,
        'period': period.name,
        'goalType': goalType.name,
        'target': target,
        'baseCount': baseCount,
        'rewardPoints': rewardPoints,
        'rewardCoins': rewardCoins,
        'completedBy': completedBy,
        'claimed': claimed,
        'claimedBy': claimedBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
      };

  factory ChallengeModel.fromMap(Map<String, dynamic> map) => ChallengeModel(
        id: map['id'] as String,
        templateId: map['templateId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        emoji: map['emoji'] as String? ?? '🎯',
        period: ChallengePeriod.values
            .byName(map['period'] as String? ?? 'daily'),
        goalType: ChallengeGoalType.values
            .byName(map['goalType'] as String? ?? 'bothAct'),
        target: (map['target'] as num?)?.toInt() ?? 2,
        baseCount: (map['baseCount'] as num?)?.toInt() ?? 0,
        rewardPoints: (map['rewardPoints'] as num?)?.toInt() ?? 0,
        rewardCoins: (map['rewardCoins'] as num?)?.toInt() ?? 0,
        completedBy: Map<String, bool>.from(
            map['completedBy'] as Map? ?? const {}),
        claimed: map['claimed'] as bool? ?? false,
        claimedBy: map['claimedBy'] as String?,
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        expiresAt:
            (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
