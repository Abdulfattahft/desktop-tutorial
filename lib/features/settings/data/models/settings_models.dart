import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// تفضيل وضع المظهر
enum ThemePref { light, dark, system }

extension ThemePrefX on ThemePref {
  String get label => switch (this) {
        ThemePref.light => 'فاتح',
        ThemePref.dark => 'ليلي',
        ThemePref.system => 'تلقائي (حسب الجهاز)',
      };

  IconData get icon => switch (this) {
        ThemePref.light => Icons.light_mode_rounded,
        ThemePref.dark => Icons.dark_mode_rounded,
        ThemePref.system => Icons.brightness_auto_rounded,
      };

  ThemeMode get themeMode => switch (this) {
        ThemePref.light => ThemeMode.light,
        ThemePref.dark => ThemeMode.dark,
        ThemePref.system => ThemeMode.system,
      };

  static ThemePref fromName(String? name) {
    try {
      return ThemePref.values.byName(name ?? 'system');
    } catch (_) {
      return ThemePref.system;
    }
  }
}

/// حالة طلب فصل العلاقة
enum UnlinkStatus { none, pending, accepted, rejected }

/// طلب فصل العلاقة — يحتاج موافقة الطرف الآخر
class UnlinkRequest {
  final String requestedBy;
  final DateTime requestedAt;
  final UnlinkStatus status;

  const UnlinkRequest({
    required this.requestedBy,
    required this.requestedAt,
    this.status = UnlinkStatus.pending,
  });

  Map<String, dynamic> toMap() => {
        'requestedBy': requestedBy,
        'requestedAt': Timestamp.fromDate(requestedAt),
        'status': status.name,
      };

  factory UnlinkRequest.fromMap(Map<String, dynamic> map) {
    UnlinkStatus parse(String? v) {
      try {
        return UnlinkStatus.values.byName(v ?? 'none');
      } catch (_) {
        return UnlinkStatus.none;
      }
    }

    return UnlinkRequest(
      requestedBy: map['requestedBy'] as String? ?? '',
      requestedAt:
          (map['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: parse(map['status'] as String?),
    );
  }
}

/// استثناء الإعدادات برسالة عربية
class SettingsException implements Exception {
  final String message;
  const SettingsException(this.message);
}
