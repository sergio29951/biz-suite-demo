import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/transaction.dart';

class TransactionsRepository {
  TransactionsRepository(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _collection(String workspaceId) {
    return firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('transactions');
  }

  Stream<List<WorkspaceTransaction>> watchTransactions(
    String workspaceId, {
    DateTime? from,
    DateTime? to,
    String? type,
    String? status,
  }) {
    Query<Map<String, dynamic>> query =
        _collection(workspaceId).orderBy('scheduledAt', descending: true);

    if (from != null) {
      query = query.where('scheduledAt', isGreaterThanOrEqualTo: from);
    }
    if (to != null) {
      query = query.where('scheduledAt', isLessThan: to);
    }
    if (type != null && type != 'all') {
      query = query.where('type', isEqualTo: type);
    }
    if (status != null && status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map(WorkspaceTransaction.fromDocument)
              .toList(growable: false),
        );
  }

  Future<void> addTransaction(
    String workspaceId,
    WorkspaceTransaction transaction,
  ) async {
    final docRef = _collection(workspaceId).doc();
    final data = {
      ...transaction.copyWith(id: docRef.id).toMap(),
      'scheduledAt': transaction.scheduledAt ?? FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(data);
  }

  Future<void> updateTransaction(
    String workspaceId,
    WorkspaceTransaction transaction,
  ) {
    final data = {
      ...transaction.toMap(),
      'scheduledAt': transaction.scheduledAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    return _collection(workspaceId).doc(transaction.id).update(data);
  }

  Future<void> deleteTransaction(String workspaceId, String transactionId) {
    return _collection(workspaceId).doc(transactionId).delete();
  }
}
