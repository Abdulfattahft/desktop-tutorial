import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../notifications/data/repositories/notification_events.dart';
import '../../../notifications/data/repositories/notifications_repository.dart';
import '../content/challenges_content.dart';
import '../models/challenge_models.dart';

/// استثناء تحديات برسالة عربية
class ChallengeException implements Exception {
  final String message;
  const ChallengeException(this.message);
}

/// مستودع التحديات
/// - توليد حتمي (Deterministic): نفس اليوم + نفس الزوجين = نفس التحديات
///   على أي جهاز، ومعرّف المستند ثابت فلا تكرار أبدًا
/// - استلام المكافأة داخل Transaction بحُرّاس تمنع الاستلام مرتين
class ChallengesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationEvents _notify =
      NotificationEvents(NotificationsRepository());

  DocumentReference<Map<String, dynamic>> _coupleRef(String coupleId) =>
      _db.collection(AppConstants.couplesCollection).doc(coupleId);

  CollectionReference<Map<String, dynamic>> _challengesRef(String coupleId) =>
      _coupleRef(coupleId).collection(AppConstants.challengesCollection);

  // ===== أدوات التاريخ =====
  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// رقم الأسبوع بصيغة ISO تقريبية (كافية للتوليد الفريد)
  static String _weekKey(DateTime d) {
    final firstDay = DateTime(d.year, 1, 1);
    final week = ((d.difference(firstDay).inDays + firstDay.weekday) / 7)
        .ceil();
    return '${d.year}-W${week.toString().padLeft(2, '0')}';
  }

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59);

  static DateTime _endOfWeek(DateTime d) {
    // نهاية الأسبوع = نهاية يوم السبت القادم (بداية الأسبوع أحد)
    final daysToSaturday = (DateTime.saturday - d.weekday) % 7;
    final sat = d.add(Duration(days: daysToSaturday));
    return _endOfDay(sat);
  }

  /// بذرة حتمية من نص — نفس المدخل يعطي نفس الرقم على كل الأجهزة
  static int _seed(String input) {
    var h = 0;
    for (final c in input.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }

  /// توليد تحديات اليوم/الأسبوع إن لم تكن موجودة — آمن ضد التسابق:
  /// المعرّفات ثابتة والإنشاء داخل Transaction تتحقق من الوجود أولًا
  Future<void> ensureChallenges(String coupleId) async {
    final now = DateTime.now();
    final dayKey = _dateKey(now);
    final weekKey = _weekKey(now);

    // تحديان يوميان مختلفان + تحدٍ أسبوعي
    final dailyPool = ChallengesContent.daily;
    final s = _seed('$coupleId|$dayKey');
    final i1 = s % dailyPool.length;
    final i2 = (s ~/ 7 + 1 + i1) % dailyPool.length == i1
        ? (i1 + 1) % dailyPool.length
        : (s ~/ 7 + 1 + i1) % dailyPool.length;

    final weeklyPool = ChallengesContent.weekly;
    final wi = _seed('$coupleId|$weekKey') % weeklyPool.length;

    final specs = [
      (id: 'daily_${dayKey}_1', tpl: dailyPool[i1], expires: _endOfDay(now)),
      (id: 'daily_${dayKey}_2', tpl: dailyPool[i2], expires: _endOfDay(now)),
      (id: 'weekly_$weekKey', tpl: weeklyPool[wi], expires: _endOfWeek(now)),
    ];

    await _db.runTransaction((tx) async {
      // القراءات كلها أولًا (شرط معاملات Firestore)
      final docs = await Future.wait(
          specs.map((sp) => tx.get(_challengesRef(coupleId).doc(sp.id))));
      final coupleDoc = await tx.get(_coupleRef(coupleId));
      final gamesTotal =
          (coupleDoc.data()?['gamesPlayedTotal'] as num?)?.toInt() ?? 0;

      for (var k = 0; k < specs.length; k++) {
        if (docs[k].exists) continue; // موجود مسبقًا → لا تكرار
        final sp = specs[k];
        final challenge = ChallengeModel(
          id: sp.id,
          templateId: sp.tpl.templateId,
          title: sp.tpl.title,
          description: sp.tpl.description,
          emoji: sp.tpl.emoji,
          period: sp.tpl.period,
          goalType: sp.tpl.goalType,
          target: sp.tpl.target,
          baseCount:
              sp.tpl.goalType == ChallengeGoalType.playGames ? gamesTotal : 0,
          rewardPoints: sp.tpl.rewardPoints,
          rewardCoins: sp.tpl.rewardCoins,
          completedBy: const {},
          claimed: false,
          createdAt: now,
          expiresAt: sp.expires,
        );
        tx.set(_challengesRef(coupleId).doc(sp.id), challenge.toMap());
      }
    });
  }

  /// تيار التحديات غير المنتهية (والمستلمة حديثًا تبقى ظاهرة حتى تنتهي)
  Stream<List<ChallengeModel>> challengesStream(String coupleId) =>
      _challengesRef(coupleId)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => ChallengeModel.fromMap(d.data()))
              .toList());

  /// تسجيل "أنجزت" لتحديات bothAct — Transaction بحُرّاس
  Future<void> markDone({
    required String coupleId,
    required String challengeId,
    required String uid,
  }) async {
    final ref = _challengesRef(coupleId).doc(challengeId);
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) return;
      final c = ChallengeModel.fromMap(doc.data()!);
      if (c.claimed || c.isExpired) return;
      if (c.goalType != ChallengeGoalType.bothAct) return;
      if (c.completedBy[uid] == true) return; // سجّل مسبقًا

      tx.update(ref, {'completedBy.$uid': true});
    });
  }

  /// استلام المكافأة — Transaction واحدة:
  /// تحقق الإكمال الفعلي + منع الاستلام المكرر + منح النقاط والعملات + المستوى
  Future<void> claimReward({
    required String coupleId,
    required String challengeId,
    required String uid,
    required List<String> playerIds,
  }) async {
    final ref = _challengesRef(coupleId).doc(challengeId);
    final coupleRef = _coupleRef(coupleId);
    ChallengeModel? claimed;

    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final coupleDoc = await tx.get(coupleRef);
      if (!doc.exists || !coupleDoc.exists) {
        throw const ChallengeException('حدث خطأ، حاول مرة أخرى');
      }
      final c = ChallengeModel.fromMap(doc.data()!);
      final coupleData = coupleDoc.data()!;

      // ===== الحُرّاس =====
      if (c.claimed) {
        throw const ChallengeException('استلمتما مكافأة هذا التحدي من قبل');
      }
      if (c.isExpired) {
        throw const ChallengeException('انتهى وقت هذا التحدي 😢');
      }
      final progress = c.progressWith(
        coupleStreak: (coupleData['streak'] as num?)?.toInt() ?? 0,
        gamesTotal:
            (coupleData['gamesPlayedTotal'] as num?)?.toInt() ?? 0,
      );
      if (progress < c.target) {
        throw const ChallengeException('التحدي لم يكتمل بعد');
      }

      // ===== منح المكافآت =====
      final newTotal = ((coupleData['totalPoints'] as num?)?.toInt() ?? 0) +
          c.rewardPoints;
      tx.update(ref, {
        'claimed': true,
        'claimedBy': uid,
      });
      tx.update(coupleRef, {
        'totalPoints': newTotal,
        'level': AppConstants.levelForPoints(newTotal),
      });
      for (final pid in playerIds) {
        tx.update(
          _db.collection(AppConstants.usersCollection).doc(pid),
          {
            'points': FieldValue.increment(c.rewardPoints),
            'coins': FieldValue.increment(c.rewardCoins),
          },
        );
      }
      claimed = c;
    });

    // إشعار للطرف الآخر بأن المكافأة استُلمت
    if (claimed != null) {
      final partnerUid = playerIds.firstWhere((p) => p != uid,
          orElse: () => '');
      if (partnerUid.isNotEmpty) {
        try {
          await _notify.rewardClaimed(
            toUid: partnerUid,
            fromUid: uid,
            claimerName: 'شريكك',
            points: claimed!.rewardPoints,
            coins: claimed!.rewardCoins,
            challengeId: challengeId,
          );
        } catch (_) {}
      }
    }
  }
}
