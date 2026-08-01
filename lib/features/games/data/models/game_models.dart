import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// أنواع الألعاب — أضف نوعًا جديدًا هنا + محتواه في games_content.dart
/// وسيظهر تلقائيًا في شاشة الألعاب
enum GameType {
  knowMe,       // لعبة الأسئلة (اعرفني)
  whoKnows,     // مين يعرف الثاني أكثر؟
  wouldYouRather, // لو خيروك
  truth,        // الصراحة
  dares,        // التحديات
  guess,        // التخمين
  wheel,        // العجلة العشوائية
}

/// أوضاع الإجابة التي يدعمها المحرك
enum AnswerMode { freeText, choices }

/// بيانات وصفية لكل لعبة (العنوان، الأيقونة، الوصف، اللون، وضع الإجابة)
class GameMeta {
  final GameType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final AnswerMode mode;
  final int rounds;
  final bool scoreOnMatch; // هل تطابق الإجابتين يمنح نقاطًا إضافية؟

  const GameMeta({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.mode,
    this.rounds = 5,
    this.scoreOnMatch = false,
  });
}

/// جولة واحدة داخل الجلسة
class GameRound {
  final String prompt;
  final List<String> options; // فارغة في وضع النص الحر
  final Map<String, String> answers; // uid → الإجابة
  final bool? isMatch; // يُحسب عند اكتمال الإجابتين
  final int? wheelIndex; // للعجلة فقط

  const GameRound({
    required this.prompt,
    this.options = const [],
    this.answers = const {},
    this.isMatch,
    this.wheelIndex,
  });

  bool answeredBy(String uid) => answers.containsKey(uid);
  bool get bothAnswered => answers.length >= 2;

  Map<String, dynamic> toMap() => {
        'prompt': prompt,
        'options': options,
        'answers': answers,
        'isMatch': isMatch,
        'wheelIndex': wheelIndex,
      };

  factory GameRound.fromMap(Map<String, dynamic> map) => GameRound(
        prompt: map['prompt'] as String? ?? '',
        options: List<String>.from(map['options'] as List? ?? const []),
        answers: Map<String, String>.from(map['answers'] as Map? ?? const {}),
        isMatch: map['isMatch'] as bool?,
        wheelIndex: (map['wheelIndex'] as num?)?.toInt(),
      );

  GameRound copyWith({
    String? prompt,
    Map<String, String>? answers,
    bool? isMatch,
    int? wheelIndex,
  }) =>
      GameRound(
        prompt: prompt ?? this.prompt,
        options: options,
        answers: answers ?? this.answers,
        isMatch: isMatch ?? this.isMatch,
        wheelIndex: wheelIndex ?? this.wheelIndex,
      );
}

/// حالة الجلسة
enum SessionStatus { playing, finished }

/// جلسة لعب مشتركة — مستند واحد يراه الطرفان لحظيًا
class GameSession {
  final String id; // = gameType.name (معرّف ثابت يمنع الازدواج)
  final GameType gameType;
  final SessionStatus status;
  final int currentRound;
  final List<GameRound> rounds;
  final int score; // نقاط هذه الجلسة
  final List<String> playerIds;
  final DateTime createdAt;

  const GameSession({
    required this.id,
    required this.gameType,
    required this.status,
    required this.currentRound,
    required this.rounds,
    required this.score,
    required this.playerIds,
    required this.createdAt,
  });

  GameRound get round => rounds[currentRound];
  bool get isLastRound => currentRound >= rounds.length - 1;

  Map<String, dynamic> toMap() => {
        'id': id,
        'gameType': gameType.name,
        'status': status.name,
        'currentRound': currentRound,
        'rounds': rounds.map((r) => r.toMap()).toList(),
        'score': score,
        'playerIds': playerIds,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory GameSession.fromMap(Map<String, dynamic> map) => GameSession(
        id: map['id'] as String,
        gameType: GameType.values.byName(map['gameType'] as String),
        status: SessionStatus.values.byName(map['status'] as String),
        currentRound: (map['currentRound'] as num?)?.toInt() ?? 0,
        rounds: (map['rounds'] as List? ?? const [])
            .map((r) => GameRound.fromMap(Map<String, dynamic>.from(r)))
            .toList(),
        score: (map['score'] as num?)?.toInt() ?? 0,
        playerIds: List<String>.from(map['playerIds'] as List? ?? const []),
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

/// سجل لعبة منتهية (لآخر الألعاب في شاشة الألعاب)
class GameHistoryEntry {
  final String gameTypeName;
  final int score;
  final DateTime playedAt;

  const GameHistoryEntry({
    required this.gameTypeName,
    required this.score,
    required this.playedAt,
  });

  Map<String, dynamic> toMap() => {
        'gameTypeName': gameTypeName,
        'score': score,
        'playedAt': Timestamp.fromDate(playedAt),
      };

  factory GameHistoryEntry.fromMap(Map<String, dynamic> map) =>
      GameHistoryEntry(
        gameTypeName: map['gameTypeName'] as String? ?? '',
        score: (map['score'] as num?)?.toInt() ?? 0,
        playedAt:
            (map['playedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
