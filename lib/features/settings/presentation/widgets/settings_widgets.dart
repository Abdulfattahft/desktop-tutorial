import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';

/// عنوان قسم في الإعدادات
class SettingsSection extends StatelessWidget {
  final String title;
  final String emoji;
  final List<Widget> children;
  final int index;

  const SettingsSection({
    super.key,
    required this.title,
    required this.emoji,
    required this.children,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8, top: 18),
          child: Text('$emoji  $title',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 16)),
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    ).animate().fadeIn(delay: (60 * index).ms).slideY(begin: 0.06);
  }
}

/// عنصر إعداد قابل للضغط
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool danger;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        danger ? AppColors.error : (iconColor ?? AppColors.primary);
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
              color: danger ? AppColors.error : null)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: const TextStyle(fontSize: 12.5)),
      trailing: trailing ??
          (onTap == null
              ? null
              : const Icon(Icons.chevron_left_rounded,
                  color: AppColors.textSecondary, size: 22)),
    );
  }
}

/// مفتاح تبديل
class SettingsSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitch({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      secondary: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14.5)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: const TextStyle(fontSize: 12.5)),
    );
  }
}

/// حوار تأكيد موحد
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'تأكيد',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title),
      content: Text(message, style: const TextStyle(height: 1.6)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText,
              style: TextStyle(
                  color: danger ? AppColors.error : AppColors.primaryDark,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
  return result ?? false;
}
