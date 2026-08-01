import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/settings_models.dart';
import '../../data/repositories/settings_repository.dart';

/// ViewModel الإعدادات — يشمل التحكم بالمظهر على مستوى التطبيق
class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _repo;
  SettingsViewModel(this._repo) {
    _loadTheme();
  }

  bool isBusy = false;
  String? errorMessage;

  ThemePref themePref = ThemePref.system;
  ThemeMode get themeMode => themePref.themeMode;

  Future<void> _loadTheme() async {
    themePref = await _repo.getThemePref();
    notifyListeners();
  }

  Future<void> setTheme(ThemePref pref) async {
    themePref = pref;
    notifyListeners();
    await _repo.setThemePref(pref);
  }

  Future<bool> _guarded(Future<void> Function() action) async {
    if (isBusy) return false;
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on SettingsException catch (e) {
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

  // ===== الحساب =====

  Future<bool> updateName({
    required String uid,
    required String name,
    String? coupleId,
  }) =>
      _guarded(() =>
          _repo.updateName(uid: uid, name: name, coupleId: coupleId));

  Future<bool> updatePhoto({required String uid, required XFile image}) =>
      _guarded(() => _repo.updatePhoto(uid: uid, image: image));

  Future<bool> deleteAccount(String password) =>
      _guarded(() => _repo.deleteAccount(password: password));

  // ===== العلاقة =====

  Future<bool> requestUnlink(
          {required String coupleId, required String uid}) =>
      _guarded(() => _repo.requestUnlink(coupleId: coupleId, uid: uid));

  Future<bool> cancelUnlink(String coupleId) =>
      _guarded(() => _repo.cancelUnlink(coupleId));

  Future<bool> confirmUnlink(
          {required String coupleId, required String uid}) =>
      _guarded(() => _repo.confirmUnlink(coupleId: coupleId, uid: uid));

  // ===== البيانات =====

  Future<bool> clearCache() => _guarded(_repo.clearImageCache);

  Future<bool> refreshData() => _guarded(_repo.refreshData);
}
