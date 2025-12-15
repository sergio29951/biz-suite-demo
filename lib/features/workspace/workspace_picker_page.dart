import 'package:flutter/material.dart';

import 'models/workspace_option.dart';

class WorkspacePickerPage extends StatelessWidget {
  const WorkspacePickerPage({super.key, required this.workspaces, required this.onSelected});

  final List<WorkspaceOption> workspaces;
  final ValueChanged<WorkspaceOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scegli un workspace'),
      ),
      body: ListView.separated(
        itemCount: workspaces.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final workspace = workspaces[index];
          return ListTile(
            leading: const Icon(Icons.work_outline),
            title: Text(workspace.name),
            subtitle: Text('ID: ${workspace.id}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onSelected(workspace),
          );
        },
      ),
    );
  }
}
