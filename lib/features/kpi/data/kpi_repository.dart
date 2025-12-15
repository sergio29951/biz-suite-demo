import 'package:cloud_firestore/cloud_firestore.dart';

import '../../transactions/models/transaction.dart';

class KpiRepository {
  KpiRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String workspaceId) {
    return _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('transactions');
  }

  Stream<List<WorkspaceTransaction>> watchTransactions(
    String workspaceId, {
    DateTime? from,
    DateTime? to,
  }) {
    Query<Map<String, dynamic>> query =
        _collection(workspaceId).orderBy('scheduledAt', descending: true);

    if (from != null) {
      query = query.where('scheduledAt', isGreaterThanOrEqualTo: from);
    }
    if (to != null) {
      query = query.where('scheduledAt', isLessThan: to);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map(WorkspaceTransaction.fromDocument)
              .toList(growable: false),
        );
  }
}
