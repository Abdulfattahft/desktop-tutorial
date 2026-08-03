import 'package:flutter/foundation.dart';

import '../../data/models/game_models.dart';
import '../../data/repositories/games_repository.dart';
import '../../data/services/game_completion_service.dart';

/// ViewModel الألعاب — أفعال المستخدم فقط
/// (عرض الجلسة يتم مباشرة عبر Stream في الشاشات للمزامنة اللحظية)
class GamesViewModel extends ChangeNotifier {
  final GamesRepository _repo;
  final GameCompletionService _completionService;

  GamesViewModel(
    this._repo, {
    GameCompletionService? completionService,
  }) : _completionService = completionService ?? GameCompletionService();

  bool isBusy = false;
  String? errorMessage;

  Stream<GameSession?> sessionStream(String coupleId, GameType type) =>
      _repo.sessionStream(coupleId, type);

  Stream<List<GameHistoryEntry>> recentGames(String coupleId) =>
      _repo.recentGames(coupleId);

  Future<bool> _guarded(Future<void> Function() action) async {
    if (isBusy) return false;
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on GameCompletionException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'حدث خطأ، تأكد من اتصالك وحاول مرة أخرى';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> startOrJoin({
    required String coupleId,
    required GameType type,
    required List<String> playerIds,
    String? starterUid,
    String? starterName,
  }) =>
      _guarded(() => _repo.startOrJoin(
            coupleId: coupleId,
            type: type,
            playerIds: playerIds,
            starterUid: starterUid,
            starterName: starterName,
          ));

  Future<bool> submitAnswer({
    required String coupleId,
    required GameType type,
    required int roundIndex,
    required String uid,
    required String answer,
  }) =>
      _guarded(() => _repo.submitAnswer(
            coupleId: coupleId,
            type: type,
            roundIndex: roundIndex,
            uid: uid,
            answer: answer,
          ));

  Future<int?> spinWheel({
    required String coupleId,
    required int roundIndex,
  }) async {
    if (isBusy) return null;
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await _repo.spinWheel(coupleId: coupleId, roundIndex: roundIndex);
    } catch (_) {
      errorMessage = 'حدث خطأ، حاول مرة أخرى';
      return null;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> advanceRound({
    required String coupleId,
    required GameType type,
    required int fromRound,
  }) =>
      _guarded(() => _repo.advanceOrFinish(
            coupleId: coupleId,
            type: type,
            fromRound: fromRound,
          ));

  Future<bool> finishGame({
    required String coupleId,
    required GameType type,
    required int fromRound,
  }) =>
      _guarded(() async {
        await _completionService.finishGame(
          coupleId: coupleId,
          type: type,
          fromRound: fromRound,
        );
      });
}
