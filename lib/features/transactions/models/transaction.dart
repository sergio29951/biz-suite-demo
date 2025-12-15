import 'package:cloud_firestore/cloud_firestore.dart';

class WorkspaceTransaction {
  const WorkspaceTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.scheduledAt,
    required this.customerId,
    required this.customerNameSnapshot,
    required this.offerId,
    required this.offerNameSnapshot,
    required this.priceSnapshot,
    required this.quantity,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.createdByUid,
  });

  final String id;
  final String type;
  final String status;
  final DateTime? scheduledAt;
  final String customerId;
  final String customerNameSnapshot;
  final String offerId;
  final String offerNameSnapshot;
  final double priceSnapshot;
  final int quantity;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdByUid;

  factory WorkspaceTransaction.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final scheduledAt = data['scheduledAt'];
    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];

    return WorkspaceTransaction(
      id: doc.id,
      type: data['type'] as String? ?? 'booking',
      status: data['status'] as String? ?? 'new',
      scheduledAt: scheduledAt is Timestamp ? scheduledAt.toDate() : null,
      customerId: data['customerId'] as String? ?? '',
      customerNameSnapshot: data['customerNameSnapshot'] as String? ?? '',
      offerId: data['offerId'] as String? ?? '',
      offerNameSnapshot: data['offerNameSnapshot'] as String? ?? '',
      priceSnapshot: (data['priceSnapshot'] as num?)?.toDouble() ?? 0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      notes: data['notes'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
      createdByUid: data['createdByUid'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'status': status,
      'scheduledAt': scheduledAt,
      'customerId': customerId,
      'customerNameSnapshot': customerNameSnapshot,
      'offerId': offerId,
      'offerNameSnapshot': offerNameSnapshot,
      'priceSnapshot': priceSnapshot,
      'quantity': quantity,
      'notes': notes,
      'createdByUid': createdByUid,
    };
  }

  WorkspaceTransaction copyWith({
    String? id,
    String? type,
    String? status,
    DateTime? scheduledAt,
    String? customerId,
    String? customerNameSnapshot,
    String? offerId,
    String? offerNameSnapshot,
    double? priceSnapshot,
    int? quantity,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByUid,
  }) {
    return WorkspaceTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      customerId: customerId ?? this.customerId,
      customerNameSnapshot:
          customerNameSnapshot ?? this.customerNameSnapshot,
      offerId: offerId ?? this.offerId,
      offerNameSnapshot: offerNameSnapshot ?? this.offerNameSnapshot,
      priceSnapshot: priceSnapshot ?? this.priceSnapshot,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByUid: createdByUid ?? this.createdByUid,
    );
  }
}
