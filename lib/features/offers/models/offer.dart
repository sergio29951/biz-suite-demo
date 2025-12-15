import 'package:cloud_firestore/cloud_firestore.dart';

class Offer {
  const Offer({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String type;
  final double price;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Offer.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];

    return Offer(
      id: doc.id,
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? 'service',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      description: data['description'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'price': price,
      'description': description,
      'isActive': isActive,
    };
  }

  Offer copyWith({
    String? id,
    String? name,
    String? type,
    double? price,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Offer(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      price: price ?? this.price,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
