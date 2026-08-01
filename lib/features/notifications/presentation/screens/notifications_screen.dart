import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/models/notification_models.dart';
import '../viewmodels/notifications_viewmodel.dart';

/// مركز الإشعارات داخل التطبيق
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Stream<List<AppNotification>>? _notifsStream;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final vm = context.read<NotificationsViewModel>();
    _notifsStream ??= vm.notificationsStream(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات 🔔'),
        actions: [
          IconButton(
            tooltip: 'إعدادات الإشعارات',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push(AppRoutes.notificationSettings),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'read') {
                await vm.markAllAsRead(user.uid);
              } else if (v == 'clear') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: const Text('حذف الكل'),
                    content: const Text('تبي تحذف جميع الإشعارات؟'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('إلغاء')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('حذف',
                              style:
                                  TextStyle(color: AppColors.error))),
                    ],
                  ),
                );
                if (ok == true) await vm.deleteAll(user.uid);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'read', child: Text('تحديد الكل كمقروء ✅')),
              PopupMenuItem(value: 'clear', child: Text('حذف الكل 🗑️')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<AppNotification>>(
          stream: _notifsStream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final notifs = snap.data ?? const <AppNotification>[];
            if (notifs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔕', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('ما فيه إشعارات',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Text('كل جديد بينكما بيوصلك هنا',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ).animate().fadeIn(),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: notifs.length,
              itemBuilder: (context, i) {
                final n = notifs[i];
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    padding:
                        const EdgeInsetsDirectional.only(end: 20),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error),
                  ),
                  onDismissed: (_) => vm.delete(user.uid, n.id),
                  child: _NotificationTile(
                    notification: n,
                    onTap: () async {
                      if (!n.isRead) {
                        await vm.markAsRead(user.uid, n.id);
                      }
                      if (!context.mounted) return;
                      // Deep Linking
                      if (n.actionRoute != null &&
                          n.actionRoute!.isNotEmpty) {
                        context.push(n.actionRoute!);
                      }
                    },
                  )
                      .animate()
                      .fadeIn(delay: (40 * i.clamp(0, 10)).ms)
                      .slideY(begin: 0.06),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile(
      {required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final unread = !n.isRead;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: unread
          ? AppColors.primary.withOpacity(0.06)
          : Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: unread
            ? BorderSide(color: AppColors.primary.withOpacity(0.35))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: n.type.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(n.type.icon, color: n.type.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight: unread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(n.body,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(height: 1.5)),
                    const SizedBox(height: 5),
                    Text(TimeUtils.relative(n.createdAt),
                        style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
