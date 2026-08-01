import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/app_router.dart' show AppRouter;
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../notifications/presentation/viewmodels/notifications_viewmodel.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

/// شاشة البداية — تقرر الوجهة:
/// - مسجل دخوله ومرتبط بشريك → الرئيسية
/// - مسجل دخوله بدون شريك → شاشة الربط
/// - أول مرة → صفحات التعريف
/// - غير ذلك → تسجيل الدخول
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNext();
  }

  Future<void> _decideNext() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final vm = context.read<AuthViewModel>();
    if (vm.isLoggedIn) {
      final loaded = await vm.loadCurrentUser();
      if (!mounted) return;
      if (loaded) {
        // تهيئة الإشعارات الفورية + حفظ الرمز + Deep Linking
        final notifVm = context.read<NotificationsViewModel>();
        final uid = vm.currentUser!.uid;
        PushNotificationService.instance.onNotificationTap =
            (route, _) => AppRouter.router.push(route);
        unawaited(PushNotificationService.instance.init(
          onToken: (token) => notifVm.saveFcmToken(uid, token),
        ));

        final linked = vm.currentUser?.isLinked ?? false;
        context.go(linked ? AppRoutes.home : AppRoutes.linkPartner);
        return;
      }
    }

    final seenOnboarding =
        await LocalStorageService.instance.hasSeenOnboarding();
    if (!mounted) return;
    context.go(seenOnboarding ? AppRoutes.login : AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: AppColors.romanticGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 54),
              )
                  .animate()
                  .scale(
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                      begin: const Offset(0.4, 0.4))
                  .then()
                  .shimmer(duration: 1200.ms, color: Colors.white54),
              const SizedBox(height: 24),
              Text(
                'بيننا',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(
                  begin: 0.3, curve: Curves.easeOutCubic, duration: 600.ms),
              const SizedBox(height: 8),
              Text(
                'المسافة تقرّبنا',
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
