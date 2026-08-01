import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/challenge_models.dart';

/// بطاقة تحدٍ واحدة — تعرض التقدم والمكافأة وحالة الإنجاز
class ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final int progress;
  final String myUid;
  final VoidCallback onMarkDone;
  final VoidCallback onClaim;

  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.progress,
    required this.myUid,
    required this.onMarkDone,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final c = challenge;
    final completed = progress >= c.target;
    final iDidMyPart = c.completedBy[myUid] == true;
    final ratio = (progress / c.target).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child:
                      Text(c.emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(
                        c.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // شريط التقدم + النسبة
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 9,
                      backgroundColor: AppColors.surface,
                      color: completed
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$progress/${c.target}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: completed
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // المكافآت + زر الحالة
            Row(
              children: [
                _RewardChip(text: '⭐ +${c.rewardPoints}'),
                const SizedBox(width: 8),
                _RewardChip(text: '🪙 +${c.rewardCoins}'),
                const Spacer(),
                _buildAction(context,
                    completed: completed, iDidMyPart: iDidMyPart),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context,
      {required bool completed, required bool iDidMyPart}) {
    final c = challenge;

    // مستلَم ✔️
    if (c.claimed) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
          SizedBox(width: 4),
          Text('تم الاستلام',
              style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ],
      );
    }

    // مكتمل → زر الاستلام بلمعة
    if (completed) {
      return ElevatedButton(
        onPressed: onClaim,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Text('استلام المكافأة 🎁',
            style: TextStyle(fontSize: 13)),
      )
          .animate(onPlay: (ctrl) => ctrl.repeat())
          .shimmer(duration: 1800.ms, color: Colors.white54);
    }

    // bothAct: زر "أنجزت" أو انتظار الشريك
    if (c.goalType == ChallengeGoalType.bothAct) {
      if (iDidMyPart) {
        return Text('بانتظار شريكك 💗',
                style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600))
            .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
            .fadeIn(duration: 800.ms);
      }
      return OutlinedButton(
        onPressed: onMarkDone,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          foregroundColor: AppColors.primaryDark,
        ),
        child: const Text('أنجزت ✅', style: TextStyle(fontSize: 13)),
      );
    }

    // playGames / reachStreak: توجيه
    return Text(
      c.goalType == ChallengeGoalType.playGames
          ? 'العبا لإكماله 🎮'
          : 'حافظا على الستريك 🔥',
      style: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.9),
          fontSize: 12.5,
          fontWeight: FontWeight.w600),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String text;
  const _RewardChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
    );
  }
}
