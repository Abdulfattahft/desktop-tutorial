import 'package:flutter/foundation.dart';

import '../../data/models/gift_models.dart';
import '../../data/repositories/gifts_repository.dart';

class GiftsViewModel extends ChangeNotifier {
  final GiftsRepository _repo;
  GiftsViewModel(this._repo);

  bool isBusy = false;
  String? errorMessage;

  Stream<List<GiftCatalogItem>> catalogStream() => _repo.catalogStream();
  Stream<List<SentGift>> giftsStream(String coupleId) =>
      _repo.giftsStream(coupleId);

  Future<bool> sendGift({
    required String coupleId,
    required String fromUid,
    required String toUid,
    required GiftCatalogItem gift,
    String? message,
  }) async {
    if (isBusy) return false;
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repo.sendGift(
        coupleId: coupleId,
        fromUid: fromUid,
        toUid: toUid,
        gift: gift,
        message: message,
      );
      return true;
    } on GiftException catch (e) {
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

  Future<void> openGift({
    required String coupleId,
    required String giftId,
    required String uid,
  }) =>
      _repo.openGift(coupleId: coupleId, giftId: giftId, uid: uid);

  Future<void> markSeen({
    required String coupleId,
    required String giftId,
    required String uid,
  }) =>
      _repo.markSeen(coupleId: coupleId, giftId: giftId, uid: uid);

  Future<void> reactToGift({
    required String coupleId,
    required String giftId,
    required String uid,
    required String reaction,
  }) =>
      _repo.reactToGift(
          coupleId: coupleId, giftId: giftId, uid: uid, reaction: reaction);
}
