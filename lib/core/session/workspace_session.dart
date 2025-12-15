import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WorkspaceSession extends ChangeNotifier {
  String? activeWorkspaceId;

  String? get workspaceId => activeWorkspaceId;

  void setActiveWorkspaceId(String id) {
    final cleaned = id.trim();
    activeWorkspaceId = cleaned.isEmpty ? null : cleaned;
    notifyListeners();
  }

  void clear() {
    activeWorkspaceId = null;
    notifyListeners();
  }

  static WorkspaceSession of(BuildContext context) =>
      Provider.of<WorkspaceSession>(context, listen: false);
}
