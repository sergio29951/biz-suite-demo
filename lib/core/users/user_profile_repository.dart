import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<String?> getUserRole(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return (snap.data() ?? {})['role'] as String?;
  }

  Future<void> ensureUserDoc(String uid, Map<String, dynamic> data) {
    return _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> watchUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return snap.data();
    });
  }
}
