import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/viewmodels/settings_viewmodel.dart';

class BaynanaApp extends StatelessWidget {
  const BaynanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'بيننا',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: context.watch<SettingsViewModel>().themeMode,
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
          child: SizedBox.expand(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
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
