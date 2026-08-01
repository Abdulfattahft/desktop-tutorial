import 'package:flutter/foundation.dart';

import '../../data/models/challenge_models.dart';
import '../../data/repositories/challenges_repository.dart';

/// ViewModel التحديات
class ChallengesViewModel extends ChangeNotifier {
  final ChallengesRepository _repo;
  ChallengesViewModel(this._repo);

  bool isBusy = false;
  String? errorMessage;

  Stream<List<ChallengeModel>> challengesStream(String coupleId) =>
      _repo.challengesStream(coupleId);

  Future<void> ensureChallenges(String coupleId) async {
    try {
      await _repo.ensureChallenges(coupleId);
    } catch (_) {
      // فشل التوليد غير حرج — سيُعاد عند فتح الشاشة مجددًا
    }
  }

  Future<bool> markDone({
    required String coupleId,
    required String challengeId,
    required String uid,
  }) async {
    if (isBusy) return false;
    isBusy = true;
    notifyListeners();
    try {
      await _repo.markDone(
          coupleId: coupleId, challengeId: challengeId, uid: uid);
      return true;
    } catch (_) {
      errorMessage = 'حدث خطأ، حاول مرة أخرى';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> claimReward({
    required String coupleId,
    required String challengeId,
    required String uid,
    required List<String> playerIds,
  }) async {
    if (isBusy) return false;
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.claimReward(
        coupleId: coupleId,
        challengeId: challengeId,
        uid: uid,
        playerIds: playerIds,
      );
      return true;
    } on ChallengeException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (_) {
      errorMessage = 'حدث خطأ، حاول مرة أخرى';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}
