class Profile {
  final int? id;
  final String username;
  final String email;
  final String? phoneNumber;
  final String? birthDate;
  final String? zodiacSign;
  final String? birthPlace;
  final String? birthTime;
  final String? profileImage; // <-- EKLENDİ

  Profile({
    this.id,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.birthDate,
    this.zodiacSign,
    this.birthPlace,
    this.birthTime,
    this.profileImage, // <-- EKLENDİ
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int?,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone'] as String? ?? json['phoneNumber'] as String?,
      birthDate: json['birthdate'] as String? ??
          json['birth_date'] as String? ??
          json['birthDate'] as String?,
      zodiacSign: json['zodiacSign'] as String? ??
          json['zodiac_sign'] as String?,
      birthPlace: json['birth_place'] as String? ??
          json['birthPlace'] as String? ??
          json['birthplace'] as String?,
      birthTime: json['birth_time'] as String? ??
          json['birthTime'] as String? ??
          json['birthtime'] as String?,
      profileImage: json['profile_image'] as String?, // <-- EKLENDİ
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phoneNumber,
      'birthdate': birthDate,
      'zodiacSign': zodiacSign,
      'birth_place': birthPlace,
      'birth_time': birthTime,
      'profile_image': profileImage, // <-- EKLENDİ
    };
  }

  Profile copyWith({
    int? id,
    String? username,
    String? email,
    String? phoneNumber,
    String? birthDate,
    String? zodiacSign,
    String? birthPlace,
    String? birthTime,
    String? profileImage, // <-- EKLENDİ
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      birthPlace: birthPlace ?? this.birthPlace,
      birthTime: birthTime ?? this.birthTime,
      profileImage: profileImage ?? this.profileImage, // <-- EKLENDİ
    );
  }
}
