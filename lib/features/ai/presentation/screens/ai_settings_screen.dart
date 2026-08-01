import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../viewmodels/ai_viewmodel.dart';

/// إعدادات المساعد — تعطيل الميزة، اختيار المزود، مسح السجل
class AISettingsScreen extends StatelessWidget {
  const AISettingsScreen({super.key});

  String _providerLabel(String id) => switch (id) {
        'mock' => 'تجريبي (بدون إنترنت)',
        'cloud_function' => 'مساعد بيننا',
        'remote_configured' => 'مساعد بيننا (إعداد بعيد)',
        _ => id,
      };

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AIViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات المساعد')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Card(
              child: SwitchListTile(
                value: vm.aiEnabled,
                activeColor: AppColors.primary,
                onChanged: vm.setEnabled,
                title: const Text('تفعيل المساعد الذكي',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  vm.aiEnabled
                      ? 'كل ميزات الاقتراحات والرسائل شغّالة'
                      : 'الميزات موقوفة تمامًا',
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text('مزود الذكاء الاصطناعي',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.memory_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(vm.providerName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...vm.availableProviders.map(
                      (id) => RadioListTile<String>(
                        value: id,
                        groupValue: vm.activeProviderId,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        title: Text(_providerLabel(id),
                            style: const TextStyle(fontSize: 13.5)),
                        onChanged: (v) {
                          if (v != null) vm.switchProvider(v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                title: const Text('مسح سجل الاقتراحات',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${vm.history.length} عنصر محفوظ محليًا',
                    style: const TextStyle(fontSize: 12.5)),
                onTap: vm.clearHistory,
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      color: AppColors.secondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'خصوصيتكما محفوظة: لا تُرسل أسماء ولا صور ولا رسائل — '
                      'فقط أرقام عامة (مثل عدد الألعاب) والخيار الذي تختاره.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 12.5, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
