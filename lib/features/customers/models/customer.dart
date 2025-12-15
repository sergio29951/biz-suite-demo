import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  const Customer({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Customer.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];

    return Customer(
      id: doc.id,
      fullName: data['fullName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String?,
      notes: data['notes'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'notes': notes,
    };
  }

  Customer copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
