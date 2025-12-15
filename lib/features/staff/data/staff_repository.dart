import 'package:cloud_firestore/cloud_firestore.dart';

class StaffMember {
  const StaffMember({required this.uid, required this.role, this.email});

  final String uid;
  final String role;
  final String? email;
}

class StaffRepository {
  StaffRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<StaffMember>> listMembers(String workspaceId) async {
    final membersSnap = await _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('members')
        .get();
    final usersCollection = _firestore.collection('users');
    final members = <StaffMember>[];
    for (final doc in membersSnap.docs) {
      final data = doc.data();
      final uid = data['uid'] as String? ?? doc.id;
      final email = (await usersCollection.doc(uid).get()).data()?['email'] as String?;
      members.add(
        StaffMember(
          uid: uid,
          role: (data['role'] as String?) ?? 'staff',
          email: email,
        ),
      );
    }
    return members;
  }

  Future<void> inviteStaffByEmail(String workspaceId, String email) async {
    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .where('role', isEqualTo: 'business')
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      throw StateError('Utente non registrato');
    }

    final userDoc = userQuery.docs.first;
    final uid = userDoc.id;
    final membershipData = {
      'uid': uid,
      'workspaceId': workspaceId,
      'role': 'staff',
      'joinedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('memberships')
        .doc('${uid}_$workspaceId')
        .set(membershipData, SetOptions(merge: true));

    await _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('members')
        .doc(uid)
        .set(membershipData, SetOptions(merge: true));
  }

  Future<void> removeMember(String workspaceId, String uid) async {
    await _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('members')
        .doc(uid)
        .delete();
    await _firestore.collection('memberships').doc('${uid}_$workspaceId').delete();
  }
}
