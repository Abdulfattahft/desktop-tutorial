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

/// الصفحة الرئيسية — مركز التطبيق
/// كل البيانات لحظية عبر ثلاث Streams: مستندي، مستند شريكي، مستند الزوجين
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // التيارات تُنشأ مرة واحدة — إنشاؤها داخل build يعيد الاشتراك
  // مع كل إعادة بناء ويستهلك قراءات Firestore بلا داعٍ
  Stream<CoupleModel?>? _coupleStream;
  Stream<UserModel?>? _meStream;
  Stream<UserModel?>? _partnerStream;
  Stream<GameHistoryEntry?>? _activityStream;
  Stream<int>? _unreadStream;

  @override
  void initState() {
    super.initState();
    // تحديث "آخر ظهور" لي عند فتح الرئيسية
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

    final ok =
        await context.read<HomeViewModel>().setWeddingDate(coupleId, picked);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم تحديد الموعد 🎉' : 'حدث خطأ، حاول مرة أخرى'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthViewModel>().currentUser;
    if (authUser == null || !authUser.isLinked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final vm = context.read<HomeViewModel>();

    // تهيئة كسولة مرة واحدة لكل تيار
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
          // جرس الإشعارات مع شارة غير المقروء
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
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints:
                              const BoxConstraints(minWidth: 17),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
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
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Text('تسجيل الخروج'),
                  content: const Text('متأكد إنك تبي تسجل خروجك؟'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('خروج',
                            style: TextStyle(color: AppColors.error))),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await context.read<AuthViewModel>().signOut();
                if (context.mounted) context.go(AppRoutes.login);
              }
            },
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
                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async =>
                          vm.touchLastActive(authUser.uid),
                      child: ListView(
                        padding:
                            const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          // 1) رأس الزوجين + المستوى
                          CoupleHeaderCard(
                                  couple: couple, myUid: authUser.uid)
                              .animate()
                              .fadeIn()
                              .slideY(begin: 0.1),

                          const SizedBox(height: 16),

                          // 2) العداد التنازلي
                          WeddingCountdownCard(
                            weddingDate: couple.weddingDate,
                            onPickDate: () =>
                                _pickWeddingDate(couple.id),
                          ).animate().fadeIn(delay: 100.ms),

                          const SizedBox(height: 16),

                          // 3) الإحصائيات
                          StatsRow(
                            points: couple.totalPoints,
                            coins: me?.coins ?? 0,
                            streak: couple.streak,
                          ).animate().fadeIn(delay: 200.ms),

                          const SizedBox(height: 16),

                          // 4) حالة الشريك (آخر ظهور)
                          if (partner != null)
                            _PartnerStatusCard(partner: partner)
                                .animate()
                                .fadeIn(delay: 300.ms),

                          const SizedBox(height: 16),

                          // 5) آخر نشاط مشترك
                          StreamBuilder<GameHistoryEntry?>(
                            stream: _activityStream,
                            builder: (context, actSnap) =>
                                _LastActivityCard(
                                        entry: actSnap.data)
                                    .animate()
                                    .fadeIn(delay: 400.ms),
                          ),

                          const SizedBox(height: 24),

                          // 6) شبكة الأقسام
                          Text('الأقسام',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: MediaQuery.sizeOf(context).width >= 1100 ? 5 : MediaQuery.sizeOf(context).width >= 700 ? 4 : 3,
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.95,
                            children: [
                              SectionButton(
                                title: 'الألعاب',
                                icon: Icons.videogame_asset_rounded,
                                color: AppColors.primary,
                                onTap: () =>
                                    context.push(AppRoutes.games),
                              ),
                              SectionButton(
                                title: 'التحديات',
                                icon: Icons
                                    .local_fire_department_rounded,
                                color: const Color(0xFFE08E45),
                                onTap: () => context
                                    .push(AppRoutes.challenges),
                              ),
                              SectionButton(
                                title: 'الذكريات',
                                icon: Icons.photo_library_rounded,
                                color: const Color(0xFF9C7BB8),
                                onTap: () => context
                                    .push(AppRoutes.memories),
                              ),
                              SectionButton(
                                title: 'الهدايا',
                                icon: Icons.card_giftcard_rounded,
                                color: AppColors.secondary,
                                onTap: () =>
                                    context.push(AppRoutes.gifts),
                              ),
                              SectionButton(
                                title: 'المساعد',
                                icon: Icons.auto_awesome_rounded,
                                color: const Color(0xFF7B68A6),
                                onTap: () =>
                                    context.push(AppRoutes.ai),
                              ),
                              SectionButton(
                                title: 'الإعدادات',
                                icon: Icons.settings_rounded,
                                color: const Color(0xFF5EA3A3),
                                onTap: () =>
                                    context.push(AppRoutes.settings),
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
        ),
      ),
    );
  }
}

/// بطاقة حالة الشريك — نقطة خضراء لو متصل الآن
class _PartnerStatusCard extends StatelessWidget {
  final UserModel partner;
  const _PartnerStatusCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    final online = TimeUtils.isOnline(partner.lastActive);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              backgroundImage: partner.photoUrl != null
                  ? NetworkImage(partner.photoUrl!)
                  : null,
              child: partner.photoUrl == null
                  ? Text(
                      partner.name.isNotEmpty ? partner.name[0] : '؟',
                      style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
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
        title: Text(partner.name,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          TimeUtils.relative(partner.lastActive),
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

/// بطاقة آخر نشاط مشترك
class _LastActivityCard extends StatelessWidget {
  final GameHistoryEntry? entry;
  const _LastActivityCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: const Text('✨', style: TextStyle(fontSize: 24)),
          title: Text('ما فيه نشاط بعد',
              style: Theme.of(context).textTheme.bodyLarge),
          subtitle: const Text('ابدآ أول لعبة واصنعا أول ذكرى!'),
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
        leading: CircleAvatar(
          backgroundColor:
              (meta?.color ?? AppColors.primary).withOpacity(0.15),
          child: Icon(meta?.icon ?? Icons.videogame_asset_rounded,
              color: meta?.color ?? AppColors.primary),
        ),
        title: Text('آخر نشاط: ${meta?.title ?? "لعبة"}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
            '${TimeUtils.relative(entry!.playedAt)} • +${entry!.score} نقطة'),
        trailing: const Icon(Icons.chevron_left_rounded,
            color: AppColors.textSecondary),
      ),
    );
  }
}
