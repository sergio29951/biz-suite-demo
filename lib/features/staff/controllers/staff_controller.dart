import '../../../core/permissions/permissions.dart';
import '../data/staff_repository.dart';

class StaffController {
  StaffController({required StaffRepository repository}) : _repository = repository;

  final StaffRepository _repository;

  Future<List<StaffMember>> listMembers(String workspaceId) {
    return _repository.listMembers(workspaceId);
  }

  Future<void> invite(String workspaceId, String email, String workspaceRole) {
    if (!canManageStaff(workspaceRole)) {
      throw StateError('Not allowed');
    }
    return _repository.inviteStaffByEmail(workspaceId, email);
  }

  Future<void> remove(String workspaceId, String uid, String workspaceRole) {
    if (!canManageStaff(workspaceRole)) {
      throw StateError('Not allowed');
    }
    return _repository.removeMember(workspaceId, uid);
  }
}
