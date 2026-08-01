import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';

/// حذف الحساب نهائيًا — مع تأكيد صريح وإعادة مصادقة
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _understood = false;
  bool _obscure = true;

  static const String _confirmWord = 'حذف';

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _canDelete =>
      _understood &&
      _confirmCtrl.text.trim() == _confirmWord &&
      _passwordCtrl.text.length >= 6;

  Future<void> _delete() async {
    FocusScope.of(context).unfocus();
    final vm = context.read<SettingsViewModel>();

    final ok = await vm.deleteAccount(_passwordCtrl.text);
    if (!mounted) return;

    if (ok) {
      // الحساب حُذف — نعيد للتسجيل
      await context.read<AuthViewModel>().signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حُذف حسابك. نتمنى نشوفك مرة ثانية 🤍'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go(AppRoutes.login);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'تعذر حذف الحساب'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('حذف الحساب')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            const Center(
                child: Text('⚠️', style: TextStyle(fontSize: 52))),
            const SizedBox(height: 16),
            Text(
              'حذف الحساب إجراء نهائي',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),

            // ماذا سيحدث
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.07),
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: AppColors.error.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اللي بيصير:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error)),
                  const SizedBox(height: 10),
                  Text(
                    '• يُحذف حسابك وبياناتك الشخصية نهائيًا\n'
                    '• ينفصل ارتباطك بشريكك\n'
                    '• تفقد نقاطك وعملاتك ومستواك\n'
                    '• ما تقدر تسترجع الحساب بعد الحذف',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.9),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'ملاحظة: الذكريات والهدايا المشتركة تبقى متاحة لشريكك، '
                    'ويقدر يحذفها من طرفه.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.7, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // التأكيد
            CheckboxListTile(
              value: _understood,
              onChanged: (v) => setState(() => _understood = v ?? false),
              activeColor: AppColors.error,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'أفهم أن هذا الإجراء نهائي ولا يمكن التراجع عنه',
                style: TextStyle(fontSize: 13.5, height: 1.5),
              ),
            ),
            const SizedBox(height: 12),

            Text('اكتب كلمة "$_confirmWord" للتأكيد:',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmCtrl,
              textAlign: TextAlign.center,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'حذف'),
            ),
            const SizedBox(height: 16),

            Text('أدخل كلمة المرور للتحقق من هويتك:',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            AppTextField(
              controller: _passwordCtrl,
              hint: 'كلمة المرور',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              textInputAction: TextInputAction.done,
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: (_canDelete && !vm.isBusy) ? _delete : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                disabledBackgroundColor:
                    AppColors.textSecondary.withOpacity(0.3),
              ),
              child: vm.isBusy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('حذف حسابي نهائيًا'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('تراجع — أبي أبقى 🤍'),
            ),
          ],
        ),
      ),
    );
  }
}
