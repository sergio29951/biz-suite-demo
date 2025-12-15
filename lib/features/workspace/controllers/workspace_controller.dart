import '../../workspace/models/workspace_option.dart';
import '../../workspace/data/workspace_repository.dart';
import '../../../core/session/workspace_session.dart';

class WorkspaceController {
  WorkspaceController({
    required WorkspaceRepository repository,
    required WorkspaceSession session,
  })  : _repository = repository,
        _session = session;

  final WorkspaceRepository _repository;
  final WorkspaceSession _session;

  Future<WorkspaceGateResult> resolveInitialWorkspace(String uid) async {
    final memberships = await _repository.listMemberships(uid);
    return WorkspaceGateResult(memberships: memberships);
  }

  Future<void> setActive(String workspaceId, {String? role}) async {
    _session.setActiveWorkspaceId(workspaceId, role: role);
  }

  Future<String> createWorkspaceAndActivate(
    String uid,
    Map<String, dynamic> workspaceData,
  ) async {
    final id = await _repository.createWorkspaceForAdmin(uid, workspaceData);
    _session.setActiveWorkspaceId(id, role: 'admin');
    return id;
  }

  Future<String?> getUserWorkspaceRole(String uid, String workspaceId) {
    return _repository.getUserWorkspaceRole(uid, workspaceId);
  }
}

class WorkspaceGateResult {
  const WorkspaceGateResult({required this.memberships});

  final List<WorkspaceMembership> memberships;
}
