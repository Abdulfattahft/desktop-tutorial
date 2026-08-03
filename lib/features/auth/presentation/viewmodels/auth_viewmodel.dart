import 'package:flutter/foundation.dart';

import '../../../../core/services/push_notification_service.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// حالة عمليات المصادقة
enum AuthStatus { idle, loading, success, error }

/// ViewModel المصادقة — الوسيط بين الشاشات والمستودع
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  AuthViewModel(this._repo);

  AuthStatus status = AuthStatus.idle;
  String? errorMessage;
  UserModel? currentUser;

  bool get isLoading => status == AuthStatus.loading;
  bool get isLoggedIn => _repo.currentUser != null;

  void _setStatus(AuthStatus s, [String? error]) {
    status = s;
    errorMessage = error;
    notifyListeners();
  }

  /// تحميل بيانات المستخدم الحالي وتحديث الواجهات التي تعرض النقاط والعملات.
  Future<bool> loadCurrentUser() async {
    final user = _repo.currentUser;
    if (user == null) return false;
    try {
      currentUser = await _repo.getUserData(user.uid);
      notifyListeners();
      await _repo.updateLastActive(user.uid);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setStatus(AuthStatus.loading);
    try {
      currentUser =
          await _repo.register(name: name, email: email, password: password);
      _setStatus(AuthStatus.success);
      return true;
    } on AuthException catch (e) {
      _setStatus(AuthStatus.error, e.message);
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setStatus(AuthStatus.loading);
    try {
      currentUser = await _repo.login(email: email, password: password);
      _setStatus(AuthStatus.success);
      return true;
    } on AuthException catch (e) {
      _setStatus(AuthStatus.error, e.message);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _setStatus(AuthStatus.loading);
    try {
      await _repo.resetPassword(email);
      _setStatus(AuthStatus.success);
      return true;
    } on AuthException catch (e) {
      _setStatus(AuthStatus.error, e.message);
      return false;
    }
  }

  Future<void> signOut() async {
    // إلغاء رمز الجهاز حتى لا تصل إشعارات لمستخدم سجّل خروجه
    try {
      await PushNotificationService.instance.deleteToken();
    } catch (_) {}
    await _repo.signOut();
    currentUser = null;
    _setStatus(AuthStatus.idle);
  }
}
