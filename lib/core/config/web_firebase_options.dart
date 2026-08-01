import 'package:firebase_core/firebase_core.dart';

/// Firebase Web configuration.
///
/// Firebase Web configuration values identify the Firebase project and are
/// shipped to the browser by design. Security must be enforced through
/// Authentication, Firestore rules, Storage rules and App Check where needed.
///
/// Values can still be overridden at build time using --dart-define.
class WebFirebaseOptions {
  WebFirebaseOptions._();

  static const apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyB1ZBFGelG16Qia6WExadVMYAWEdQJ2jys',
  );
  static const appId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:867534196842:web:fe0d768771b2ed6d03fa13',
  );
  static const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '867534196842',
  );
  static const projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'baynana-1047c',
  );
  static const authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'baynana-1047c.firebaseapp.com',
  );
  static const storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'baynana-1047c.firebasestorage.app',
  );
  static const measurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
    defaultValue: 'G-KGT0VNPQRR',
  );

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
        authDomain: authDomain,
        storageBucket: storageBucket,
        measurementId: measurementId,
      );
}
