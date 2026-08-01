import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../games/data/content/games_content.dart';
import '../../../games/data/models/game_models.dart';
import '../../../linking/data/models/couple_model.dart';
import '../../../notifications/presentation/viewmodels/notifications_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/home_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Stream<CoupleModel?>? _coupleStream;
  Stream<UserModel?>? _meStream;
  Stream<UserModel?>? _partnerStream;
  Stream<GameHistoryEntry?>? _activityStream;
  Stream<int>? _unreadStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthViewModel>().currentUser?.uid;
      if (uid != null) context.read<HomeViewModel>().touchLastActive(uid);
    });
  }

  Future<void> _pickWeddingDate(String coupleId) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 90)),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
      helpText: 'اختارا موعد زواجكما 💍',
      confirmText: 'تأكيد',
      cancelText: 'إلغاء',
    );
    if (picked == null || !mounted) return;

    final ok = await context.read<HomeViewModel>().setWeddingDate(coupleId, picked);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم تحديد الموعد 🎉' : 'حدث خطأ، حاول مرة أخرى'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تسجيل الخروج'),
        content: const Text('متأكد إنك تبي تسجل خروجك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthViewModel>().signOut();
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthViewModel>().currentUser;
    if (authUser == null || !authUser.isLinked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final vm = context.read<HomeViewModel>();
    _coupleStream ??= vm.coupleStream(authUser.coupleId!);
    _meStream ??= vm.userStream(authUser.uid);
    _partnerStream ??= vm.userStream(authUser.partnerId!);
    _activityStream ??= vm.lastActivityStream(authUser.coupleId!);
    _unreadStream ??= context
        .read<NotificationsViewModel>()
        .unreadCountStream(authUser.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('بيننا 💕'),
        actions: [
          StreamBuilder<int>(
            stream: _unreadStream,
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return IconButton(
                tooltip: 'الإشعارات',
                onPressed: () => context.push(AppRoutes.notifications),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_rounded),
                    if (count > 0)
                      PositionedDirectional(
                        top: -4,
                        end: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          constraints: const BoxConstraints(minWidth: 17),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<CoupleModel?>(
          stream: _coupleStream,
          builder: (context, coupleSnap) {
            final couple = coupleSnap.data;
            if (couple == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return StreamBuilder<UserModel?>(
              stream: _meStream,
              builder: (context, meSnap) {
                final me = meSnap.data;
                return StreamBuilder<UserModel?>(
                  stream: _partnerStream,
                  builder: (context, partnerSnap) {
                    final partner = partnerSnap.data;
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final sidePadding = width < 380 ? 12.0 : width < 700 ? 16.0 : 24.0;
                        final gridColumns = width < 460
                            ? 2
                            : width < 760
                                ? 3
                                : width < 1100
                                    ? 4
                                    : 5;
                        final gridRatio = width < 380 ? 1.05 : 1.0;

                        return RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async => vm.touchLastActive(authUser.uid),
                          child: ListView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.fromLTRB(
                              sidePadding,
                              8,
                              sidePadding,
                              28,
                            ),
                            children: [
                              CoupleHeaderCard(
                                couple: couple,
                                myUid: authUser.uid,
                              ).animate().fadeIn().slideY(begin: 0.1),
                              const SizedBox(height: 16),
                              WeddingCountdownCard(
                                weddingDate: couple.weddingDate,
                                onPickDate: () => _pickWeddingDate(couple.id),
                              ).animate().fadeIn(delay: 100.ms),
                              const SizedBox(height: 16),
                              StatsRow(
                                points: couple.totalPoints,
                                coins: me?.coins ?? 0,
                                streak: couple.streak,
                              ).animate().fadeIn(delay: 200.ms),
                              if (partner != null) ...[
                                const SizedBox(height: 16),
                                _PartnerStatusCard(partner: partner)
                                    .animate()
                                    .fadeIn(delay: 300.ms),
                              ],
                              const SizedBox(height: 16),
                              StreamBuilder<GameHistoryEntry?>(
                                stream: _activityStream,
                                builder: (context, actSnap) => _LastActivityCard(
                                  entry: actSnap.data,
                                ).animate().fadeIn(delay: 400.ms),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'الأقسام',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              GridView.count(
                                crossAxisCount: gridColumns,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: gridRatio,
                                children: [
                                  SectionButton(
                                    title: 'الألعاب',
                                    icon: Icons.videogame_asset_rounded,
                                    color: AppColors.primary,
                                    onTap: () => context.push(AppRoutes.games),
                                  ),
                                  SectionButton(
                                    title: 'التحديات',
                                    icon: Icons.local_fire_department_rounded,
                                    color: const Color(0xFFE08E45),
                                    onTap: () => context.push(AppRoutes.challenges),
                                  ),
                                  SectionButton(
                                    title: 'الذكريات',
                                    icon: Icons.photo_library_rounded,
                                    color: const Color(0xFF9C7BB8),
                                    onTap: () => context.push(AppRoutes.memories),
                                  ),
                                  SectionButton(
                                    title: 'الهدايا',
                                    icon: Icons.card_giftcard_rounded,
                                    color: AppColors.secondary,
                                    onTap: () => context.push(AppRoutes.gifts),
                                  ),
                                  SectionButton(
                                    title: 'المساعد',
                                    icon: Icons.auto_awesome_rounded,
                                    color: const Color(0xFF7B68A6),
                                    onTap: () => context.push(AppRoutes.ai),
                                  ),
                                  SectionButton(
                                    title: 'الإعدادات',
                                    icon: Icons.settings_rounded,
                                    color: const Color(0xFF5EA3A3),
                                    onTap: () => context.push(AppRoutes.settings),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PartnerStatusCard extends StatelessWidget {
  final UserModel partner;

  const _PartnerStatusCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    final online = TimeUtils.isOnline(partner.lastActive);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              backgroundImage:
                  partner.photoUrl != null ? NetworkImage(partner.photoUrl!) : null,
              child: partner.photoUrl == null
                  ? Text(
                      partner.name.isNotEmpty ? partner.name[0] : '؟',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            if (online)
              PositionedDirectional(
                bottom: 0,
                end: 0,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          partner.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          TimeUtils.relative(partner.lastActive),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: online ? AppColors.success : AppColors.textSecondary,
            fontWeight: online ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: const Text('💗', style: TextStyle(fontSize: 22)),
      ),
    );
  }
}

class _LastActivityCard extends StatelessWidget {
  final GameHistoryEntry? entry;

  const _LastActivityCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: const Text('✨', style: TextStyle(fontSize: 24)),
          title: Text(
            'ما فيه نشاط بعد',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: const Text(
            'ابدآ أول لعبة واصنعا أول ذكرى!',
            maxLines: 2,
          ),
        ),
      );
    }

    GameMeta? meta;
    try {
      meta = GamesContent.metaOf(GameType.values.byName(entry!.gameTypeName));
    } catch (_) {}

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: (meta?.color ?? AppColors.primary).withOpacity(0.15),
          child: Icon(
            meta?.icon ?? Icons.videogame_asset_rounded,
            color: meta?.color ?? AppColors.primary,
          ),
        ),
        title: Text(
          'آخر نشاط: ${meta?.title ?? "لعبة"}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${TimeUtils.relative(entry!.playedAt)} • +${entry!.score} نقطة',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(
          Icons.chevron_left_rounded,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
