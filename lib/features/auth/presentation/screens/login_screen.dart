import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final vm = context.read<AuthViewModel>();
    final ok = await vm.login(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    if (ok) {
      // إذا لم يرتبط بشريك بعد → شاشة الربط، وإلا → الرئيسية
      final linked = vm.currentUser?.isLinked ?? false;
      context.go(linked ? AppRoutes.home : AppRoutes.linkPartner);
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // الشعار
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      gradient: AppColors.romanticGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        color: Colors.white, size: 40),
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 20),

                  Text('أهلًا بعودتك 💕',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium)
                      .animate()
                      .fadeIn(delay: 150.ms),
                  const SizedBox(height: 6),
                  Text('سجّل دخولك وكمّل رحلتكما',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium)
                      .animate()
                      .fadeIn(delay: 250.ms),

                  const SizedBox(height: 36),

                  AppTextField(
                    controller: _emailCtrl,
                    hint: 'البريد الإلكتروني',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _passwordCtrl,
                    hint: 'كلمة المرور',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscure,
                    textInputAction: TextInputAction.done,
                    validator: Validators.password,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.forgotPassword),
                      child: const Text('نسيت كلمة المرور؟',
                          style: TextStyle(color: AppColors.primaryDark)),
                    ),
                  ),

                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('تسجيل الدخول'),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('ما عندك حساب؟',
                          style: Theme.of(context).textTheme.bodyMedium),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.register),
                        child: const Text('أنشئ حسابًا',
                            style: TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
