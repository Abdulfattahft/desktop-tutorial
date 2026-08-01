import 'package:firebase_core/firebase_core.dart';

/// Firebase Web configuration supplied at build/run time.
/// API keys used by Firebase Web identify the Firebase project; security must
/// still be enforced by Authentication, Firestore rules and Storage rules.
class WebFirebaseOptions {
  WebFirebaseOptions._();

  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

  static bool get isConfigured =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      projectId.isNotEmpty;

  static FirebaseOptions get current => FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: authDomain.isEmpty ? null : authDomain,
        storageBucket: storageBucket.isEmpty ? null : storageBucket,
        measurementId: measurementId.isEmpty ? null : measurementId,
      );
}
