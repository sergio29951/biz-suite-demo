import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/workspace_option.dart';

class WorkspaceMembership {
  const WorkspaceMembership({required this.option, required this.role});

  final WorkspaceOption option;
  final String role;
}

class WorkspaceRepository {
  WorkspaceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<WorkspaceOption>> listUserWorkspaces(String uid) async {
    final membershipQuery = await _firestore
        .collection('memberships')
        .where('uid', isEqualTo: uid)
        .get();

    final results = <WorkspaceOption>[];
    for (final doc in membershipQuery.docs) {
      final data = doc.data();
      final workspaceId = data['workspaceId'] as String?;
      if (workspaceId == null || workspaceId.isEmpty) continue;
      final workspaceSnap =
          await _firestore.collection('workspaces').doc(workspaceId).get();
      final workspaceData = workspaceSnap.data();
      if (workspaceSnap.exists && workspaceData != null) {
        results.add(
          WorkspaceOption(
            id: workspaceSnap.id,
            name: workspaceData['name'] as String? ?? 'Workspace',
          ),
        );
      }
    }
    return results;
  }

  Future<List<WorkspaceMembership>> listMemberships(String uid) async {
    final membershipQuery = await _firestore
        .collection('memberships')
        .where('uid', isEqualTo: uid)
        .get();

    final results = <WorkspaceMembership>[];
    for (final doc in membershipQuery.docs) {
      final data = doc.data();
      final workspaceId = data['workspaceId'] as String?;
      if (workspaceId == null || workspaceId.isEmpty) continue;
      final workspaceSnap =
          await _firestore.collection('workspaces').doc(workspaceId).get();
      final workspaceData = workspaceSnap.data();
      if (workspaceSnap.exists && workspaceData != null) {
        final role = _normalizeRole(data['role'] as String?);
        results.add(
          WorkspaceMembership(
            option: WorkspaceOption(
              id: workspaceSnap.id,
              name: workspaceData['name'] as String? ?? 'Workspace',
            ),
            role: role,
          ),
        );
      }
    }
    return results;
  }

  Future<String> createWorkspaceForAdmin(
    String uid,
    Map<String, dynamic> workspaceData,
  ) async {
    final workspaceRef = _firestore.collection('workspaces').doc();
    await workspaceRef.set({
      ...workspaceData,
      'createdByUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final membershipData = {
      'uid': uid,
      'workspaceId': workspaceRef.id,
      'role': 'admin',
      'joinedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('memberships')
        .doc('${uid}_${workspaceRef.id}')
        .set(membershipData);

    await workspaceRef.collection('members').doc(uid).set(membershipData);

    return workspaceRef.id;
  }

  Future<String?> getUserWorkspaceRole(String uid, String workspaceId) async {
    final membershipId = '${uid}_$workspaceId';
    final memberDoc =
        await _firestore.collection('memberships').doc(membershipId).get();
    if (!memberDoc.exists) return null;
    return _normalizeRole((memberDoc.data() ?? {})['role'] as String?);
  }

  Stream<List<WorkspaceOption>> watchUserWorkspaces(String uid) {
    return _firestore
        .collection('memberships')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .asyncMap((snapshot) async {
      final futures = snapshot.docs.map((doc) async {
        final data = doc.data();
        final workspaceId = data['workspaceId'] as String?;
        if (workspaceId == null || workspaceId.isEmpty) return null;
        final workspaceSnap =
            await _firestore.collection('workspaces').doc(workspaceId).get();
        final workspaceData = workspaceSnap.data();
        if (!workspaceSnap.exists || workspaceData == null) return null;
        return WorkspaceOption(
          id: workspaceSnap.id,
          name: workspaceData['name'] as String? ?? 'Workspace',
        );
      });
      final results = await Future.wait(futures);
      return results.whereType<WorkspaceOption>().toList();
    });
  }

  static String _normalizeRole(String? role) {
    if (role == 'owner') return 'admin';
    if (role == null || role.isEmpty) return 'staff';
    return role;
  }
}
