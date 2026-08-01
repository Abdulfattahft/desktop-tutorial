import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';

/// نموذج بيانات صفحة تعريف واحدة
class OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientColors;

  const OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColors,
  });
}

/// ودجت تعرض صفحة تعريف واحدة — أيقونة كبيرة متحركة + عنوان + وصف
class OnboardingPageView extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingPageView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // دائرة الأيقونة مع هالة خفيفة
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: data.gradientColors,
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: data.gradientColors.first.withOpacity(0.35),
                  blurRadius: 40,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Icon(data.icon, size: 80, color: Colors.white),
          )
              .animate()
              .scale(
                duration: 600.ms,
                curve: Curves.easeOutBack,
                begin: const Offset(0.6, 0.6),
              )
              .then(delay: 200.ms)
              .shake(hz: 2, rotation: 0.02, duration: 400.ms),

          const SizedBox(height: 48),

          Text(
            data.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(
              begin: 0.3, duration: 500.ms, curve: Curves.easeOutCubic),

          const SizedBox(height: 16),

          Text(
            data.description,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(height: 1.7),
          ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(
              begin: 0.3, duration: 500.ms, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}
