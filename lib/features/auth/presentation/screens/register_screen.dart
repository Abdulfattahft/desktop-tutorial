import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../viewmodels/auth_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final vm = context.read<AuthViewModel>();
    final ok = await vm.register(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    if (ok) {
      context.go(AppRoutes.linkPartner);
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
    final media = MediaQuery.of(context);
    final compact = media.size.width < 420;
    final horizontal = compact ? 16.0 : 24.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('حساب جديد')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                horizontal,
                compact ? 8 : 16,
                horizontal,
                media.viewInsets.bottom + 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ابدأ حكايتكما ✨',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ).animate().fadeIn(),
                    const SizedBox(height: 6),
                    Text(
                      'أنشئ حسابك ثم اربطه بشريكك برمز الدعوة',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ).animate().fadeIn(delay: 100.ms),
                    SizedBox(height: compact ? 20 : 28),
                    AppTextField(
                      controller: _nameCtrl,
                      hint: 'الاسم',
                      icon: Icons.person_outline_rounded,
                      validator: Validators.name,
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _emailCtrl,
                      hint: 'البريد الإلكتروني',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _passwordCtrl,
                      hint: 'كلمة المرور',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      validator: Validators.password,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _confirmCtrl,
                      hint: 'تأكيد كلمة المرور',
                      icon: Icons.lock_outline_rounded,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      validator: (v) => v != _passwordCtrl.text
                          ? 'كلمتا المرور غير متطابقتين'
                          : null,
                    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2),
                    SizedBox(height: compact ? 20 : 28),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('إنشاء الحساب'),
                    ).animate().fadeIn(delay: 550.ms),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'عندك حساب؟',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text(
                            'سجّل دخولك',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
