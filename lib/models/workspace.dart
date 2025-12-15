import 'package:cloud_firestore/cloud_firestore.dart';

class Workspace {
  const Workspace({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final DateTime createdAt;

  factory Workspace.fromMap(String id, Map<String, dynamic> data) {
    final createdAtValue = data['createdAt'];
    final createdAt = createdAtValue is Timestamp
        ? createdAtValue.toDate()
        : createdAtValue is DateTime
            ? createdAtValue
            : DateTime.tryParse(createdAtValue?.toString() ?? '') ??
                DateTime.now();

    return Workspace(
      id: id,
      name: data['name'] as String? ?? 'Workspace',
      description: data['description'] as String? ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdAt': createdAt,
    };
  }
}
