import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/session/workspace_session.dart';
import 'create_workspace_page.dart';
import 'workspace_picker_page.dart';

class WorkspaceGate extends StatefulWidget {
  const WorkspaceGate({super.key, required this.user});

  final User user;

  @override
  State<WorkspaceGate> createState() => _WorkspaceGateState();
}

class _WorkspaceGateState extends State<WorkspaceGate> {
  late final Future<_WorkspaceGateData> _gateFuture;

  @override
  void initState() {
    super.initState();
    _gateFuture = _loadData();
  }

  Future<_WorkspaceGateData> _loadData() async {
    final firestore = FirebaseFirestore.instance;
    final uid = widget.user.uid;

    final userDoc = await firestore.collection('users').doc(uid).get();
    final role = (userDoc.data()?['role'] as String?) ?? 'business';

    if (role == 'customer') {
      return _WorkspaceGateData(role: role, workspaces: const []);
    }

    final membershipQuery = await firestore
        .collection('memberships')
        .where('uid', isEqualTo: uid)
        .get();

    if (membershipQuery.docs.isEmpty) {
      return _WorkspaceGateData(role: role, workspaces: const []);
    }

    final futures = membershipQuery.docs.map((doc) async {
      final data = doc.data();
      final workspaceId = data['workspaceId'] as String?;
      if (workspaceId == null || workspaceId.isEmpty) {
        return null;
      }

      final workspaceSnap =
          await firestore.collection('workspaces').doc(workspaceId).get();
      final workspaceData = workspaceSnap.data();
      if (!workspaceSnap.exists || workspaceData == null) {
        return null;
      }

      return WorkspaceOption(
        id: workspaceSnap.id,
        name: workspaceData['name'] as String? ?? 'Workspace',
        role: data['role'] as String?,
      );
    });

    final results = await Future.wait(futures);
    return _WorkspaceGateData(
      role: role,
      workspaces: results.whereType<WorkspaceOption>().toList(),
    );
  }

  void _selectWorkspace(String workspaceId) {
    context.read<WorkspaceSession>().setActiveWorkspaceId(workspaceId);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<WorkspaceSession>();
    if (session.activeWorkspaceId != null) {
      return const AppShell();
    }

    return FutureBuilder<_WorkspaceGateData>(
      future: _gateFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Errore nel caricamento dei workspace: ${snapshot.error}'),
            ),
          );
        }

        final gateData = snapshot.data;
        if (gateData == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (gateData.role == 'customer') {
          return const _CustomerWaitingPage();
        }

        final workspaces = gateData.workspaces;

        if (workspaces.isEmpty) {
          return CreateWorkspacePage(
            user: widget.user,
            onWorkspaceCreated: _selectWorkspace,
          );
        }

        if (workspaces.length == 1) {
          scheduleMicrotask(() => _selectWorkspace(workspaces.first.id));
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return WorkspacePickerPage(
          workspaces: workspaces,
          onSelected: (workspace) => _selectWorkspace(workspace.id),
        );
      },
    );
  }
}

class _WorkspaceGateData {
  const _WorkspaceGateData({required this.role, required this.workspaces});

  final String role;
  final List<WorkspaceOption> workspaces;
}

class WorkspaceOption {
  const WorkspaceOption({required this.id, required this.name, this.role});

  final String id;
  final String name;
  final String? role;
}

class _CustomerWaitingPage extends StatelessWidget {
  const _CustomerWaitingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Account cliente creato. In attesa di collegamento a un\'attività.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
