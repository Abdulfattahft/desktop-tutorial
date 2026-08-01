import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../linking/data/models/couple_model.dart';

class CoupleHeaderCard extends StatelessWidget {
  final CoupleModel couple;
  final String myUid;

  const CoupleHeaderCard({
    super.key,
    required this.couple,
    required this.myUid,
  });

  @override
  Widget build(BuildContext context) {
    final myName = couple.names[myUid] ?? '';
    final partnerName = couple.partnerNameOf(myUid);
    final level = couple.level;
    final levelName = AppConstants.levelName(level);
    final thresholds = AppConstants.levelThresholds;
    final currentBase = thresholds[(level - 1).clamp(0, thresholds.length - 1)];
    final nextTarget = level < thresholds.length ? thresholds[level] : thresholds.last;
    final progress = nextTarget == currentBase
        ? 1.0
        : ((couple.totalPoints - currentBase) / (nextTarget - currentBase))
            .clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final name = Text(
          '$myName 💕 $partnerName',
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 17 : 20,
            height: 1.35,
            fontWeight: FontWeight.w800,
          ),
        );
        final levelChip = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'مستوى $level',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        );

        return Container(
          padding: EdgeInsets.all(compact ? 16 : 20),
          decoration: BoxDecoration(
            gradient: AppColors.romanticGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                name,
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: levelChip,
                ),
              ] else
                Row(
                  children: [
                    Expanded(child: name),
                    const SizedBox(width: 12),
                    levelChip,
                  ],
                ),
              const SizedBox(height: 8),
              Text(
                levelName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                level < thresholds.length
                    ? '${couple.totalPoints} / $nextTarget نقطة للمستوى القادم'
                    : 'وصلتما لأعلى مستوى! ${couple.totalPoints} نقطة 👑',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class WeddingCountdownCard extends StatefulWidget {
  final DateTime? weddingDate;
  final VoidCallback onPickDate;

  const WeddingCountdownCard({
    super.key,
    required this.weddingDate,
    required this.onPickDate,
  });

  @override
  State<WeddingCountdownCard> createState() => _WeddingCountdownCardState();
}

class _WeddingCountdownCardState extends State<WeddingCountdownCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.weddingDate;

    if (date == null) {
      return Card(
        child: InkWell(
          onTap: widget.onPickDate,
          borderRadius: BorderRadius.circular(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 390;
              return Padding(
                padding: EdgeInsets.all(compact ? 14 : 18),
                child: Row(
                  children: [
                    Container(
                      width: compact ? 42 : 48,
                      height: compact ? 42 : 48,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'متى الليلة الكبيرة؟ 💍',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: compact ? 15 : null,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'حددا موعد زواجكما ليبدأ العد التنازلي',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    if (!compact)
                      const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    final now = DateTime.now();
    final passed = date.isBefore(now);
    final diff = passed ? now.difference(date) : date.difference(now);
    final values = <({int value, String label})>[
      (value: diff.inDays, label: 'يوم'),
      (value: diff.inHours % 24, label: 'ساعة'),
      (value: diff.inMinutes % 60, label: 'دقيقة'),
      (value: diff.inSeconds % 60, label: 'ثانية'),
    ];

    return Card(
      child: InkWell(
        onTap: widget.onPickDate,
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final veryCompact = constraints.maxWidth < 355;
            return Padding(
              padding: EdgeInsets.all(veryCompact ? 12 : 18),
              child: Column(
                children: [
                  Text(
                    passed ? 'متزوجين من 🎉' : 'باقي على زواجكما 💍',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  if (veryCompact)
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: values
                          .map((item) => SizedBox(
                                width: (constraints.maxWidth - 40) / 2,
                                child: _TimeBox(
                                  value: item.value,
                                  label: item.label,
                                  compact: true,
                                ),
                              ))
                          .toList(),
                    )
                  else
                    Row(
                      children: [
                        for (var i = 0; i < values.length; i++) ...[
                          Expanded(
                            child: _TimeBox(
                              value: values[i].value,
                              label: values[i].label,
                              compact: constraints.maxWidth < 430,
                            ),
                          ),
                          if (i != values.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 3),
                              child: Text(
                                ':',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final int value;
  final String label;
  final bool compact;

  const _TimeBox({
    required this.value,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: compact ? 8 : 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 17 : 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: compact ? 10.5 : 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class StatsRow extends StatelessWidget {
  final int points;
  final int coins;
  final int streak;

  const StatsRow({
    super.key,
    required this.points,
    required this.coins,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (emoji: '⭐', value: '$points', label: 'نقاط العلاقة'),
      (emoji: '🪙', value: '$coins', label: 'عملاتك'),
      (
        emoji: '🔥',
        value: '$streak',
        label: streak == 1 ? 'يوم متتالي' : 'أيام متتالية',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 390 ? 2 : 3;
        const gap = 10.0;
        final itemWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          alignment: WrapAlignment.center,
          children: items
              .map((item) => SizedBox(
                    width: itemWidth,
                    child: _StatCard(
                      emoji: item.emoji,
                      value: item.value,
                      label: item.label,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 21)),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: dark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.25,
                color: dark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const SectionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 23),
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (!enabled)
                  Text(
                    'قريبًا',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
