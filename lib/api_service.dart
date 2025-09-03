import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'models/message.dart';
import 'models/favorite.dart';
import 'models/gift.dart';
import 'models/score.dart';
import 'models/notification_model.dart';
import 'models/profile.dart';
import 'models/zodiac_sign.dart';

class ApiService {
  static final String _baseUrl =
      dotenv.env['API_URL'] ?? 'https://api.astromend.com';
  static const Duration timeoutDuration = Duration(seconds: 30);

  // ----------- PAYLAŞIMLAR (AKIŞ/POSTS) -----------

  static String get _postBaseUrl => '$_baseUrl/api/posts';

  /// Tüm gönderileri getir
  static Future<List<Map<String, dynamic>>> fetchPosts() async {
    final resp = await http.get(Uri.parse(_postBaseUrl));
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      if (decoded is Map && decoded['posts'] is List) {
        return List<Map<String, dynamic>>.from(decoded['posts']);
      }
    }
    throw Exception('Gönderiler yüklenemedi');
  }

  /// Yeni paylaşım ekle
  static Future<bool> addPost({
    required int userId,
    String? text,
    String? imagePath,
  }) async {
    final body = {
      "user_id": userId,
      if (text != null) "text": text,
      if (imagePath != null) "image_path": imagePath,
    };
    final resp = await http.post(
      Uri.parse(_postBaseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return resp.statusCode == 201;
  }

  /// Paylaşımı beğen
  static Future<void> likePost(int postId, int userId) async {
    final resp = await http.post(
      Uri.parse('$_postBaseUrl/$postId/like'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"user_id": userId}),
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Beğeni hatası');
    }
  }

  /// Beğeniyi kaldır
  static Future<void> unlikePost(int postId, int userId) async {
    final resp = await http.post(
      Uri.parse('$_postBaseUrl/$postId/unlike'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"user_id": userId}),
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Beğeni kaldırma hatası');
    }
  }

  /// Beğenenleri getir
  static Future<List<Map<String, dynamic>>> fetchLikes(int postId) async {
    final resp = await http.get(Uri.parse('$_postBaseUrl/$postId/likes'));
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
    }
    throw Exception('Beğenenler yüklenemedi');
  }

  /// Yorumları getir
  static Future<List<Map<String, dynamic>>> fetchComments(int postId) async {
    final resp = await http.get(Uri.parse('$_postBaseUrl/$postId/comments'));
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
    }
    throw Exception('Yorumlar yüklenemedi');
  }

  /// Yorum ekle
  static Future<bool> addComment({
    required int postId,
    required int userId,
    required String text,
  }) async {
    final resp = await http.post(
      Uri.parse('$_postBaseUrl/$postId/comments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"user_id": userId, "text": text}),
    );
    return resp.statusCode == 201;
  }

  // ----------- AUTH / PROFILE -----------

  /// Kullanıcı girişi
  static Future<String> loginUser(String email, String password) async {
    final url = Uri.parse('$_baseUrl/api/account/login');
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(timeoutDuration);

    debugPrint('⚙️ loginUser → ${response.statusCode}: ${response.body}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['token'] != null) {
      return data['token'] as String;
    } else if (response.statusCode == 401) {
      // 👇 özel kontrol
      throw Exception("Kullanıcı adı veya şifre hatalı.");
    } else {
      throw Exception(
          data['message'] ?? 'Giriş başarısız (${response.statusCode})');
    }
  }

  /// Kayıt
  static Future<void> registerUser(Map<String, dynamic> userData) async {
    final url = Uri.parse('$_baseUrl/api/account/register');
    final payload = {
      'name': userData['name'],
      'email': userData['email'],
      'password': userData['password'],
      'confirm_password': userData['confirm_password'],
      'birthdate': userData['birthdate'],
      'birthplace': userData['birthplace'],
      'birthtime': userData['birthtime'],
      'phone': userData['phone'],
    };
    debugPrint('📤 registerUser payload → $payload');

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          body: jsonEncode(payload),
        )
        .timeout(timeoutDuration);

    debugPrint('⚙️ registerUser → ${response.statusCode}: ${response.body}');
    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Kayıt başarısız');
    }
  }

  // ----------- MESAJLAR -----------

  Future<List<Message>> fetchMessages(String token) async {
    final url = Uri.parse('$_baseUrl/api/messages');
    final response = await http.get(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((e) => Message.fromJson(e)).toList();
    }
    throw Exception('Mesajlar yüklenemedi (${response.statusCode})');
  }

  Future<List<Message>> fetchMessagesWithUser(
      String token, int currentUserId, int otherUserId) async {
    final allMessages = await fetchMessages(token);
    return allMessages.where((msg) {
      return (msg.senderId == currentUserId &&
              msg.receiverId == otherUserId) ||
          (msg.senderId == otherUserId && msg.receiverId == currentUserId);
    }).toList();
  }

  // ✅ Düzeltilmiş versiyon
  Future<void> deleteConversation(
      String token, int currentUserId, int otherUserId) async {
    final url = Uri.parse('$_baseUrl/api/messages/delete-conversation');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "user1": currentUserId,
        "user2": otherUserId,
      }),
    ).timeout(timeoutDuration);

    debugPrint("🗑 deleteConversation → ${response.statusCode} ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Sohbet silinemedi (${response.statusCode})');
    }
  }

  Future<void> deleteConversations(
      String token, int currentUserId, List<int> otherUserIds) async {
    for (final otherId in otherUserIds) {
      await deleteConversation(token, currentUserId, otherId);
    }
  }

  // ----------- FAVORİLER / HEDİYELER / PUANLAR -----------

  Future<List<Favorite>> fetchFavorites(String token) async {
    final url = Uri.parse('$_baseUrl/api/favoriler');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    ).timeout(timeoutDuration);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => Favorite.fromJson(e)).toList();
    }
    throw Exception('Favoriler yüklenemedi (${response.statusCode})');
  }

  Future<List<Gift>> fetchGifts(String token) async {
    final url = Uri.parse('$_baseUrl/api/hediyeler');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    ).timeout(timeoutDuration);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => Gift.fromJson(e)).toList();
    }
    throw Exception('Hediyeler yüklenemedi (${response.statusCode})');
  }

  Future<List<Score>> fetchScores(String token) async {
    final url = Uri.parse('$_baseUrl/api/puan');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    ).timeout(timeoutDuration);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => Score.fromJson(e)).toList();
    }
    throw Exception('Puanlar yüklenemedi (${response.statusCode})');
  }

  Future<List<NotificationModel>> fetchNotifications(String token) async {
    final url = Uri.parse('$_baseUrl/api/bildirimler');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    ).timeout(timeoutDuration);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => NotificationModel.fromJson(e)).toList();
    }
    throw Exception('Bildirimler yüklenemedi (${response.statusCode})');
  }

  // ----------- PROFİL -----------

  Future<Profile> fetchProfile(String token) async {
    final url = Uri.parse('$_baseUrl/api/account/profile');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    ).timeout(timeoutDuration);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return Profile.fromJson(data['profile'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? 'Profil bilgileri alınamadı');
  }

  // ----------- BURÇLAR -----------

  Future<List<ZodiacSign>> fetchZodiacSigns() async {
    final url = Uri.parse('$_baseUrl/api/burclar');
    final response = await http.get(url).timeout(timeoutDuration);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => ZodiacSign.fromJson(e)).toList();
    }
    throw Exception('Burçlar yüklenemedi (${response.statusCode})');
  }

  Future<List<Map<String, dynamic>>> fetchMatches() async {
    final url = Uri.parse('$_baseUrl/api/matches');
    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Eşleşmeler yüklenemedi: ${response.statusCode}');
    }
  }

  // ----------- MESAJ GÖNDERME -----------

  Future<void> sendMessage({
    required String token,
    required int senderId,
    required int receiverId,
    required String message,
  }) async {
    final url = Uri.parse('$_baseUrl/api/messages');
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'sender_id': senderId,
            'receiver_id': receiverId,
            'message': message,
          }),
        )
        .timeout(timeoutDuration);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final contentType = response.headers['content-type'];
      if (contentType != null && contentType.contains('application/json')) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Mesaj gönderilemedi');
      } else {
        throw Exception(
            'Mesaj gönderilemedi, sunucudan beklenmeyen yanıt alındı.');
      }
    }
  }

  // ----------- KULLANICI BURCU -----------

  Future<String?> fetchUserZodiac(String token, int userId) async {
    final url = Uri.parse('$_baseUrl/api/burclar/kullanici?userId=$userId');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['zodiac']?['name'] != null) {
        return data['zodiac']['name'] as String;
      }
      if (data['success'] == true && data['burc'] != null) {
        return data['burc'] as String;
      }
      if (data['name'] != null) {
        return data['name'] as String;
      }
    }
    return null;
  }

  // ----------- GÜNLÜK BURÇ YORUMU -----------

  Future<String?> fetchDailyHoroscope(String token, String zodiacName) async {
    final url = Uri.parse('$_baseUrl/api/western_horoscope');
    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'zodiac': zodiacName}),
        )
        .timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['horoscope'] != null) {
        return data['horoscope'] as String;
      } else {
        throw Exception(data['message'] ?? 'Günlük burç yorumu alınamadı');
      }
    } else {
      throw Exception('Günlük burç yorumu yüklenemedi (${response.statusCode})');
    }
  }

  Future<String?> fetchDailyHoroscopeFromHoroscopeApi(
      String zodiacName) async {
    final url = Uri.parse(
        'https://api.horoscopeapi.com/v1/horoscope/daily?sign=$zodiacName');
    final response = await http.get(
      url,
      headers: {
        'X-API-KEY': 'd78854d9f793028066acc300d64f988a98537025',
        'X-API-ID': '643228',
        'Accept': 'application/json',
      },
    ).timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('prediction')) {
        if (data['prediction'] is String) {
          return data['prediction'];
        } else if (data['prediction'] is Map &&
            data['prediction']['horoscope'] != null) {
          return data['prediction']['horoscope'];
        }
      } else if (data.containsKey('horoscope')) {
        return data['horoscope'];
      }
      return "Yorum bulunamadı.";
    } else {
      throw Exception(
          'Günlük burç yorumu API hatası (${response.statusCode})');
    }
  }
}
