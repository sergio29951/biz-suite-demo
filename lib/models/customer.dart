class Customer {
  const Customer({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.email,
    required this.phone,
    this.notes = '',
  });

  final String id;
  final String workspaceId;
  final String name;
  final String email;
  final String phone;
  final String notes;

  factory Customer.fromMap(String id, Map<String, dynamic> data) {
    return Customer(
      id: id,
      workspaceId: data['workspaceId'] as String? ?? '',
      name: data['name'] as String? ?? 'Customer',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workspaceId': workspaceId,
      'name': name,
      'email': email,
      'phone': phone,
      'notes': notes,
    };
  }
}
