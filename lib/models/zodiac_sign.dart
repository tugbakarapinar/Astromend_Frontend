/// lib/models/zodiac_sign.dart

class ZodiacSign {
  final int id;
  final String name;
  final String description;
  // eğer start_date/end_date kullanacaksan DateTime ekleyebilirsin

  ZodiacSign({
    required this.id,
    required this.name,
    required this.description,
  });

  factory ZodiacSign.fromJson(Map<String, dynamic> json) {
    return ZodiacSign(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }
}

