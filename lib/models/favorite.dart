/// lib/models/favorite.dart

class Favorite {
  final int id;
  final int userId;
  final int itemId;
  final DateTime timestamp;

  Favorite({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.timestamp,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      itemId: json['item_id'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'item_id': itemId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

