import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/models/notification_models.dart';
import '../viewmodels/notifications_viewmodel.dart';

/// إعدادات الإشعارات — تفعيل/تعطيل كل فئة
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final vm = context.read<NotificationsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الإشعارات')),
      body: SafeArea(
        child: StreamBuilder<NotificationPrefs>(
          stream: vm.prefsStream(user.uid),
          builder: (context, snap) {
            final prefs =
                snap.data ?? const NotificationPrefs({});
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Text(
                  'اختر الإشعارات اللي تبي توصلك — الباقي بيوقف تمامًا',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.6),
                ).animate().fadeIn(),
                const SizedBox(height: 18),
                ...NotificationCategory.values.asMap().entries.map((e) {
                  final c = e.value;
                  final enabled = prefs.isEnabled(c);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: SwitchListTile(
                      value: enabled,
                      activeColor: AppColors.primary,
                      onChanged: (v) => vm.setPref(
                          uid: user.uid, category: c, enabled: v),
                      title: Text('${c.emoji}  ${c.label}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      subtitle: Text(
                        enabled ? 'مفعّلة' : 'موقوفة',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: enabled
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (60 * e.key).ms)
                      .slideY(begin: 0.08);
                }),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.secondary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'إشعارات النظام تشمل التنبيهات المهمة والتحديثات',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 12.5, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
