import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../notifications/data/repositories/notification_events.dart';
import '../../../notifications/data/repositories/notifications_repository.dart';
import '../content/games_content.dart';
import '../models/game_models.dart';

/// مستودع الألعاب — كل عمليات الجلسات داخل Transactions
/// لضمان عدم التعارض عند ضغط الطرفين في نفس اللحظة
class GamesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Random _rand = Random();
  final NotificationEvents _notify =
      NotificationEvents(NotificationsRepository());

  DocumentReference<Map<String, dynamic>> _sessionRef(
          String coupleId, GameType type) =>
      _db
          .collection(AppConstants.couplesCollection)
          .doc(coupleId)
          .collection(AppConstants.sessionsCollection)
          .doc(type.name); // معرّف ثابت لكل لعبة = جلسة نشطة واحدة فقط

  CollectionReference<Map<String, dynamic>> _historyRef(String coupleId) =>
      _db
          .collection(AppConstants.couplesCollection)
          .doc(coupleId)
          .collection(AppConstants.gameHistoryCollection);

  /// توليد جولات عشوائية حسب نوع اللعبة
  List<GameRound> _generateRounds(GameType type) {
    final meta = GamesContent.metaOf(type);
    List<GameRound> pickText(List<String> src, {List<String> opts = const []}) {
      final shuffled = List<String>.from(src)..shuffle(_rand);
      return shuffled
          .take(meta.rounds)
          .map((p) => GameRound(prompt: p, options: opts))
          .toList();
    }

    List<GameRound> pickQ(List<Map<String, dynamic>> src) {
      final shuffled = List<Map<String, dynamic>>.from(src)..shuffle(_rand);
      return shuffled
          .take(meta.rounds)
          .map((m) => GameRound(
                prompt: m['q'] as String,
                options: List<String>.from(m['o'] as List),
              ))
          .toList();
    }

    switch (type) {
      case GameType.knowMe:
        return pickText(GamesContent.knowMePrompts);
      case GameType.truth:
        return pickText(GamesContent.truthPrompts);
      case GameType.dares:
        return pickText(GamesContent.darePrompts,
            opts: GamesContent.dareOptions);
      case GameType.whoKnows:
        return pickQ(GamesContent.whoKnowsQuestions);
      case GameType.wouldYouRather:
        return pickQ(GamesContent.wouldYouRatherQuestions);
      case GameType.guess:
        return pickQ(GamesContent.guessQuestions);
      case GameType.wheel:
        // العجلة: الجولات تبدأ فارغة وتُملأ عند اللف
        return List.generate(
          meta.rounds,
          (_) => const GameRound(
              prompt: '', options: GamesContent.wheelOptions),
        );
    }
  }

  /// بدء جلسة أو الانضمام للجلسة النشطة
  /// Transaction على مستند بمعرّف ثابت → مستحيل تتكون جلستان
  Future<void> startOrJoin({
    required String coupleId,
    required GameType type,
    required List<String> playerIds,
    String? starterUid,
    String? starterName,
  }) async {
    final ref = _sessionRef(coupleId, type);
    var createdNew = false;
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (doc.exists) {
        final session = GameSession.fromMap(doc.data()!);
        if (session.status == SessionStatus.playing) {
          return; // جلسة نشطة موجودة → ننضم لها كما هي
        }
      }
      // إنشاء جلسة جديدة
      final session = GameSession(
        id: type.name,
        gameType: type,
        status: SessionStatus.playing,
        currentRound: 0,
        rounds: _generateRounds(type),
        score: 0,
        playerIds: playerIds,
        createdAt: DateTime.now(),
      );
      tx.set(ref, session.toMap());
      createdNew = true;
    });

    // إشعار الشريك عند بدء جلسة جديدة فقط
    if (createdNew && starterUid != null) {
      final partnerUid =
          playerIds.firstWhere((p) => p != starterUid, orElse: () => '');
      if (partnerUid.isNotEmpty) {
        try {
          await _notify.gameStarted(
            toUid: partnerUid,
            fromUid: starterUid,
            partnerName: starterName ?? 'شريكك',
            gameTitle: GamesContent.metaOf(type).title,
            gameType: type.name,
          );
        } catch (_) {}
      }
    }
  }

  /// تيار الجلسة — المزامنة اللحظية بين الطرفين
  Stream<GameSession?> sessionStream(String coupleId, GameType type) =>
      _sessionRef(coupleId, type).snapshots().map(
          (doc) => doc.exists ? GameSession.fromMap(doc.data()!) : null);

  /// إرسال إجابة — Transaction بحُرّاس:
  /// - الجلسة playing والجولة هي الحالية
  /// - المرسل لم يجب مسبقًا
  /// عند اكتمال الإجابتين: حساب التطابق وإضافة نقاط الجولة
  Future<void> submitAnswer({
    required String coupleId,
    required GameType type,
    required int roundIndex,
    required String uid,
    required String answer,
  }) async {
    final ref = _sessionRef(coupleId, type);
    final meta = GamesContent.metaOf(type);

    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) return;
      final session = GameSession.fromMap(doc.data()!);

      // حُرّاس منع التعارض والتكرار
      if (session.status != SessionStatus.playing) return;
      if (session.currentRound != roundIndex) return;
      final round = session.rounds[roundIndex];
      if (round.answeredBy(uid)) return;

      final newAnswers = Map<String, String>.from(round.answers)
        ..[uid] = answer;

      bool? isMatch;
      int addedScore = 0;
      if (newAnswers.length >= 2) {
        // اكتملت الجولة: نقاط أساسية + مكافأة تطابق
        addedScore = AppConstants.pointsPerRound;
        if (meta.scoreOnMatch) {
          final vals = newAnswers.values.toList();
          isMatch = vals[0] == vals[1];
          if (isMatch) addedScore += AppConstants.matchBonus;
        }
      }

      final newRounds = List<GameRound>.from(session.rounds);
      newRounds[roundIndex] =
          round.copyWith(answers: newAnswers, isMatch: isMatch);

      tx.update(ref, {
        'rounds': newRounds.map((r) => r.toMap()).toList(),
        'score': session.score + addedScore,
      });
    });
  }

  /// لفّ العجلة — أول من يلف يحدد النتيجة للطرفين (Transaction)
  /// يعيد index العنصر المختار لعرض حركة الدوران
  Future<int> spinWheel({
    required String coupleId,
    required int roundIndex,
  }) async {
    final ref = _sessionRef(coupleId, GameType.wheel);
    return _db.runTransaction<int>((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) return 0;
      final session = GameSession.fromMap(doc.data()!);
      final round = session.rounds[roundIndex];

      // لو الطرف الآخر لفّ قبلنا بلحظة → نستخدم نتيجته
      if (round.wheelIndex != null) return round.wheelIndex!;

      final idx = _rand.nextInt(GamesContent.wheelItems.length);
      final newRounds = List<GameRound>.from(session.rounds);
      newRounds[roundIndex] = round.copyWith(
        prompt: GamesContent.wheelItems[idx],
        wheelIndex: idx,
      );
      tx.update(ref, {
        'rounds': newRounds.map((r) => r.toMap()).toList(),
      });
      return idx;
    });
  }

  /// الانتقال للجولة التالية أو إنهاء اللعبة
  /// أي طرف يضغط "التالي" — الحارس يضمن التنفيذ مرة واحدة فقط
  /// عند الإنهاء: منح النقاط للزوجين وللمستخدمين + كتابة السجل (نفس الـ Transaction)
  Future<void> advanceOrFinish({
    required String coupleId,
    required GameType type,
    required int fromRound,
  }) async {
    final sessionRef = _sessionRef(coupleId, type);
    final coupleRef =
        _db.collection(AppConstants.couplesCollection).doc(coupleId);

    await _db.runTransaction((tx) async {
      final doc = await tx.get(sessionRef);
      if (!doc.exists) return;
      final session = GameSession.fromMap(doc.data()!);

      // حُرّاس: playing + نفس الجولة + الجولة مكتملة
      if (session.status != SessionStatus.playing) return;
      if (session.currentRound != fromRound) return; // طرف آخر سبقنا
      if (!session.round.bothAnswered) return;

      if (!session.isLastRound) {
        tx.update(sessionRef, {'currentRound': fromRound + 1});
        return;
      }

      // ===== نهاية اللعبة: منح النقاط مرة واحدة =====
      final coupleDoc = await tx.get(coupleRef);
      final coupleData = coupleDoc.data() ?? {};
      final newTotal =
          ((coupleData['totalPoints'] as num?)?.toInt() ?? 0) + session.score;

      // ===== منطق الستريك 🔥 =====
      // لعبتما اليوم؟ الستريك ثابت. أمس؟ +1. قبل أكثر؟ يبدأ من 1
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastPlayedAt =
          (coupleData['lastPlayedAt'] as Timestamp?)?.toDate();
      final lastDay = lastPlayedAt == null
          ? null
          : DateTime(
              lastPlayedAt.year, lastPlayedAt.month, lastPlayedAt.day);
      final currentStreak = (coupleData['streak'] as num?)?.toInt() ?? 0;
      int newStreak;
      if (lastDay == null) {
        newStreak = 1;
      } else if (lastDay == today) {
        newStreak = currentStreak == 0 ? 1 : currentStreak;
      } else if (today.difference(lastDay).inDays == 1) {
        newStreak = currentStreak + 1;
      } else {
        newStreak = 1;
      }

      tx.update(sessionRef, {'status': SessionStatus.finished.name});
      tx.update(coupleRef, {
        'totalPoints': newTotal,
        'level': AppConstants.levelForPoints(newTotal),
        'streak': newStreak,
        'lastPlayedAt': Timestamp.fromDate(now),
        'gamesPlayedTotal': FieldValue.increment(1),
      });
      // نقاط وعملات لكل طرف
      for (final uid in session.playerIds) {
        tx.update(
          _db.collection(AppConstants.usersCollection).doc(uid),
          {
            'points': FieldValue.increment(session.score),
            'coins': FieldValue.increment(AppConstants.coinsPerGame),
          },
        );
      }
      // سجل اللعبة
      tx.set(
        _historyRef(coupleId).doc(),
        GameHistoryEntry(
          gameTypeName: type.name,
          score: session.score,
          playedAt: DateTime.now(),
        ).toMap(),
      );
    });
  }

  /// آخر الألعاب الملعوبة
  Stream<List<GameHistoryEntry>> recentGames(String coupleId) => _historyRef(
          coupleId)
      .orderBy('playedAt', descending: true)
      .limit(10)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => GameHistoryEntry.fromMap(d.data())).toList());
}
