import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';

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

class OnboardingPageView extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingPageView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactHeight = constraints.maxHeight < 560;
        final compactWidth = constraints.maxWidth < 380;
        final iconSize = compactHeight
            ? 112.0
            : compactWidth
                ? 138.0
                : constraints.maxWidth >= 700
                    ? 190.0
                    : 165.0;
        final iconGlyph = iconSize * 0.44;
        final horizontal = compactWidth ? 20.0 : 32.0;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: data.gradientColors,
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: data.gradientColors.first.withOpacity(0.3),
                        blurRadius: compactHeight ? 24 : 38,
                        spreadRadius: compactHeight ? 2 : 5,
                      ),
                    ],
                  ),
                  child: Icon(data.icon, size: iconGlyph, color: Colors.white),
                )
                    .animate()
                    .scale(
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                      begin: const Offset(0.6, 0.6),
                    )
                    .then(delay: 200.ms)
                    .shake(hz: 2, rotation: 0.02, duration: 400.ms),
                SizedBox(height: compactHeight ? 24 : 42),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: compactHeight ? 21 : null,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(
                      begin: 0.3,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                    ),
                SizedBox(height: compactHeight ? 10 : 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      fontSize: compactHeight ? 14 : null,
                      height: compactHeight ? 1.55 : 1.7,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(
                      begin: 0.3,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}
