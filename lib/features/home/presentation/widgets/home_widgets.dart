import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../linking/data/models/couple_model.dart';

/// ===== بطاقة الرأس: الاسمان + المستوى + شريط التقدم =====
class CoupleHeaderCard extends StatelessWidget {
  final CoupleModel couple;
  final String myUid;

  const CoupleHeaderCard(
      {super.key, required this.couple, required this.myUid});

  @override
  Widget build(BuildContext context) {
    final myName = couple.names[myUid] ?? '';
    final partnerName = couple.partnerNameOf(myUid);
    final level = couple.level;
    final levelName = AppConstants.levelName(level);

    // تقدم المستوى الحالي
    final thresholds = AppConstants.levelThresholds;
    final currentBase = thresholds[(level - 1).clamp(0, thresholds.length - 1)];
    final nextTarget = level < thresholds.length
        ? thresholds[level]
        : thresholds.last;
    final progress = nextTarget == currentBase
        ? 1.0
        : ((couple.totalPoints - currentBase) / (nextTarget - currentBase))
            .clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  '$myName 💕 $partnerName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'مستوى $level',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            levelName,
            style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600),
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
                color: Colors.white.withOpacity(0.9), fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

/// ===== بطاقة العداد التنازلي لموعد الزواج =====
/// تحدّث نفسها كل ثانية
class WeddingCountdownCard extends StatefulWidget {
  final DateTime? weddingDate;
  final VoidCallback onPickDate;

  const WeddingCountdownCard(
      {super.key, required this.weddingDate, required this.onPickDate});

  @override
  State<WeddingCountdownCard> createState() => _WeddingCountdownCardState();
}

class _WeddingCountdownCardState extends State<WeddingCountdownCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.weddingDate;

    // لم يُحدد الموعد بعد → دعوة لتحديده
    if (date == null) {
      return Card(
        child: InkWell(
          onTap: widget.onPickDate,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      color: AppColors.secondary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('متى الليلة الكبيرة؟ 💍',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text('حددا موعد زواجكما ليبدأ العد التنازلي',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final passed = date.isBefore(now);
    final diff = passed ? now.difference(date) : date.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    return Card(
      child: InkWell(
        onTap: widget.onPickDate, // ضغطة طويلة/قصيرة لتعديل الموعد
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Text(
                passed ? 'متزوجين من 🎉' : 'باقي على زواجكما 💍',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TimeBox(value: days, label: 'يوم'),
                  _sep(),
                  _TimeBox(value: hours, label: 'ساعة'),
                  _sep(),
                  _TimeBox(value: minutes, label: 'دقيقة'),
                  _sep(),
                  _TimeBox(value: seconds, label: 'ثانية'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sep() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text(':',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
      );
}

class _TimeBox extends StatelessWidget {
  final int value;
  final String label;

  const _TimeBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 58,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

/// ===== صف الإحصائيات: نقاط / عملات / ستريك =====
class StatsRow extends StatelessWidget {
  final int points;
  final int coins;
  final int streak;

  const StatsRow(
      {super.key,
      required this.points,
      required this.coins,
      required this.streak});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(emoji: '⭐', value: '$points', label: 'نقاط العلاقة'),
        const SizedBox(width: 12),
        _StatCard(emoji: '🪙', value: '$coins', label: 'عملاتك'),
        const SizedBox(width: 12),
        _StatCard(
          emoji: '🔥',
          value: '$streak',
          label: streak == 1 ? 'يوم متتالي' : 'أيام متتالية',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _StatCard(
      {required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===== زر قسم في شبكة الأقسام =====
class SectionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap; // null = قريبًا

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
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                            fontSize: 13.5, fontWeight: FontWeight.w700)),
                if (!enabled)
                  Text('قريبًا',
                      style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary
                              .withOpacity(0.8))),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
