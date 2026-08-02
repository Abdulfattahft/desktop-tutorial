import 'dart:ui' show PlatformDispatcher;

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
import 'core/services/web_ready_service.dart';
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
  _installVisibleErrorHandlers();

  try {
    await WebFontService.load();

    const enablePathUrls = bool.fromEnvironment(
      'USE_PATH_URL_STRATEGY',
      defaultValue: true,
    );
    if (kIsWeb && enablePathUrls) usePathUrlStrategy();

    if (kIsWeb) {
      if (!WebFirebaseOptions.isConfigured) {
        await initializeDateFormatting('ar');
        _runMarkedApp(const _FirebaseSetupApp(), screen: 'firebase-setup');
        return;
      }
      await Firebase.initializeApp(options: WebFirebaseOptions.current);
    } else {
      await Firebase.initializeApp();
    }

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );
    }

    await initializeDateFormatting('ar');
    AIConfig.registerProviders();

    // لا نعلن نجاح الويب هنا. شاشة تسجيل الدخول نفسها تعلن الجاهزية
    // بعد أن تُرسم فعليًا، حتى لا تختفي شاشة التحميل فوق صفحة فارغة.
    runApp(
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
    debugPrint('Baynana startup failed: $error\n$stackTrace');
    _runMarkedApp(
      _StartupFailureApp(message: error.toString()),
      screen: 'startup-error',
    );
  }
}

void _installVisibleErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error: $error\n$stack');
    return false;
  };

  ErrorWidget.builder = (details) => _VisibleErrorWidget(
        message: details.exceptionAsString(),
      );
}

void _runMarkedApp(Widget app, {required String screen}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    markWebAppReady(screen: screen);
  });
  runApp(app);
}

class _VisibleErrorWidget extends StatefulWidget {
  final String message;

  const _VisibleErrorWidget({required this.message});

  @override
  State<_VisibleErrorWidget> createState() => _VisibleErrorWidgetState();
}

class _VisibleErrorWidgetState extends State<_VisibleErrorWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      markWebAppReady(screen: 'flutter-error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1E1A19),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2422),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF76504F)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFFFB4AB),
                        size: 46,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'خطأ في واجهة تطبيق بيننا',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SelectableText(
                        widget.message,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          color: Color(0xFFFFB4AB),
                          fontSize: 13,
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
    );
  }
}

class _StartupFailureApp extends StatelessWidget {
  final String message;

  const _StartupFailureApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFF1E1A19),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2422),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFF76504F)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFFFB4AB),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'تعذر بدء تطبيق بيننا',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'ظهرت مشكلة أثناء تهيئة خدمات التطبيق.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFE0D6D2),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          message,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            color: Color(0xFFFFB4AB),
                            fontSize: 13,
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
                          'نسخة الويب جاهزة للنشر، وتحتاج فقط إلى ربط إعدادات Firebase لتفعيل الحسابات والذكريات والألعاب وبقية المزايا.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 17, height: 1.7),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'أضف قيم Firebase إلى GitHub Secrets ثم أعد تشغيل النشر.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B5B62),
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
    );
  }
}
