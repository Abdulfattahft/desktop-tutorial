import 'package:cloud_functions/cloud_functions.dart';

import '../models/game_models.dart';

class GameCompletionResult {
  const GameCompletionResult({
    required this.status,
    required this.score,
    required this.coinsPerPlayer,
    this.totalPoints,
    this.level,
    this.streak,
  });

  final String status;
  final int score;
  final int coinsPerPlayer;
  final int? totalPoints;
  final int? level;
  final int? streak;

  factory GameCompletionResult.fromMap(Map<String, dynamic> map) {
    return GameCompletionResult(
      status: map['status'] as String? ?? 'finished',
      score: (map['score'] as num?)?.toInt() ?? 0,
      coinsPerPlayer: (map['coinsPerPlayer'] as num?)?.toInt() ?? 0,
      totalPoints: (map['totalPoints'] as num?)?.toInt(),
      level: (map['level'] as num?)?.toInt(),
      streak: (map['streak'] as num?)?.toInt(),
    );
  }
}

class GameCompletionException implements Exception {
  const GameCompletionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GameCompletionService {
  GameCompletionService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<GameCompletionResult> finishGame({
    required String coupleId,
    required GameType type,
    required int fromRound,
  }) async {
    try {
      final callable = _functions.httpsCallable('finishGame');
      final response = await callable.call<Map<String, dynamic>>({
        'coupleId': coupleId,
        'gameType': type.name,
        'fromRound': fromRound,
      });

      return GameCompletionResult.fromMap(
        Map<String, dynamic>.from(response.data),
      );
    } on FirebaseFunctionsException catch (error) {
      throw GameCompletionException(_messageFor(error));
    } catch (_) {
      throw const GameCompletionException(
        'تعذر إنهاء اللعبة الآن. تحقق من الاتصال وحاول مرة أخرى.',
      );
    }
  }

  String _messageFor(FirebaseFunctionsException error) {
    final serverMessage = error.message?.trim();
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return serverMessage;
    }

    switch (error.code) {
      case 'unauthenticated':
        return 'انتهت جلسة تسجيل الدخول. سجّل دخولك مرة أخرى.';
      case 'permission-denied':
        return 'لا تملك صلاحية إنهاء هذه اللعبة.';
      case 'failed-precondition':
        return 'لا يمكن إنهاء اللعبة قبل اكتمال الجولة الأخيرة.';
      case 'not-found':
        return 'تعذر العثور على جلسة اللعبة.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'الاتصال بالخادم غير مستقر. حاول مرة أخرى.';
      default:
        return 'تعذر إنهاء اللعبة الآن. حاول مرة أخرى.';
    }
  }
}
