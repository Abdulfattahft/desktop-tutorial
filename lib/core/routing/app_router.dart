import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai/presentation/screens/ai_assistant_screen.dart';
import '../../features/ai/presentation/screens/ai_settings_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/challenges/presentation/screens/challenges_screen.dart';
import '../../features/games/data/models/game_models.dart';
import '../../features/games/presentation/screens/game_play_screen.dart';
import '../../features/games/presentation/screens/games_hub_screen.dart';
import '../../features/games/presentation/screens/wheel_game_screen.dart';
import '../../features/gifts/presentation/screens/gifts_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/linking/presentation/screens/link_partner_screen.dart';
import '../../features/memories/data/models/memory_model.dart';
import '../../features/memories/presentation/screens/add_memory_screen.dart';
import '../../features/memories/presentation/screens/memories_screen.dart';
import '../../features/memories/presentation/screens/memory_detail_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/settings/presentation/screens/delete_account_screen.dart';
import '../../features/settings/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/legal_screen.dart';
import '../../features/settings/presentation/screens/relationship_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../presentation/screens/not_found_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String linkPartner = '/link-partner';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String games = '/games';
  static const String challenges = '/challenges';
  static const String memories = '/memories';
  static const String memoriesAdd = '/memories/add';
  static const String memoryDetail = '/memories/detail';
  static const String gifts = '/gifts';
  static const String settings = '/settings';
  static const String editProfile = '/settings/profile';
  static const String relationship = '/settings/relationship';
  static const String deleteAccount = '/settings/delete-account';
  static const String privacyPolicy = '/settings/privacy';
  static const String terms = '/settings/terms';
  static const String ai = '/ai';
  static const String aiSettings = '/ai/settings';
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notifications/settings';
}

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    errorBuilder: (context, state) =>
        NotFoundScreen(message: state.error?.toString()),
    redirect: (context, state) {
      final signedIn = FirebaseAuth.instance.currentUser != null;
      final location = state.matchedLocation;
      const publicRoutes = {
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      };
      if (!signedIn && !publicRoutes.contains(location)) return AppRoutes.login;
      if (signedIn &&
          (location == AppRoutes.login || location == AppRoutes.register)) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.linkPartner, builder: (_, __) => const LinkPartnerScreen()),
      GoRoute(
        path: AppRoutes.games,
        builder: (_, __) => const GamesHubScreen(),
        routes: [
          GoRoute(
            path: ':type',
            builder: (context, state) {
              final typeName = state.pathParameters['type']!;
              final type = GameType.values.byName(typeName);
              if (type == GameType.wheel) return const WheelGameScreen();
              return GamePlayScreen(gameType: type);
            },
          ),
        ],
      ),
      GoRoute(path: AppRoutes.challenges, builder: (_, __) => const ChallengesScreen()),
      GoRoute(path: AppRoutes.gifts, builder: (_, __) => const GiftsScreen()),
      GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
      GoRoute(path: AppRoutes.editProfile, builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: AppRoutes.relationship, builder: (_, __) => const RelationshipScreen()),
      GoRoute(path: AppRoutes.deleteAccount, builder: (_, __) => const DeleteAccountScreen()),
      GoRoute(path: AppRoutes.privacyPolicy, builder: (_, __) => const LegalScreen(isPrivacy: true)),
      GoRoute(path: AppRoutes.terms, builder: (_, __) => const LegalScreen(isPrivacy: false)),
      GoRoute(path: AppRoutes.ai, builder: (_, __) => const AIAssistantScreen()),
      GoRoute(path: AppRoutes.aiSettings, builder: (_, __) => const AISettingsScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.notificationSettings, builder: (_, __) => const NotificationSettingsScreen()),
      GoRoute(path: AppRoutes.memories, builder: (_, __) => const MemoriesScreen()),
      GoRoute(path: AppRoutes.memoriesAdd, builder: (_, __) => const AddMemoryScreen()),
      GoRoute(
        path: AppRoutes.memoryDetail,
        builder: (context, state) =>
            MemoryDetailScreen(initial: state.extra as MemoryModel),
      ),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
    ],
  );
}
