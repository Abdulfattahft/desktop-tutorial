import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
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
import 'features/memories/data/repositories/memories_repository.dart';
import 'features/memories/presentation/viewmodels/memories_viewmodel.dart';
import 'features/notifications/data/repositories/notifications_repository.dart';
import 'features/notifications/presentation/viewmodels/notifications_viewmodel.dart';
import 'features/settings/data/repositories/settings_repository.dart';
import 'features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'core/services/push_notification_service.dart';
import 'core/config/web_firebase_options.dart';
import 'features/linking/presentation/viewmodels/linking_viewmodel.dart';
// ملاحظة: بعد تنفيذ flutterfire configure فعّل السطر التالي:
// import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) usePathUrlStrategy();

  // بعد flutterfire configure استبدل السطر التالي بـ:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kIsWeb) {
    if (!WebFirebaseOptions.isConfigured) {
      throw StateError('Firebase Web is not configured. See WEB_SETUP.md.');
    }
    await Firebase.initializeApp(options: WebFirebaseOptions.current);
  } else {
    await Firebase.initializeApp();
  }

  // معالج إشعارات الخلفية (يجب تسجيله قبل runApp)
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // تهيئة تنسيق التواريخ بالعربية (لسجل الألعاب وغيره)
  await initializeDateFormatting('ar');

  // تسجيل مزودي الذكاء الاصطناعي
  AIConfig.registerProviders();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<LinkingRepository>(create: (_) => LinkingRepository()),
        Provider<GamesRepository>(create: (_) => GamesRepository()),
        Provider<HomeRepository>(create: (_) => HomeRepository()),
        Provider<ChallengesRepository>(
            create: (_) => ChallengesRepository()),
        Provider<MemoriesRepository>(create: (_) => MemoriesRepository()),
        Provider<GiftsRepository>(create: (_) => GiftsRepository()),
        Provider<NotificationsRepository>(
            create: (_) => NotificationsRepository()),
        Provider<AIRepository>(
            create: (_) => AIRepository(AIConfig.buildActive())),
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
              ctx.read<NotificationsRepository>()),
        ),
        ChangeNotifierProvider<AIViewModel>(
          create: (ctx) => AIViewModel(ctx.read<AIRepository>()),
        ),
        ChangeNotifierProvider<SettingsViewModel>(
          create: (ctx) =>
              SettingsViewModel(ctx.read<SettingsRepository>()),
        ),
      ],
      child: const BaynanaApp(),
    ),
  );
}
