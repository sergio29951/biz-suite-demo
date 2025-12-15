import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WorkspaceSession extends ChangeNotifier {
  WorkspaceSession(this.user);

  final User user;
  String? workspaceId;

  void updateWorkspace(String? value) {
    workspaceId = value?.trim().isEmpty ?? true ? null : value?.trim();
    notifyListeners();
  }

  static WorkspaceSession of(BuildContext context) =>
      Provider.of<WorkspaceSession>(context, listen: false);
}
