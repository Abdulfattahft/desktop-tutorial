import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/legal_texts.dart';

/// عرض النصوص القانونية (سياسة الخصوصية / الشروط)
class LegalScreen extends StatelessWidget {
  final bool isPrivacy;
  const LegalScreen({super.key, required this.isPrivacy});

  @override
  Widget build(BuildContext context) {
    final text = isPrivacy
        ? LegalTexts.privacyPolicy
        : LegalTexts.termsOfService;

    return Scaffold(
      appBar: AppBar(
        title: Text(isPrivacy ? 'سياسة الخصوصية' : 'الشروط والأحكام'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                      isPrivacy
                          ? Icons.privacy_tip_rounded
                          : Icons.description_rounded,
                      color: AppColors.primary,
                      size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      LegalTexts.lastUpdated,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SelectableText(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(height: 1.9, fontSize: 14.5),
            ),
          ],
        ),
      ),
    );
  }
}
