import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/viewmodels/settings_viewmodel.dart';

class BaynanaApp extends StatelessWidget {
  const BaynanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final savedThemeMode = context.watch<SettingsViewModel>().themeMode;

    return MaterialApp.router(
      title: 'بيننا',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // نثبت الوضع الفاتح مؤقتًا على الويب حتى لا تختلط شاشة فارغة
      // بخلفية الوضع الليلي أثناء تهيئة Router على Safari.
      themeMode: kIsWeb ? ThemeMode.light : savedThemeMode,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      scrollBehavior: const _BaynanaScrollBehavior(),
      routerConfig: AppRouter.router,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final currentScale = media.textScaler.scale(16) / 16;
        final safeScale = currentScale.clamp(0.9, 1.25).toDouble();

        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(safeScale)),
          child: ColoredBox(
            color: AppColors.background,
            child: SizedBox.expand(
              child: child ?? const _RouterStartingScreen(),
            ),
          ),
        );
      },
    );
  }
}

class _RouterStartingScreen extends StatelessWidget {
  const _RouterStartingScreen();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_rounded,
              color: AppColors.primary,
              size: 58,
            ),
            SizedBox(height: 18),
            Text(
              'جاري تجهيز بيننا…',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 18),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BaynanaScrollBehavior extends MaterialScrollBehavior {
  const _BaynanaScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}
