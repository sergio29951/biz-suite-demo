import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dashboard/dashboard_page.dart';
import 'sign_in_view.dart';
import 'workspace_scope.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const SignInView();
        }

        return ChangeNotifierProvider(
          create: (_) => WorkspaceSession(),
          child: const DashboardPage(),
        );
      },
    );
  }
}
