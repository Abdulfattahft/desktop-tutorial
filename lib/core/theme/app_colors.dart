import 'package:flutter/material.dart';

/// ألوان تطبيق "بيننا" — هادئة ودافئة
/// أبيض، بيج، وردي فاتح، ذهبي
class AppColors {
  AppColors._();

  // ===== الوضع الفاتح =====
  static const Color background = Color(0xFFFFFDFA); // أبيض دافئ
  static const Color surface = Color(0xFFFAF3EC); // بيج فاتح
  static const Color card = Color(0xFFFFFFFF);

  static const Color primary = Color(0xFFE8A0A8); // وردي فاتح
  static const Color primaryDark = Color(0xFFD4838C);
  static const Color secondary = Color(0xFFC9A227); // ذهبي
  static const Color secondaryLight = Color(0xFFE7C873);

  static const Color textPrimary = Color(0xFF3E3230);
  static const Color textSecondary = Color(0xFF8A7A76);

  static const Color success = Color(0xFF7FB77E);
  static const Color error = Color(0xFFD9534F);

  // ===== الوضع الليلي =====
  static const Color darkBackground = Color(0xFF1E1A19);
  static const Color darkSurface = Color(0xFF2A2422);
  static const Color darkCard = Color(0xFF332C29);
  static const Color darkTextPrimary = Color(0xFFF5EFEA);
  static const Color darkTextSecondary = Color(0xFFB8A9A3);

  // تدرج رومانسي يُستخدم في الرأس والأزرار المميزة
  static const LinearGradient romanticGradient = LinearGradient(
    colors: [primary, secondaryLight],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );
}
