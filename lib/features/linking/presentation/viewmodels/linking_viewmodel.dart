import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../auth/data/models/user_model.dart';
import '../../data/models/couple_model.dart';
import '../../data/repositories/linking_repository.dart';

enum LinkStatus { idle, loading, success, error }

/// ViewModel ربط الشريكين
class LinkingViewModel extends ChangeNotifier {
  final LinkingRepository _repo;
  LinkingViewModel(this._repo);

  LinkStatus status = LinkStatus.idle;
  String? errorMessage;
  CoupleModel? couple;

  StreamSubscription<UserModel?>? _userSub;

  /// يصبح true فقط إذا الشريك ربطنا من جهازه (وليس عند ربطنا نحن)
  bool linkedByPartner = false;

  bool get isLoading => status == LinkStatus.loading;

  /// الاستماع لمستندي في Firestore — لو الشريك أدخل رمزي من جهازه
  /// يتحدث partnerId تلقائيًا فننتقل بدون إعادة تشغيل
  ///
  /// مهم: نتجاهل الحدث أثناء loading/success لأن التغيير حينها
  /// قادم من معاملتنا نحن — هذا يمنع ظهور النجاح مرتين (Race condition)
  void watchMyAccount(String myUid) {
    _userSub?.cancel();
    _userSub = _repo.userStream(myUid).listen((user) {
      final canAccept =
          status == LinkStatus.idle || status == LinkStatus.error;
      if (user != null && user.isLinked && canAccept && !linkedByPartner) {
        linkedByPartner = true;
        status = LinkStatus.success;
        notifyListeners();
      }
    });
  }

  /// إيقاف الاستماع — تُستدعى عند مغادرة شاشة الربط
  void stopWatching() {
    _userSub?.cancel();
    _userSub = null;
  }

  Future<bool> linkWithCode({
    required String myUid,
    required String code,
  }) async {
    status = LinkStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      couple = await _repo.linkWithCode(myUid: myUid, code: code);
      status = LinkStatus.success;
      notifyListeners();
      return true;
    } on LinkException catch (e) {
      status = LinkStatus.error;
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      status = LinkStatus.error;
      errorMessage = 'حدث خطأ غير متوقع، حاول مرة أخرى';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}
