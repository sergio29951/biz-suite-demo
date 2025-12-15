import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/auth/login_page.dart';
import 'core/session/workspace_session.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/customers/customers_page.dart';
import 'features/customers/controllers/customers_controller.dart';
import 'features/customers/data/customers_repository.dart';
import 'features/offers/offers_page.dart';
import 'features/offers/controllers/offers_controller.dart';
import 'features/offers/data/offers_repository.dart';
import 'features/staff/staff_page.dart';
import 'features/transactions/transactions_page.dart';
import 'features/transactions/data/transactions_repository.dart';
import 'features/workspace/permissions.dart';

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

            final user = authSnapshot.data;
            if (user == null) {
              return const LoginPage();
            }

            return MultiProvider(
              providers: [
                Provider(
                  create: (_) => CustomersController(
                    repository: CustomersRepository(),
                  ),
                ),
                Provider(
                  create: (_) => OffersController(
                    repository: OffersRepository(FirebaseFirestore.instance),
                  ),
                ),
                Provider(
                  create: (_) => TransactionsRepository(FirebaseFirestore.instance),
                ),
                ChangeNotifierProvider(
                  create: (_) => WorkspaceSession(),
                ),
              ],
              child: const AppShell(),
            );
          },
        );
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<WorkspaceSession>(context, listen: true);
    final role = session.memberRole;

    final tabs = <_ShellTab>[
      const _ShellTab(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        page: DashboardPage(),
      ),
      _ShellTab(
        label: 'Attività',
        icon: Icons.event_note_outlined,
        page: TransactionsPage(),
      ),
      _ShellTab(
        label: 'Clienti',
        icon: Icons.people_alt_outlined,
        page: CustomersPage(),
      ),
      _ShellTab(
        label: 'Offerte',
        icon: Icons.local_offer_outlined,
        page: OffersPage(),
      ),
      if (canManageStaff(role))
        _ShellTab(
          label: 'Staff',
          icon: Icons.group_outlined,
          page: StaffPage(),
        ),
      const _ShellTab(
        label: 'Impostazioni',
        icon: Icons.settings_outlined,
        page: Center(child: Text('Impostazioni')),
      ),
    ];

    final safeIndex = _currentIndex >= tabs.length ? 0 : _currentIndex;
    if (safeIndex != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(() => _currentIndex = safeIndex),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: tabs.map((t) => t.page).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab({
    required this.label,
    required this.icon,
    required this.page,
  });

  final String label;
  final IconData icon;
  final Widget page;
}
