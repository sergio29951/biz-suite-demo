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
  late final Future<List<WorkspaceOption>> _workspacesFuture;

  @override
  void initState() {
    super.initState();
    _workspacesFuture = _fetchWorkspaces();
  }

  Future<List<WorkspaceOption>> _fetchWorkspaces() async {
    final firestore = FirebaseFirestore.instance;
    final uid = widget.user.uid;

    final membershipQuery = await firestore
        .collection('memberships')
        .where('uid', isEqualTo: uid)
        .get();

    if (membershipQuery.docs.isEmpty) {
      return [];
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
    return results.whereType<WorkspaceOption>().toList();
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

    return FutureBuilder<List<WorkspaceOption>>(
      future: _workspacesFuture,
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

        final workspaces = snapshot.data ?? [];

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
