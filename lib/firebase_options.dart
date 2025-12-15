import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration for Biz Suite Demo.
/// Replace the placeholder values with your Firebase project's settings.
/// For Flutter web, these should match the configuration provided in
/// `web/index.html`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  /// Web configuration.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT.appspot.com',
    measurementId: 'YOUR_MEASUREMENT_ID',
  );
}
