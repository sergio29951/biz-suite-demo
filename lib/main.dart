import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'features/auth/login_page.dart';
import 'features/workspace/workspace_gate.dart';
import 'features/customer/customer_home_page.dart';
import 'firebase_options.dart';
import 'core/auth/auth_service.dart';
import 'core/session/workspace_session.dart';
import 'core/users/user_profile_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const _BizSuiteRoot());
}

class _BizSuiteRoot extends StatelessWidget {
  const _BizSuiteRoot();

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userRepository = UserProfileRepository();
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF0D47A1),
      textTheme: GoogleFonts.interTextTheme(),
    );

    return MaterialApp(
      title: 'Biz Suite Demo',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const LoginPage();
          }

          return StreamBuilder<Map<String, dynamic>?>(
            stream: userRepository.watchUser(user.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child:
                        Text('Errore nel caricamento utente: ${userSnapshot.error}'),
                  ),
                );
              }

              if (!userSnapshot.hasData) {
                return const Scaffold(
                  body: Center(
                    child: Text('Profilo utente non trovato.'),
                  ),
                );
              }

              final data = userSnapshot.data ?? {};
              final role = data['role'] as String? ?? 'business';

              if (role == 'customer') {
                return const CustomerHomePage();
              }

              return ChangeNotifierProvider(
                create: (_) => WorkspaceSession(),
                child: WorkspaceGate(user: user),
              );
            },
          );
        },
      ),
    );
  }
}
