import 'package:shared_preferences/shared_preferences.dart';

/// خدمة التخزين المحلي — تغلّف shared_preferences
/// نستخدمها لأي إعدادات بسيطة تُحفظ على الجهاز
class LocalStorageService {
  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  static const String _keySeenOnboarding = 'seen_onboarding';
  static const String _keyThemeMode = 'theme_mode'; // سنستخدمه في الإعدادات

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// هل شاهد المستخدم صفحات التعريف من قبل؟
  Future<bool> hasSeenOnboarding() async {
    final prefs = await _instance;
    return prefs.getBool(_keySeenOnboarding) ?? false;
  }

  /// حفظ أن المستخدم شاهد صفحات التعريف
  Future<void> setSeenOnboarding() async {
    final prefs = await _instance;
    await prefs.setBool(_keySeenOnboarding, true);
  }

  /// وضع الثيم المحفوظ (light / dark / system)
  Future<String> getThemeMode() async {
    final prefs = await _instance;
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await _instance;
    await prefs.setString(_keyThemeMode, mode);
  }
}
