import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import '../models/offering.dart';
import '../models/transaction.dart';
import '../models/workspace.dart';

class FirestoreService {
  FirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _workspaceCollection() =>
      _firestore.collection('workspaces');

  CollectionReference<Map<String, dynamic>> _customerCollection(
    String workspaceId,
  ) =>
      _workspaceCollection()
          .doc(workspaceId)
          .collection('customers');

  CollectionReference<Map<String, dynamic>> _offeringCollection(
    String workspaceId,
  ) =>
      _workspaceCollection()
          .doc(workspaceId)
          .collection('offerings');

  CollectionReference<Map<String, dynamic>> _transactionCollection(
    String workspaceId,
  ) =>
      _workspaceCollection()
          .doc(workspaceId)
          .collection('transactions');

  Stream<Workspace> watchWorkspace(String workspaceId) {
    return _workspaceCollection()
        .doc(workspaceId)
        .snapshots()
        .map((snapshot) => Workspace.fromMap(snapshot.id, snapshot.data() ?? {}));
  }

  Stream<List<Customer>> watchCustomers(String workspaceId) {
    return _customerCollection(workspaceId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Customer.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<Offering>> watchOfferings(String workspaceId) {
    return _offeringCollection(workspaceId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Offering.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<TransactionRecord>> watchTransactions(String workspaceId) {
    return _transactionCollection(workspaceId)
        .orderBy('createdAt', descending: true)
        .limit(25)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addCustomer(String workspaceId, Customer customer) {
    return _customerCollection(workspaceId).add(customer.toMap());
  }

  Future<void> addOffering(String workspaceId, Offering offering) {
    return _offeringCollection(workspaceId).add(offering.toMap());
  }

  Future<void> addTransaction(String workspaceId, TransactionRecord record) {
    return _transactionCollection(workspaceId).add(record.toMap());
  }
}
