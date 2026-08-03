import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/responsive_page_frame.dart';
import 'features/games/presentation/widgets/game_action_feedback.dart';
import 'features/settings/presentation/viewmodels/settings_viewmodel.dart';

/// جذر تطبيق "بيننا"
/// - العربية هي اللغة الافتراضية (RTL تلقائيًا)
/// - الإنجليزية مضافة في supportedLocales وجاهزة للتفعيل لاحقًا
/// - يدعم الوضع الفاتح والليلي حسب إعدادات الجهاز
class BaynanaApp extends StatelessWidget {
  const BaynanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'بيننا',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: gameScaffoldMessengerKey,

      // ===== الثيمات =====
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // يتبع اختيار المستخدم من الإعدادات (فاتح / ليلي / تلقائي)
      themeMode: context.watch<SettingsViewModel>().themeMode,

      // ===== اللغات =====
      locale: const Locale('ar'), // العربية افتراضيًا
      supportedLocales: const [
        Locale('ar'),
        Locale('en'), // جاهزة للمستقبل
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ===== التوجيه =====
      routerConfig: AppRouter.router,
      builder: (context, child) => ResponsivePageFrame(
        child: GameActionFeedback(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
