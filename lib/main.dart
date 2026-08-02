import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/config/web_firebase_options.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/web_font_service.dart';
import 'core/services/web_startup_signal.dart';
import 'features/ai/ai_config.dart';
import 'features/ai/data/repositories/ai_repository.dart';
import 'features/ai/presentation/viewmodels/ai_viewmodel.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/challenges/data/repositories/challenges_repository.dart';
import 'features/challenges/presentation/viewmodels/challenges_viewmodel.dart';
import 'features/games/data/repositories/games_repository.dart';
import 'features/games/presentation/viewmodels/games_viewmodel.dart';
import 'features/gifts/data/repositories/gifts_repository.dart';
import 'features/gifts/presentation/viewmodels/gifts_viewmodel.dart';
import 'features/home/data/repositories/home_repository.dart';
import 'features/home/presentation/viewmodels/home_viewmodel.dart';
import 'features/linking/data/repositories/linking_repository.dart';
import 'features/linking/presentation/viewmodels/linking_viewmodel.dart';
import 'features/memories/data/repositories/memories_repository.dart';
import 'features/memories/presentation/viewmodels/memories_viewmodel.dart';
import 'features/notifications/data/repositories/notifications_repository.dart';
import 'features/notifications/presentation/viewmodels/notifications_viewmodel.dart';
import 'features/settings/data/repositories/settings_repository.dart';
import 'features/settings/presentation/viewmodels/settings_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const enablePathUrls = bool.fromEnvironment(
    'USE_PATH_URL_STRATEGY',
    defaultValue: true,
  );
  if (kIsWeb && enablePathUrls) usePathUrlStrategy();

  try {
    if (kIsWeb) {
      if (!WebFirebaseOptions.isConfigured) {
        await initializeDateFormatting('ar');
        _runRoot(const _FirebaseSetupApp());
        return;
      }

      await Firebase.initializeApp(
        options: WebFirebaseOptions.current,
      ).timeout(const Duration(seconds: 20));
    } else {
      await Firebase.initializeApp().timeout(const Duration(seconds: 20));
    }

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    await initializeDateFormatting('ar').timeout(const Duration(seconds: 12));
    AIConfig.registerProviders();

    _runRoot(
      MultiProvider(
        providers: [
          Provider<AuthRepository>(create: (_) => AuthRepository()),
          Provider<LinkingRepository>(create: (_) => LinkingRepository()),
          Provider<GamesRepository>(create: (_) => GamesRepository()),
          Provider<HomeRepository>(create: (_) => HomeRepository()),
          Provider<ChallengesRepository>(
            create: (_) => ChallengesRepository(),
          ),
          Provider<MemoriesRepository>(create: (_) => MemoriesRepository()),
          Provider<GiftsRepository>(create: (_) => GiftsRepository()),
          Provider<NotificationsRepository>(
            create: (_) => NotificationsRepository(),
          ),
          Provider<AIRepository>(
            create: (_) => AIRepository(AIConfig.buildActive()),
          ),
          Provider<SettingsRepository>(create: (_) => SettingsRepository()),
          ChangeNotifierProvider<AuthViewModel>(
            create: (ctx) => AuthViewModel(ctx.read<AuthRepository>()),
          ),
          ChangeNotifierProvider<LinkingViewModel>(
            create: (ctx) => LinkingViewModel(ctx.read<LinkingRepository>()),
          ),
          ChangeNotifierProvider<GamesViewModel>(
            create: (ctx) => GamesViewModel(ctx.read<GamesRepository>()),
          ),
          ChangeNotifierProvider<HomeViewModel>(
            create: (ctx) => HomeViewModel(ctx.read<HomeRepository>()),
          ),
          ChangeNotifierProvider<ChallengesViewModel>(
            create: (ctx) =>
                ChallengesViewModel(ctx.read<ChallengesRepository>()),
          ),
          ChangeNotifierProvider<MemoriesViewModel>(
            create: (ctx) =>
                MemoriesViewModel(ctx.read<MemoriesRepository>()),
          ),
          ChangeNotifierProvider<GiftsViewModel>(
            create: (ctx) => GiftsViewModel(ctx.read<GiftsRepository>()),
          ),
          ChangeNotifierProvider<NotificationsViewModel>(
            create: (ctx) => NotificationsViewModel(
              ctx.read<NotificationsRepository>(),
            ),
          ),
          ChangeNotifierProvider<AIViewModel>(
            create: (ctx) => AIViewModel(ctx.read<AIRepository>()),
          ),
          ChangeNotifierProvider<SettingsViewModel>(
            create: (ctx) => SettingsViewModel(
              ctx.read<SettingsRepository>(),
            ),
          ),
        ],
        child: const BaynanaApp(),
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('Baynana startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    _runRoot(_StartupErrorApp(message: error.toString()));
  }
}

void _runRoot(Widget root) {
  runApp(root);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    markFlutterReady();
    if (kIsWeb) {
      unawaited(WebFontService.load());
    }
  });
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFFFF9F6),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('تعذر تشغيل بيننا',
                              style: TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          const Text(
                            'حدث خطأ أثناء تهيئة التطبيق. أرسل صورة هذه الرسالة.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SelectableText(
                            message,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: Color(0xFF9D3F4F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FirebaseSetupApp extends StatelessWidget {
  const _FirebaseSetupApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'بيننا',
      locale: const Locale('ar'),
      theme: ThemeData(fontFamily: WebFontService.family),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFFFFF5F8), Color(0xFFF5E7EE)],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  margin: const EdgeInsets.all(24),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: const BorderSide(color: Color(0xFFE8C5D2)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('💕', style: TextStyle(fontSize: 56)),
                        SizedBox(height: 16),
                        Text(
                          'بيننا',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8F3F5C),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'نسخة الويب تحتاج إلى ربط إعدادات Firebase لتفعيل الحسابات والميزات.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 17, height: 1.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
