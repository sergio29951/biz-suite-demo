import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { booking, order }

enum TransactionStatus { pending, confirmed, cancelled }

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.workspaceId,
    required this.customerId,
    required this.offeringId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String workspaceId;
  final String customerId;
  final String offeringId;
  final double amount;
  final String currency;
  final TransactionType type;
  final TransactionStatus status;
  final DateTime createdAt;

  factory TransactionRecord.fromMap(String id, Map<String, dynamic> data) {
    TransactionType parseType(String? value) {
      return TransactionType.values.firstWhere(
        (type) => type.name == value,
        orElse: () => TransactionType.order,
      );
    }

    TransactionStatus parseStatus(String? value) {
      return TransactionStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => TransactionStatus.pending,
      );
    }

    final dynamic createdAtValue = data['createdAt'];
    final DateTime createdAt = createdAtValue is Timestamp
        ? createdAtValue.toDate()
        : createdAtValue is DateTime
            ? createdAtValue
            : DateTime.tryParse(createdAtValue?.toString() ?? '') ??
                DateTime.now();

    return TransactionRecord(
      id: id,
      workspaceId: data['workspaceId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      offeringId: data['offeringId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? 'USD',
      type: parseType(data['type'] as String?),
      status: parseStatus(data['status'] as String?),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workspaceId': workspaceId,
      'customerId': customerId,
      'offeringId': offeringId,
      'amount': amount,
      'currency': currency,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt,
    };
  }
}
