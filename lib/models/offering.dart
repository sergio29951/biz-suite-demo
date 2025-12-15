class Offering {
  const Offering({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
  });

  final String id;
  final String workspaceId;
  final String name;
  final String description;
  final double price;
  final String currency;

  factory Offering.fromMap(String id, Map<String, dynamic> data) {
    return Offering(
      id: id,
      workspaceId: data['workspaceId'] as String? ?? '',
      name: data['name'] as String? ?? 'Offering',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? 'USD',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workspaceId': workspaceId,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
    };
  }
}
