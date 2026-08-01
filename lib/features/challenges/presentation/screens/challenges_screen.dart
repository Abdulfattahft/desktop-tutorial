import 'dart:async';

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../home/presentation/viewmodels/home_viewmodel.dart';
import '../../../linking/data/models/couple_model.dart';
import '../../data/models/challenge_models.dart';
import '../viewmodels/challenges_viewmodel.dart';
import '../widgets/challenge_card.dart';

/// شاشة التحديات — يومية وأسبوعية بتحديث لحظي
class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));
  Timer? _ticker;
  Stream<CoupleModel?>? _coupleStream;
  Stream<List<ChallengeModel>>? _challengesStream;

  @override
  void initState() {
    super.initState();
    // عداد الوقت المتبقي يحدث كل دقيقة
    _ticker =
        Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
    // توليد تحديات اليوم إن لم تكن موجودة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final coupleId = context.read<AuthViewModel>().currentUser?.coupleId;
      if (coupleId != null) {
        context.read<ChallengesViewModel>().ensureChallenges(coupleId);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  String _remaining(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'انتهى';
    if (diff.inDays >= 1) {
      return 'باقي ${diff.inDays} يوم و ${diff.inHours % 24} ساعة';
    }
    if (diff.inHours >= 1) {
      return 'باقي ${diff.inHours} ساعة و ${diff.inMinutes % 60} دقيقة';
    }
    return 'باقي ${diff.inMinutes} دقيقة ⏳';
  }

  Future<void> _claim(ChallengeModel c) async {
    final user = context.read<AuthViewModel>().currentUser!;
    final vm = context.read<ChallengesViewModel>();
    final ok = await vm.claimReward(
      coupleId: user.coupleId!,
      challengeId: c.id,
      uid: user.uid,
      playerIds: [user.uid, user.partnerId!],
    );
    if (!mounted) return;
    if (ok) {
      _confetti.play();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '🎉 مبروك! +${c.rewardPoints} نقطة و +${c.rewardCoins} عملة لكل واحد'),
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

  Future<void> _markDone(ChallengeModel c) async {
    final user = context.read<AuthViewModel>().currentUser!;
    await context.read<ChallengesViewModel>().markDone(
          coupleId: user.coupleId!,
          challengeId: c.id,
          uid: user.uid,
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null || !user.isLinked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final vm = context.read<ChallengesViewModel>();
    final homeVm = context.read<HomeViewModel>();

    _coupleStream ??= homeVm.coupleStream(user.coupleId!);
    _challengesStream ??= vm.challengesStream(user.coupleId!);

    return Scaffold(
      appBar: AppBar(title: const Text('التحديات 🔥')),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            // نحتاج بيانات الزوجين (ستريك + عداد الألعاب) لحساب التقدم لحظيًا
            child: StreamBuilder<CoupleModel?>(
              stream: _coupleStream,
              builder: (context, coupleSnap) {
                final couple = coupleSnap.data;
                if (couple == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return StreamBuilder<List<ChallengeModel>>(
                  stream: _challengesStream,
                  builder: (context, snap) {
                    final all = snap.data ?? const [];
                    if (snap.connectionState == ConnectionState.waiting &&
                        all.isEmpty) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    final daily = all
                        .where((c) => c.period == ChallengePeriod.daily)
                        .toList();
                    final weekly = all
                        .where((c) => c.period == ChallengePeriod.weekly)
                        .toList();

                    int progressOf(ChallengeModel c) => c.progressWith(
                          coupleStreak: couple.streak,
                          gamesTotal: couple.gamesPlayedTotal,
                        );

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        if (daily.isNotEmpty) ...[
                          _SectionHeader(
                            title: 'تحديات اليوم ☀️',
                            subtitle: _remaining(daily.first.expiresAt),
                          ),
                          const SizedBox(height: 12),
                          ...daily.asMap().entries.map(
                                (e) => ChallengeCard(
                                  challenge: e.value,
                                  progress: progressOf(e.value),
                                  myUid: user.uid,
                                  onMarkDone: () => _markDone(e.value),
                                  onClaim: () => _claim(e.value),
                                )
                                    .animate()
                                    .fadeIn(delay: (100 * e.key).ms)
                                    .slideY(begin: 0.1),
                              ),
                        ],
                        if (weekly.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _SectionHeader(
                            title: 'تحدي الأسبوع 🏆',
                            subtitle: _remaining(weekly.first.expiresAt),
                          ),
                          const SizedBox(height: 12),
                          ...weekly.map(
                            (c) => ChallengeCard(
                              challenge: c,
                              progress: progressOf(c),
                              myUid: user.uid,
                              onMarkDone: () => _markDone(c),
                              onClaim: () => _claim(c),
                            ).animate().fadeIn(delay: 300.ms).slideY(
                                begin: 0.1),
                          ),
                        ],
                        if (all.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Column(
                              children: [
                                const Text('🎯',
                                    style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 12),
                                Text(
                                  'جارٍ تجهيز تحديات اليوم…',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge,
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
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
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            subtitle,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark),
          ),
        ),
      ],
    );
  }
}
