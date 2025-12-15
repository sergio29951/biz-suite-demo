import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_service.dart';
import '../../app.dart';
import '../../core/session/workspace_session.dart';
import 'controllers/workspace_controller.dart';
import 'create_workspace_page.dart';
import 'data/workspace_repository.dart';
import 'models/workspace_option.dart';
import 'workspace_picker_page.dart';

class WorkspaceGate extends StatefulWidget {
  const WorkspaceGate({super.key, required this.user});

  final User user;

  @override
  State<WorkspaceGate> createState() => _WorkspaceGateState();
}

class _WorkspaceGateState extends State<WorkspaceGate> {
  late final WorkspaceRepository _repository;
  late final WorkspaceController _controller;
  late final Future<List<WorkspaceMembership>> _membershipsFuture;

  @override
  void initState() {
    super.initState();
    _repository = WorkspaceRepository();
    _controller = WorkspaceController(
      repository: _repository,
      session: context.read<WorkspaceSession>(),
    );
    final uid = (widget.user as dynamic).uid as String;
    _membershipsFuture = _controller
        .resolveInitialWorkspace(uid)
        .then((value) => value.memberships);
  }

  void _selectWorkspace(String workspaceId, {String? role}) {
    _controller.setActive(workspaceId, role: role);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<WorkspaceSession>();
    if (session.activeWorkspaceId != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Biz Suite'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                await AuthService().signOut();
              },
            ),
          ],
        ),
        body: const AppShell(),
      );
    }

    return FutureBuilder<List<WorkspaceMembership>>(
      future: _membershipsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                  'Errore nel caricamento dei workspace: ${snapshot.error}'),
            ),
          );
        }

        final memberships = snapshot.data ?? [];

        if (memberships.isEmpty) {
          final uid = (widget.user as dynamic).uid as String;
          return CreateWorkspacePage(
            userId: uid,
            controller: _controller,
            onWorkspaceCreated: (id) => _selectWorkspace(id, role: 'admin'),
          );
        }

        if (memberships.length == 1) {
          final membership = memberships.first;
          scheduleMicrotask(
            () => _selectWorkspace(
              membership.option.id,
              role: membership.role,
            ),
          );
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final rolesById = {
          for (final membership in memberships)
            membership.option.id: membership.role,
        };

        return WorkspacePickerPage(
          workspaces: memberships.map((e) => e.option).toList(),
          onSelected: (workspace) =>
              _selectWorkspace(workspace.id, role: rolesById[workspace.id]),
        );
      },
    );
  }
}
