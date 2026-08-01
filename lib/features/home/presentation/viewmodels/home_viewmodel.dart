import 'package:flutter/foundation.dart';

import '../../../auth/data/models/user_model.dart';
import '../../../games/data/models/game_models.dart';
import '../../../linking/data/models/couple_model.dart';
import '../../data/repositories/home_repository.dart';

/// ViewModel الرئيسية
class HomeViewModel extends ChangeNotifier {
  final HomeRepository _repo;
  HomeViewModel(this._repo);

  bool isBusy = false;

  Stream<UserModel?> userStream(String uid) => _repo.userStream(uid);
  Stream<CoupleModel?> coupleStream(String coupleId) =>
      _repo.coupleStream(coupleId);
  Stream<GameHistoryEntry?> lastActivityStream(String coupleId) =>
      _repo.lastActivityStream(coupleId);

  Future<void> touchLastActive(String uid) => _repo.touchLastActive(uid);

  Future<bool> setWeddingDate(String coupleId, DateTime date) async {
    if (isBusy) return false;
    isBusy = true;
    notifyListeners();
    try {
      await _repo.setWeddingDate(coupleId, date);
      return true;
    } catch (_) {
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}
