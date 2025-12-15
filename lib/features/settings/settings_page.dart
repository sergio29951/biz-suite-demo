import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/workspace_settings_controller.dart';
import 'models/workspace_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WorkspaceSettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: StreamBuilder<WorkspaceSettings>(
        stream: controller.watch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = snapshot.data ?? WorkspaceSettings.defaults();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nome attività: ${settings.nomeAttivita.isEmpty ? '—' : settings.nomeAttivita}'),
                const SizedBox(height: 8),
                Text('Valuta: ${settings.valuta}'),
                const SizedBox(height: 8),
                Text('Durata slot (min): ${settings.durataSlotMinuti}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
