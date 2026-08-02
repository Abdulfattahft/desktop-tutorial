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
    // نقطة دخول ثابتة وقابلة للاختبار للنسخة التجريبية على الويب.
    // شاشة البداية تبقى متاحة لكن لا تتحكم في أول Frame.
    initialLocation: AppRoutes.login,
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

      if (!signedIn && !publicRoutes.contains(location)) {
        return AppRoutes.login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.linkPartner,
        builder: (context, state) => const LinkPartnerScreen(),
      ),
      GoRoute(
        path: AppRoutes.games,
        builder: (context, state) => const GamesHubScreen(),
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
      GoRoute(
        path: AppRoutes.challenges,
        builder: (context, state) => const ChallengesScreen(),
      ),
      GoRoute(
        path: AppRoutes.gifts,
        builder: (context, state) => const GiftsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.relationship,
        builder: (context, state) => const RelationshipScreen(),
      ),
      GoRoute(
        path: AppRoutes.deleteAccount,
        builder: (context, state) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const LegalScreen(isPrivacy: true),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (context, state) => const LegalScreen(isPrivacy: false),
      ),
      GoRoute(
        path: AppRoutes.ai,
        builder: (context, state) => const AIAssistantScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiSettings,
        builder: (context, state) => const AISettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.memories,
        builder: (context, state) => const MemoriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.memoriesAdd,
        builder: (context, state) => const AddMemoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.memoryDetail,
        builder: (context, state) =>
            MemoryDetailScreen(initial: state.extra as MemoryModel),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}
