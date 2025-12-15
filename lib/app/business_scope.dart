import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/session/workspace_session.dart';
import '../features/customers/controllers/customers_controller.dart';
import '../features/customers/data/customers_repository.dart';
import '../features/kpi/controllers/kpi_controller.dart';
import '../features/kpi/data/kpi_repository.dart';
import '../features/offers/controllers/offers_controller.dart';
import '../features/offers/data/offers_repository.dart';
import '../features/settings/controllers/workspace_settings_controller.dart';
import '../features/settings/data/workspace_settings_repository.dart';
import '../features/transactions/controllers/transactions_controller.dart';
import '../features/transactions/data/transactions_repository.dart';

class BusinessScope extends StatelessWidget {
  const BusinessScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<WorkspaceSession>();

    if (session.activeWorkspaceId == null) {
      return const SizedBox.shrink();
    }

    return MultiProvider(
      providers: [
        Provider<CustomersRepository>(
          create: (_) => CustomersRepository(),
        ),
        Provider<OffersRepository>(
          create: (_) => OffersRepository(FirebaseFirestore.instance),
        ),
        Provider<TransactionsRepository>(
          create: (_) => TransactionsRepository(FirebaseFirestore.instance),
        ),
        Provider<KpiRepository>(
          create: (_) => KpiRepository(firestore: FirebaseFirestore.instance),
        ),
        Provider<WorkspaceSettingsRepository>(
          create: (_) =>
              WorkspaceSettingsRepository(firestore: FirebaseFirestore.instance),
        ),
        ProxyProvider2<CustomersRepository, WorkspaceSession, CustomersController>(
          update: (_, repository, workspaceSession, __) => CustomersController(
            repository: repository,
            session: workspaceSession,
          ),
        ),
        ProxyProvider2<OffersRepository, WorkspaceSession, OffersController>(
          update: (_, repository, __, ___) =>
              OffersController(repository: repository),
        ),
        ProxyProvider2<
            TransactionsRepository,
            WorkspaceSession,
            TransactionsController>(
          update: (_, repository, workspaceSession, __) => TransactionsController(
            repository: repository,
            session: workspaceSession,
          ),
        ),
        ProxyProvider2<KpiRepository, WorkspaceSession, KpiController>(
          update: (_, repository, workspaceSession, __) => KpiController(
            repository: repository,
            session: workspaceSession,
          ),
        ),
        ProxyProvider2<WorkspaceSettingsRepository, WorkspaceSession,
            WorkspaceSettingsController>(
          update: (_, repository, workspaceSession, __) =>
              WorkspaceSettingsController(
            repository: repository,
            session: workspaceSession,
          ),
        ),
      ],
      child: child,
    );
  }
}
