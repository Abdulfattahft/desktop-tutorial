import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../home/presentation/viewmodels/home_viewmodel.dart';
import '../../../linking/data/models/couple_model.dart';
import '../../data/models/gift_models.dart';
import '../viewmodels/gifts_viewmodel.dart';
import '../widgets/gift_widgets.dart';

/// شاشة الهدايا — 3 تبويبات: المتجر / الوارد / السجل
class GiftsScreen extends StatefulWidget {
  const GiftsScreen({super.key});

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  // تُنشأ مرة واحدة لتفادي إعادة الاشتراك مع كل rebuild
  Stream<List<GiftCatalogItem>>? _catalogStream;
  Stream<List<SentGift>>? _giftsStream;
  Stream<UserModel?>? _meStream;
  Stream<CoupleModel?>? _coupleStream;

  GiftCategory? _shopFilter;
  GiftCategory? _historyFilter;
  String _historyDirection = 'all'; // all | sent | received

  @override
  void dispose() {
    _tabs.dispose();
    _confetti.dispose();
    super.dispose();
  }

  // ===== إرسال هدية =====
  Future<void> _confirmSend(GiftCatalogItem gift, UserModel me) async {
    final msgCtrl = TextEditingController();
    final send = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(gift.emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            Text(gift.name, style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(gift.description,
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text('🪙 ${gift.price}',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary)),
            const SizedBox(height: 16),
            TextField(
              controller: msgCtrl,
              maxLength: 150,
              decoration: const InputDecoration(
                  hintText: 'أضف رسالة شخصية (اختياري) 💌',
                  counterText: ''),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إرسال الهدية 🎁'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
    if (send != true || !mounted) return;

    final vm = context.read<GiftsViewModel>();
    final ok = await vm.sendGift(
      coupleId: me.coupleId!,
      fromUid: me.uid,
      toUid: me.partnerId!,
      gift: gift,
      message: msgCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      _confetti.play();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('انطلقت هديتك ${gift.emoji} 💕'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'حدث خطأ'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// تعليم الهدايا غير المفتوحة كـ"شوهدت" (مرة واحدة لكل هدية)
  final Set<String> _seenMarked = {};
  void _markSeen(UserModel me, List<SentGift> gifts) {
    for (final g in gifts) {
      if (g.toUid == me.uid &&
          !g.opened &&
          g.seenAt == null &&
          !_seenMarked.contains(g.id)) {
        _seenMarked.add(g.id);
        context.read<GiftsViewModel>().markSeen(
            coupleId: me.coupleId!, giftId: g.id, uid: me.uid);
      }
    }
  }

  // ===== فتح هدية بأنيميشن =====
  Future<void> _openGift(SentGift gift, UserModel me) async {
    // سجل الفتح في Firestore
    context.read<GiftsViewModel>().openGift(
        coupleId: me.coupleId!, giftId: gift.id, uid: me.uid);
    _confetti.play();

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الصندوق يهتز ثم تظهر الهدية
              Text(gift.emoji, style: const TextStyle(fontSize: 72))
                  .animate()
                  .scale(
                      begin: const Offset(0.2, 0.2),
                      curve: Curves.elasticOut,
                      duration: 900.ms)
                  .then()
                  .shake(hz: 3, rotation: 0.04, duration: 500.ms),
              const SizedBox(height: 14),
              Text(gift.name,
                  style: Theme.of(ctx).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text('من قلب شريكك إليك 💕',
                  style: Theme.of(ctx).textTheme.bodyMedium),
              if (gift.message != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '"${gift.message}"',
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.6),
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],
              const SizedBox(height: 18),
              // ردود الفعل السريعة
              Wrap(
                spacing: 8,
                children: ['😍', '🥹', '🤩', '😘', '🥰'].map((e) {
                  return InkWell(
                    onTap: () {
                      context.read<GiftsViewModel>().reactToGift(
                            coupleId: me.coupleId!,
                            giftId: gift.id,
                            uid: me.uid,
                            reaction: e,
                          );
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child:
                          Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(delay: 800.ms),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('يا سلام 🥹'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null || !user.isLinked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final vm = context.read<GiftsViewModel>();
    final homeVm = context.read<HomeViewModel>();

    _catalogStream ??= vm.catalogStream();
    _giftsStream ??= vm.giftsStream(user.coupleId!);
    _meStream ??= homeVm.userStream(user.uid);
    _coupleStream ??= homeVm.coupleStream(user.coupleId!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الهدايا 🎁'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
          tabs: const [
            Tab(text: 'المتجر 🛍️'),
            Tab(text: 'الوارد 📥'),
            Tab(text: 'السجل 📊'),
          ],
        ),
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // عملاتي لحظيًا من تيار مستندي
          StreamBuilder<UserModel?>(
            stream: _meStream,
            builder: (context, meSnap) {
              final me = meSnap.data ?? user;
              return StreamBuilder<CoupleModel?>(
                stream: _coupleStream,
                builder: (context, coupleSnap) {
                  return StreamBuilder<List<SentGift>>(
                    stream: _giftsStream,
                    builder: (context, giftsSnap) {
                      final allGifts =
                          giftsSnap.data ?? const <SentGift>[];
                      // تعليم الهدايا الواصلة كـ"شوهدت"
                      _markSeen(me, allGifts);
                      return TabBarView(
                        controller: _tabs,
                        children: [
                          _buildShop(me, coupleSnap.data),
                          _buildInbox(me, allGifts),
                          _buildHistory(me, allGifts),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            colors: const [
              AppColors.primary,
              AppColors.secondary,
              AppColors.secondaryLight,
              Colors.white,
            ],
          ),
        ],
      ),
    );
  }

  // ===== تبويب المتجر =====
  Widget _buildShop(UserModel me, CoupleModel? couple) {
    return StreamBuilder<List<GiftCatalogItem>>(
      stream: _catalogStream,
      builder: (context, snap) {
        final catalog = snap.data ?? const <GiftCatalogItem>[];
        final filtered = _shopFilter == null
            ? catalog
            : catalog.where((g) => g.category == _shopFilter).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // رصيدي
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.romanticGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Text('رصيدك',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('🪙 ${me.coins}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 14),

            // فلتر التصنيفات
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip('الكل ✨', _shopFilter == null,
                      () => setState(() => _shopFilter = null)),
                  ...GiftCategory.values.map((c) => _filterChip(
                        '${c.emoji} ${c.label}',
                        _shopFilter == c,
                        () => setState(() => _shopFilter = c),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 14),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.sizeOf(context).width >= 1100 ? 4 : MediaQuery.sizeOf(context).width >= 700 ? 3 : 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.82,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final g = filtered[i];
                final lock = g.lockFor(
                  coupleLevel: couple?.level ?? 1,
                  coupleStreak: couple?.streak ?? 0,
                  achievements: couple?.achievements ?? const [],
                );
                return GiftShopCard(
                  gift: g,
                  myCoins: me.coins,
                  lock: lock,
                  onTap: () => lock == null
                      ? _confirmSend(g, me)
                      : ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🔒 ${lock.reason}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        ),
                )
                    .animate()
                    .fadeIn(delay: (50 * (i % 6)).ms)
                    .slideY(begin: 0.1);
              },
            ),
          ],
        );
      },
    );
  }

  // ===== تبويب الوارد =====
  Widget _buildInbox(UserModel me, List<SentGift> all) {
    final received = all.where((g) => g.toUid == me.uid).toList();
    final unopened = received.where((g) => !g.opened).toList();
    final opened = received.where((g) => g.opened).toList();

    if (received.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('ما وصلتك هدايا بعد',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (unopened.isNotEmpty) ...[
          Text('هدايا بانتظارك 🎀',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ...unopened.map((g) => GiftHistoryTile(
                gift: g,
                myUid: me.uid,
                partnerName: 'شريكك',
                onOpen: () => _openGift(g, me),
              ).animate().fadeIn().slideY(begin: 0.08)),
          const SizedBox(height: 14),
        ],
        if (opened.isNotEmpty) ...[
          Text('فتحتها سابقًا 💝',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          ...opened.map((g) => GiftHistoryTile(
              gift: g, myUid: me.uid, partnerName: 'شريكك')),
        ],
      ],
    );
  }

  // ===== تبويب السجل + الإحصائيات =====
  Widget _buildHistory(UserModel me, List<SentGift> all) {
    final stats = GiftStats.compute(all, me.uid);
    var filtered = all;
    if (_historyDirection == 'sent') {
      filtered = filtered.where((g) => g.fromUid == me.uid).toList();
    } else if (_historyDirection == 'received') {
      filtered = filtered.where((g) => g.toUid == me.uid).toList();
    }
    if (_historyFilter != null) {
      filtered =
          filtered.where((g) => g.category == _historyFilter).toList();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        // الإحصائيات
        Row(
          children: [
            GiftStatCard(
                emoji: '📤',
                value: '${stats.sentCount}',
                label: 'أرسلتها'),
            const SizedBox(width: 10),
            GiftStatCard(
                emoji: '📥',
                value: '${stats.receivedCount}',
                label: 'استلمتها'),
            const SizedBox(width: 10),
            GiftStatCard(
                emoji: stats.topSentCategory?.emoji ?? '🎁',
                value: stats.topSentCategory?.label ?? '—',
                label: 'الأكثر إرسالًا'),
            const SizedBox(width: 10),
            GiftStatCard(
                emoji: '🪙',
                value: '${stats.totalCoinsSpent}',
                label: 'عملات صرفتها'),
          ],
        ).animate().fadeIn(),
        const SizedBox(height: 14),

        // فلاتر
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _filterChip('الكل', _historyDirection == 'all',
                  () => setState(() => _historyDirection = 'all')),
              _filterChip('المرسلة 📤', _historyDirection == 'sent',
                  () => setState(() => _historyDirection = 'sent')),
              _filterChip(
                  'المستلمة 📥',
                  _historyDirection == 'received',
                  () => setState(() => _historyDirection = 'received')),
              Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  color: AppColors.textSecondary.withOpacity(0.3)),
              _filterChip('كل الأنواع', _historyFilter == null,
                  () => setState(() => _historyFilter = null)),
              ...GiftCategory.values.map((c) => _filterChip(
                    c.emoji,
                    _historyFilter == c,
                    () => setState(() => _historyFilter = c),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text('ما فيه هدايا بهذا الفلتر',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ...filtered.map((g) => GiftHistoryTile(
            gift: g, myUid: me.uid, partnerName: 'شريكك')),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          color: selected ? AppColors.primaryDark : AppColors.textSecondary,
        ),
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary.withOpacity(0.3)),
        ),
      ),
    );
  }
}
