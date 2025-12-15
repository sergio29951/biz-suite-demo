import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/workspace_settings.dart';

class WorkspaceSettingsRepository {
  WorkspaceSettingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String workspaceId) {
    return _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('settings')
        .doc('main');
  }

  Stream<WorkspaceSettings> watch(String workspaceId) {
    return _doc(workspaceId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return WorkspaceSettings.defaults();
      }
      return WorkspaceSettings.fromMap({
        ...data,
        'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
      });
    });
  }

  Future<void> save(String workspaceId, WorkspaceSettings settings) {
    final docRef = _doc(workspaceId);
    return docRef.set({
      ...settings.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
