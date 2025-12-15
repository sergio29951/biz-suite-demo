import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'features/auth/auth_gate.dart';

class BizSuiteApp extends StatelessWidget {
  const BizSuiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF0D47A1),
      textTheme: GoogleFonts.interTextTheme(),
    );

    return MaterialApp(
      title: 'Biz Suite Demo',
      theme: baseTheme.copyWith(
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: const _FirebaseInitializer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _FirebaseInitializer extends StatelessWidget {
  const _FirebaseInitializer();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Errore di inizializzazione Firebase: ${snapshot.error}'),
            ),
          );
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return const AuthGate();
          },
        );
      },
    );
  }
}
