/// lib/models/score.dart

class Score {
  final int id;
  final int userId;
  final double score;
  final DateTime timestamp;

  Score({
    required this.id,
    required this.userId,
    required this.score,
    required this.timestamp,
  });

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      score: (json['score'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'score': score,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
