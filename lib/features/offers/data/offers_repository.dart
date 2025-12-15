import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/offer.dart';

class OffersRepository {
  OffersRepository(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _collection(String workspaceId) {
    return firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('offers');
  }

  Stream<List<Offer>> watchOffers(String workspaceId) {
    return _collection(workspaceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Offer.fromDocument).toList(growable: false));
  }

  Future<void> addOffer(String workspaceId, Offer offer) async {
    final docRef = _collection(workspaceId).doc();
    await docRef.set({
      ...offer.copyWith(id: docRef.id).toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateOffer(String workspaceId, Offer offer) {
    return _collection(workspaceId).doc(offer.id).update({
          ...offer.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> deleteOffer(String workspaceId, String offerId) {
    return _collection(workspaceId).doc(offerId).delete();
  }
}
