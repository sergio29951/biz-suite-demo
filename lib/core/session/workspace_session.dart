import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WorkspaceSession extends ChangeNotifier {
  String? activeWorkspaceId;
  String? memberRole;

  String? get workspaceId => activeWorkspaceId;

  void setActiveWorkspaceId(String id, {String? role}) {
    final cleaned = id.trim();
    activeWorkspaceId = cleaned.isEmpty ? null : cleaned;
    if (role != null) {
      memberRole = role;
    }
    notifyListeners();
  }

  void setMemberRole(String? role) {
    memberRole = role;
    notifyListeners();
  }

  void clear() {
    activeWorkspaceId = null;
    memberRole = null;
    notifyListeners();
  }

  static WorkspaceSession of(BuildContext context) =>
      Provider.of<WorkspaceSession>(context, listen: false);
}
