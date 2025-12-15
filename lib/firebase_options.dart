import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration for Biz Suite Demo.
/// Replace the placeholder values with your Firebase project's settings.
/// For Flutter web, these should match the configuration provided in
/// `web/index.html`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDyE-sZAPpjmRWecikrk9G0oPo7V_V1y00',
    appId: '1:1086885236082:web:9288a1097a8a2553e7a1eb',
    messagingSenderId: '1086885236082',
    projectId: 'biz-suite-demo',
    authDomain: 'biz-suite-demo.firebaseapp.com',
    storageBucket: 'biz-suite-demo.firebasestorage.app',
    measurementId: 'G-5V7X9Y960E',
  );

  /// Web configuration.
}