/// lib/models/gift.dart

class Gift {
  final int id;
  final String name;
  final String description;
  final double price;
  final DateTime timestamp;

  Gift({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.timestamp,
  });

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

