import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/challenge_models.dart';

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 390;
          return Padding(
            padding: EdgeInsets.all(compact ? 14 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: compact ? 42 : 48,
                      height: compact ? 42 : 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        c.emoji,
                        style: TextStyle(fontSize: compact ? 21 : 24),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontSize: compact ? 15 : 16),
                          ),
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
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 9,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
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
                if (compact) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _RewardChip(text: '⭐ +${c.rewardPoints}'),
                      _RewardChip(text: '🪙 +${c.rewardCoins}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: _buildAction(
                      context,
                      completed: completed,
                      iDidMyPart: iDidMyPart,
                      fullWidth: completed,
                    ),
                  ),
                ] else
                  Row(
                    children: [
                      _RewardChip(text: '⭐ +${c.rewardPoints}'),
                      const SizedBox(width: 8),
                      _RewardChip(text: '🪙 +${c.rewardCoins}'),
                      const Spacer(),
                      Flexible(
                        child: _buildAction(
                          context,
                          completed: completed,
                          iDidMyPart: iDidMyPart,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAction(
    BuildContext context, {
    required bool completed,
    required bool iDidMyPart,
    bool fullWidth = false,
  }) {
    final c = challenge;

    if (c.claimed) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 20,
          ),
          SizedBox(width: 4),
          Text(
            'تم الاستلام',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    if (completed) {
      final button = ElevatedButton(
        onPressed: onClaim,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          minimumSize: Size(fullWidth ? double.infinity : 0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: const Text(
          'استلام المكافأة 🎁',
          maxLines: 1,
          style: TextStyle(fontSize: 12.5),
        ),
      )
          .animate(onPlay: (ctrl) => ctrl.repeat())
          .shimmer(duration: 1800.ms, color: Colors.white54);
      return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
    }

    if (c.goalType == ChallengeGoalType.bothAct) {
      if (iDidMyPart) {
        return Text(
          'بانتظار شريكك 💗',
          textAlign: TextAlign.end,
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.9),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        )
            .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
            .fadeIn(duration: 800.ms);
      }
      return OutlinedButton(
        onPressed: onMarkDone,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          foregroundColor: AppColors.primaryDark,
        ),
        child: const Text('أنجزت ✅', style: TextStyle(fontSize: 13)),
      );
    }

    return Text(
      c.goalType == ChallengeGoalType.playGames
          ? 'العبا لإكماله 🎮'
          : 'حافظا على الستريك 🔥',
      textAlign: TextAlign.end,
      style: TextStyle(
        color: AppColors.textSecondary.withOpacity(0.9),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String text;

  const _RewardChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: dark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
    );
  }
}
