import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج مستند الزوجين في مجموعة couples
class CoupleModel {
  final String id;
  final List<String> userIds; // [uid1, uid2] — تسهّل الاستعلام بـ arrayContains
  final Map<String, String> names; // uid → الاسم
  final DateTime createdAt;
  final DateTime? weddingDate;
  final int totalPoints; // نقاط العلاقة المشتركة
  final int level;
  final int streak; // أيام متتالية من النشاط المشترك
  final int gamesPlayedTotal; // عداد تراكمي للألعاب (لتتبع تقدم التحديات)
  final List<String> achievements; // إنجازات مفتوحة (لشروط الهدايا لاحقًا)

  const CoupleModel({
    required this.id,
    required this.userIds,
    required this.names,
    required this.createdAt,
    this.weddingDate,
    this.totalPoints = 0,
    this.level = 1,
    this.streak = 0,
    this.gamesPlayedTotal = 0,
    this.achievements = const [],
  });

  /// uid الشريك الآخر
  String partnerOf(String uid) => userIds.firstWhere((id) => id != uid);

  String partnerNameOf(String uid) => names[partnerOf(uid)] ?? 'شريكك';

  Map<String, dynamic> toMap() => {
        'id': id,
        'userIds': userIds,
        'names': names,
        'createdAt': Timestamp.fromDate(createdAt),
        'weddingDate':
            weddingDate == null ? null : Timestamp.fromDate(weddingDate!),
        'totalPoints': totalPoints,
        'level': level,
        'streak': streak,
        'gamesPlayedTotal': gamesPlayedTotal,
        'achievements': achievements,
      };

  factory CoupleModel.fromMap(Map<String, dynamic> map) => CoupleModel(
        id: map['id'] as String,
        userIds: List<String>.from(map['userIds'] as List),
        names: Map<String, String>.from(map['names'] as Map),
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        weddingDate: (map['weddingDate'] as Timestamp?)?.toDate(),
        totalPoints: (map['totalPoints'] as num?)?.toInt() ?? 0,
        level: (map['level'] as num?)?.toInt() ?? 1,
        streak: (map['streak'] as num?)?.toInt() ?? 0,
        gamesPlayedTotal:
            (map['gamesPlayedTotal'] as num?)?.toInt() ?? 0,
        achievements:
            List<String>.from(map['achievements'] as List? ?? const []),
      );
}
