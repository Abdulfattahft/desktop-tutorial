import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../notifications/presentation/viewmodels/notifications_viewmodel.dart';

/// شاشة بداية خفيفة وثابتة، ثم تحدد الوجهة الآمنة للمستخدم.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'جاري تجهيز مساحتكما…';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideNext());
  }

  Future<void> _decideNext() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      final vm = context.read<AuthViewModel>();
      if (vm.isLoggedIn) {
        setState(() => _status = 'جاري استعادة حسابك…');
        final loaded = await vm
            .loadCurrentUser()
            .timeout(const Duration(seconds: 12), onTimeout: () => false);
        if (!mounted) return;

        if (loaded && vm.currentUser != null) {
          final notifVm = context.read<NotificationsViewModel>();
          final uid = vm.currentUser!.uid;
          PushNotificationService.instance.onNotificationTap =
              (route, _) => AppRouter.router.push(route);
          unawaited(
            PushNotificationService.instance.init(
              onToken: (token) => notifVm.saveFcmToken(uid, token),
            ),
          );

          final linked = vm.currentUser?.isLinked ?? false;
          context.go(linked ? AppRoutes.home : AppRoutes.linkPartner);
          return;
        }
      }

      setState(() => _status = 'جاري فتح التطبيق…');
      final seenOnboarding = await LocalStorageService.instance
          .hasSeenOnboarding()
          .timeout(const Duration(seconds: 8), onTimeout: () => false);
      if (!mounted) return;
      context.go(seenOnboarding ? AppRoutes.login : AppRoutes.onboarding);
    } catch (error, stackTrace) {
      debugPrint('Splash routing failed: $error\n$stackTrace');
      if (!mounted) return;
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SizedBox.expand(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.background, AppColors.surface],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: const BoxDecoration(
                        gradient: AppColors.romanticGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'بيننا',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'المسافة تقرّبنا',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
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
