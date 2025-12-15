import '../../../core/session/workspace_session.dart';
import '../data/workspace_settings_repository.dart';
import '../models/workspace_settings.dart';

class WorkspaceSettingsController {
  WorkspaceSettingsController({
    required WorkspaceSettingsRepository repository,
    required WorkspaceSession session,
  })  : _repository = repository,
        _session = session;

  final WorkspaceSettingsRepository _repository;
  final WorkspaceSession _session;

  Stream<WorkspaceSettings> watch() {
    final workspaceId = _session.activeWorkspaceId;
    if (workspaceId == null) {
      return Stream.value(WorkspaceSettings.defaults());
    }
    return _repository.watch(workspaceId);
  }

  Future<void> saveSettings(WorkspaceSettings settings) {
    final workspaceId = _session.activeWorkspaceId;
    if (workspaceId == null) {
      throw StateError('Workspace non selezionato');
    }
    return _repository.save(workspaceId, settings);
  }
}
