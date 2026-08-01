import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ai/presentation/viewmodels/ai_viewmodel.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../home/presentation/viewmodels/home_viewmodel.dart';
import '../../../notifications/data/models/notification_models.dart';
import '../../../notifications/presentation/viewmodels/notifications_viewmodel.dart';
import '../../data/models/settings_models.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../widgets/settings_widgets.dart';

/// شاشة الإعدادات الرئيسية
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Stream<UserModel?>? _meStream;
  Stream<NotificationPrefs>? _prefsStream;

  Future<void> _signOut() async {
    final ok = await confirmDialog(
      context,
      title: 'تسجيل الخروج',
      message: 'متأكد إنك تبي تسجل خروجك؟ بتحتاج تسجل دخولك مرة ثانية.',
      confirmText: 'خروج',
      danger: true,
    );
    if (!ok || !mounted) return;
    await context.read<AuthViewModel>().signOut();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthViewModel>().currentUser;
    if (authUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final settingsVm = context.watch<SettingsViewModel>();
    final aiVm = context.watch<AIViewModel>();
    final notifVm = context.read<NotificationsViewModel>();
    final homeVm = context.read<HomeViewModel>();

    _meStream ??= homeVm.userStream(authUser.uid);
    _prefsStream ??= notifVm.prefsStream(authUser.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات ⚙️')),
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: _meStream,
          builder: (context, meSnap) {
            final me = meSnap.data ?? authUser;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                // ===== بطاقة الحساب =====
                Card(
                  margin: const EdgeInsets.only(top: 12),
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.editProfile),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                AppColors.primary.withOpacity(0.15),
                            backgroundImage: me.photoUrl != null
                                ? NetworkImage(me.photoUrl!)
                                : null,
                            child: me.photoUrl == null
                                ? Text(
                                    me.name.isNotEmpty ? me.name[0] : '؟',
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryDark),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(me.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge),
                                const SizedBox(height: 2),
                                Text(me.email,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('🪙 ${me.coins}',
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(width: 12),
                                    Text('⭐ ${me.points}',
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_left_rounded,
                              color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),

                // ===== العلاقة =====
                SettingsSection(
                  title: 'العلاقة',
                  emoji: '💕',
                  index: 1,
                  children: [
                    SettingsTile(
                      icon: Icons.favorite_rounded,
                      title: me.isLinked ? 'إدارة العلاقة' : 'ربط شريك',
                      subtitle: me.isLinked
                          ? 'بيانات شريكك وخيارات الفصل'
                          : 'اربط حسابك بشريكك للبدء',
                      onTap: () => context.push(me.isLinked
                          ? AppRoutes.relationship
                          : AppRoutes.linkPartner),
                    ),
                  ],
                ),

                // ===== الإشعارات =====
                StreamBuilder<NotificationPrefs>(
                  stream: _prefsStream,
                  builder: (context, prefsSnap) {
                    final prefs =
                        prefsSnap.data ?? const NotificationPrefs({});
                    return SettingsSection(
                      title: 'الإشعارات',
                      emoji: '🔔',
                      index: 2,
                      children: NotificationCategory.values
                          .map((c) => SettingsSwitch(
                                icon: _categoryIcon(c),
                                title: c.label,
                                value: prefs.isEnabled(c),
                                onChanged: (v) => notifVm.setPref(
                                    uid: me.uid,
                                    category: c,
                                    enabled: v),
                              ))
                          .toList(),
                    );
                  },
                ),

                // ===== الذكاء الاصطناعي =====
                SettingsSection(
                  title: 'المساعد الذكي',
                  emoji: '🤖',
                  index: 3,
                  children: [
                    SettingsSwitch(
                      icon: Icons.auto_awesome_rounded,
                      title: 'تفعيل المساعد',
                      subtitle: aiVm.aiEnabled
                          ? 'الاقتراحات والرسائل شغّالة'
                          : 'كل ميزات المساعد موقوفة',
                      value: aiVm.aiEnabled,
                      onChanged: aiVm.setEnabled,
                    ),
                    SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'ماذا نرسل للمساعد؟',
                      subtitle: 'أرقام عامة فقط — بلا أسماء أو صور',
                      onTap: () => _showAIPrivacy(context),
                    ),
                    SettingsTile(
                      icon: Icons.delete_sweep_rounded,
                      title: 'مسح سجل المساعد',
                      subtitle: '${aiVm.history.length} عنصر محفوظ محليًا',
                      onTap: () async {
                        final ok = await confirmDialog(
                          context,
                          title: 'مسح السجل',
                          message:
                              'بيُحذف سجل اقتراحات المساعد من جهازك.',
                          confirmText: 'مسح',
                          danger: true,
                        );
                        if (ok) await aiVm.clearHistory();
                      },
                    ),
                  ],
                ),

                // ===== المظهر واللغة =====
                SettingsSection(
                  title: 'المظهر واللغة',
                  emoji: '🎨',
                  index: 4,
                  children: [
                    ...ThemePref.values.map(
                      (p) => RadioListTile<ThemePref>(
                        value: p,
                        groupValue: settingsVm.themePref,
                        activeColor: AppColors.primary,
                        onChanged: (v) {
                          if (v != null) settingsVm.setTheme(v);
                        },
                        secondary: Icon(p.icon,
                            color: AppColors.primary, size: 20),
                        title: Text(p.label,
                            style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const Divider(height: 1),
                    const SettingsTile(
                      icon: Icons.language_rounded,
                      title: 'اللغة',
                      subtitle: 'العربية — دعم لغات إضافية قادم',
                      trailing: Text('🇸🇦',
                          style: TextStyle(fontSize: 20)),
                    ),
                  ],
                ),

                // ===== البيانات =====
                SettingsSection(
                  title: 'البيانات',
                  emoji: '💾',
                  index: 5,
                  children: [
                    SettingsTile(
                      icon: Icons.cleaning_services_rounded,
                      title: 'مسح ذاكرة الصور المؤقتة',
                      subtitle: 'يفرّغ مساحة — الصور تُحمّل مجددًا',
                      onTap: () async {
                        final ok = await settingsVm.clearCache();
                        if (!context.mounted) return;
                        _toast(context,
                            ok ? 'تم مسح الذاكرة المؤقتة ✅' : 'تعذر المسح',
                            success: ok);
                      },
                    ),
                    SettingsTile(
                      icon: Icons.refresh_rounded,
                      title: 'إعادة تحميل البيانات',
                      subtitle: 'يجلب أحدث نسخة من الخادم',
                      onTap: () async {
                        final ok = await settingsVm.refreshData();
                        if (!context.mounted) return;
                        _toast(
                            context,
                            ok
                                ? 'تم التحديث — أعد فتح الشاشات ✅'
                                : 'تعذر التحديث',
                            success: ok);
                      },
                    ),
                    SettingsTile(
                      icon: Icons.cloud_done_rounded,
                      title: 'حالة الاتصال',
                      subtitle: 'المزامنة تعمل تلقائيًا عند توفر الإنترنت',
                      iconColor: AppColors.success,
                      trailing: const Icon(Icons.circle,
                          color: AppColors.success, size: 12),
                    ),
                  ],
                ),

                // ===== الخصوصية والأمان =====
                SettingsSection(
                  title: 'الخصوصية والأمان',
                  emoji: '🔒',
                  index: 6,
                  children: [
                    SettingsTile(
                      icon: Icons.privacy_tip_rounded,
                      title: 'سياسة الخصوصية',
                      onTap: () => context.push(AppRoutes.privacyPolicy),
                    ),
                    SettingsTile(
                      icon: Icons.description_rounded,
                      title: 'الشروط والأحكام',
                      onTap: () => context.push(AppRoutes.terms),
                    ),
                    SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'عن التطبيق',
                      subtitle: 'بيننا — الإصدار 1.0.0',
                      onTap: () => _showAbout(context),
                    ),
                  ],
                ),

                // ===== الحساب =====
                SettingsSection(
                  title: 'الحساب',
                  emoji: '👤',
                  index: 7,
                  children: [
                    SettingsTile(
                      icon: Icons.logout_rounded,
                      title: 'تسجيل الخروج',
                      onTap: _signOut,
                    ),
                    SettingsTile(
                      icon: Icons.delete_forever_rounded,
                      title: 'حذف الحساب نهائيًا',
                      subtitle: 'لا يمكن التراجع عن هذا الإجراء',
                      danger: true,
                      onTap: () => context.push(AppRoutes.deleteAccount),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Center(
                  child: Text('صُنع بحب 💕',
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _categoryIcon(NotificationCategory c) => switch (c) {
        NotificationCategory.gifts => Icons.card_giftcard_rounded,
        NotificationCategory.games => Icons.videogame_asset_rounded,
        NotificationCategory.memories => Icons.photo_library_rounded,
        NotificationCategory.comments => Icons.chat_bubble_rounded,
        NotificationCategory.likes => Icons.favorite_rounded,
        NotificationCategory.challenges =>
          Icons.local_fire_department_rounded,
        NotificationCategory.occasions => Icons.celebration_rounded,
        NotificationCategory.system => Icons.notifications_rounded,
      };

  void _showAIPrivacy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('خصوصية المساعد 🔒',
                style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 14),
            const Text('✅ نرسل:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success)),
            const SizedBox(height: 6),
            Text(
              '• أرقام عامة: عدد الألعاب، الستريك، المستوى، عدد العملات\n'
              '• الخيار الذي تحدده أنت (نوع الرسالة، النبرة، مستوى الأسئلة)\n'
              '• الساعة الحالية (لاقتراح نشاط مناسب)',
              style: Theme.of(ctx)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.8),
            ),
            const SizedBox(height: 16),
            const Text('🚫 لا نرسل أبدًا:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error)),
            const SizedBox(height: 6),
            Text(
              '• اسمك أو بريدك أو اسم شريكك\n'
              '• صورك أو ذكرياتك أو تعليقاتك\n'
              '• رسائلك أو إجابات الألعاب\n'
              '• أي معرّف يخص حسابك',
              style: Theme.of(ctx)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.8),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('فهمت'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'بيننا',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          gradient: AppColors.romanticGradient,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.favorite_rounded,
            color: Colors.white, size: 28),
      ),
      children: [
        const SizedBox(height: 12),
        const Text(
          'تطبيق يقرّب المخطوبين والأزواج الذين تفصلهم المسافات، '
          'عبر الألعاب والتحديات والذكريات المشتركة.',
          style: TextStyle(height: 1.7),
        ),
      ],
    );
  }

  void _toast(BuildContext context, String msg, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
