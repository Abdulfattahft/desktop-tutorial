import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج المستخدم كما يُخزَّن في Firestore (مجموعة users)
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String inviteCode; // رمز الدعوة الخاص بالمستخدم
  final String? partnerId; // uid الشريك بعد الربط
  final String? coupleId; // معرف مستند الزوجين في couples
  final String? photoUrl;
  final int points;
  final int coins; // عملات شراء الهدايا
  final int level;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime lastActive;
  final DateTime? weddingDate; // موعد الزواج للعداد التنازلي

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.inviteCode,
    this.partnerId,
    this.coupleId,
    this.photoUrl,
    this.points = 0,
    this.coins = 0,
    this.level = 1,
    this.fcmToken,
    required this.createdAt,
    required this.lastActive,
    this.weddingDate,
  });

  bool get isLinked => partnerId != null && coupleId != null;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'inviteCode': inviteCode,
        'partnerId': partnerId,
        'coupleId': coupleId,
        'photoUrl': photoUrl,
        'points': points,
        'coins': coins,
        'level': level,
        'fcmToken': fcmToken,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastActive': Timestamp.fromDate(lastActive),
        'weddingDate':
            weddingDate == null ? null : Timestamp.fromDate(weddingDate!),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] as String,
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        inviteCode: map['inviteCode'] as String? ?? '',
        partnerId: map['partnerId'] as String?,
        coupleId: map['coupleId'] as String?,
        photoUrl: map['photoUrl'] as String?,
        points: (map['points'] as num?)?.toInt() ?? 0,
        coins: (map['coins'] as num?)?.toInt() ?? 0,
        level: (map['level'] as num?)?.toInt() ?? 1,
        fcmToken: map['fcmToken'] as String?,
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastActive:
            (map['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
        weddingDate: (map['weddingDate'] as Timestamp?)?.toDate(),
      );

  UserModel copyWith({
    String? name,
    String? partnerId,
    String? coupleId,
    String? photoUrl,
    int? points,
    int? coins,
    int? level,
    String? fcmToken,
    DateTime? lastActive,
    DateTime? weddingDate,
  }) =>
      UserModel(
        uid: uid,
        name: name ?? this.name,
        email: email,
        inviteCode: inviteCode,
        partnerId: partnerId ?? this.partnerId,
        coupleId: coupleId ?? this.coupleId,
        photoUrl: photoUrl ?? this.photoUrl,
        points: points ?? this.points,
        coins: coins ?? this.coins,
        level: level ?? this.level,
        fcmToken: fcmToken ?? this.fcmToken,
        createdAt: createdAt,
        lastActive: lastActive ?? this.lastActive,
        weddingDate: weddingDate ?? this.weddingDate,
      );
}
