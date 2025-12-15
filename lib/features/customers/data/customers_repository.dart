import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer.dart';

class CustomersRepository {
  CustomersRepository({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _collection(String workspaceId) {
    return firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('customers');
  }

  Stream<List<Customer>> watchCustomers(String workspaceId) {
    return _collection(workspaceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Customer.fromDocument).toList(growable: false));
  }

  Future<void> addCustomer(String workspaceId, Customer customer) async {
    final docRef = _collection(workspaceId).doc();
    await docRef.set({
      ...customer.copyWith(id: docRef.id).toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCustomer(String workspaceId, Customer customer) {
    return _collection(workspaceId).doc(customer.id).update({
          ...customer.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> deleteCustomer(String workspaceId, String customerId) {
    return _collection(workspaceId).doc(customerId).delete();
  }
}
