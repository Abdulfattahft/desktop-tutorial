import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../viewmodels/auth_viewmodel.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final vm = context.read<AuthViewModel>();
    final ok = await vm.resetPassword(_emailCtrl.text);

    if (!mounted) return;
    if (ok) {
      setState(() => _sent = true);
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

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('استعادة كلمة المرور')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: _sent
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mark_email_read_rounded,
                              size: 80, color: AppColors.success)
                          .animate()
                          .scale(curve: Curves.easeOutBack, duration: 500.ms),
                      const SizedBox(height: 20),
                      Text('تم الإرسال ✅',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 10),
                      Text(
                        'أرسلنا رابط استعادة كلمة المرور إلى بريدك.\nتحقق من صندوق الوارد (أو الرسائل غير المرغوبة).',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(height: 1.7),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      const Icon(Icons.lock_reset_rounded,
                              size: 72, color: AppColors.primary)
                          .animate()
                          .scale(curve: Curves.easeOutBack, duration: 500.ms),
                      const SizedBox(height: 20),
                      Text(
                        'اكتب بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(height: 1.7),
                      ),
                      const SizedBox(height: 28),
                      AppTextField(
                        controller: _emailCtrl,
                        hint: 'البريد الإلكتروني',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('إرسال الرابط'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
