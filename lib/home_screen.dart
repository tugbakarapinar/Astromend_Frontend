import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'models/zodiac_sign.dart';
import 'models/profile.dart';
import 'paylasimlar_screen.dart';
import 'message_list_screen.dart';
import 'natal_chart_screen.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import 'zodiac.dart';

// Ortak ikon fonksiyonu
String zodiacIconAsset(String zodiacName, {bool gold = false}) {
  final mapDefault = {
    "Koç": "aries",
    "Boğa": "taurus",
    "İkizler": "gemini",
    "Yengeç": "cancer",
    "Aslan": "leo",
    "Başak": "virgo",
    "Terazi": "libra",
    "Akrep": "scorpio",
    "Yay": "sagittarius",
    "Oğlak": "capricorn",
    "Kova": "aquarius",
    "Balık": "pisces",
  };
  final mapGold = {
    "Koç": "koc",
    "Boğa": "boga",
    "İkizler": "ikizler",
    "Yengeç": "yengec",
    "Aslan": "aslan",
    "Başak": "basak",
    "Terazi": "terazi1",
    "Akrep": "akrep",
    "Yay": "yay",
    "Oğlak": "oglak",
    "Kova": "kova",
    "Balık": "balik",
  };
  final fileName = gold
      ? (mapGold[zodiacName] ?? "koc")
      : (mapDefault[zodiacName] ?? "aries");
  return gold
      ? "assets/iconsgold/$fileName.png"
      : "assets/icons/$fileName.png";
}

String zodiacApiName(String turkishName) {
  final map = {
    "Koç": "aries",
    "Boğa": "taurus",
    "İkizler": "gemini",
    "Yengeç": "cancer",
    "Aslan": "leo",
    "Başak": "virgo",
    "Terazi": "libra",
    "Akrep": "scorpio",
    "Yay": "sagittarius",
    "Oğlak": "capricorn",
    "Kova": "aquarius",
    "Balık": "pisces",
  };
  return map[turkishName] ?? "aries";
}

class HomeScreen extends StatefulWidget {
  final String token;
  const HomeScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1;
  late Future<List<ZodiacSign>> _futureZodiac;
  late Future<Profile> _futureProfile;
  int? _currentUserId;
  String? userZodiac;
  String? userName;

  String? dailyHoroscope;
  String? fullHoroscope;

  bool showLoading = true;
  bool _profileLoaded = false;
  bool _dailyLoaded = false;

  @override
  void initState() {
    super.initState();
    final api = ApiService();
    _futureZodiac = api.fetchZodiacSigns();
    _futureProfile = api.fetchProfile(widget.token);

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && showLoading) setState(() => showLoading = false);
    });

    _futureProfile.then((profile) {
      setState(() {
        _currentUserId = profile.id;
        userName = profile.username;
        _profileLoaded = true;
      });
      api.fetchUserZodiac(widget.token, profile.id!).then((zodiac) {
        setState(() {
          userZodiac = zodiac;
        });
        if (zodiac != null && zodiac.isNotEmpty) {
          fetchDailyHoroscopeAstroApiV2(zodiac);
        } else {
          setState(() => _dailyLoaded = true);
          _tryCloseLoading();
        }
      });
    }).catchError((_) {
      setState(() {
        _profileLoaded = true;
        _dailyLoaded = true;
      });
      _tryCloseLoading();
    });
  }

  Future<void> fetchDailyHoroscopeAstroApiV2(String zodiacNameTR) async {
    try {
      final zodiacNameEN = zodiacApiName(zodiacNameTR);
      final String base = '643228:d78854d9f793028066acc300d64f988a98537025';
      final String basicAuth = 'Basic ${base64Encode(utf8.encode(base))}';
      final url = Uri.parse(
          'https://json.astrologyapi.com/v1/sun_sign_prediction/daily/$zodiacNameEN');
      final response = await http.post(
        url,
        headers: {
          'Authorization': basicAuth,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"timezone": 3.0}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? desc;
        if (data['prediction'] != null) {
          if (data['prediction']['general'] != null) {
            desc = data['prediction']['general'];
          } else if (data['prediction']['personal_life'] != null) {
            desc = data['prediction']['personal_life'];
          }
        }
        if (desc == null && data['general'] != null) {
          desc = data['general'];
        }

        if (desc != null && desc.isNotEmpty) {
          final translator = GoogleTranslator();
          var tr = await translator.translate(desc, from: 'en', to: 'tr');
          setState(() {
            fullHoroscope = tr.text;
            dailyHoroscope = (tr.text.length > 120)
                ? tr.text.substring(0, 120) + "..."
                : tr.text;
            _dailyLoaded = true;
          });
        } else {
          setState(() {
            fullHoroscope = "Günlük burç yorumu alınamadı.";
            dailyHoroscope = "Günlük burç yorumu alınamadı.";
            _dailyLoaded = true;
          });
        }
      } else {
        setState(() {
          fullHoroscope = "Günlük burç yorumu alınamadı.";
          dailyHoroscope = "Günlük burç yorumu alınamadı.";
          _dailyLoaded = true;
        });
      }
    } catch (e) {
      setState(() {
        fullHoroscope = "Günlük burç yorumuna ulaşılamadı.";
        dailyHoroscope = "Günlük burç yorumuna ulaşılamadı.";
        _dailyLoaded = true;
      });
    }
    _tryCloseLoading();
  }

  void _tryCloseLoading() {
    if (_profileLoaded && _dailyLoaded && showLoading) {
      setState(() => showLoading = false);
    }
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      backgroundColor: const Color(0xFFF7F3F7),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Padding(
                  padding: EdgeInsets.only(left: 4, top: 12, bottom: 2),
                  child: Text('Ayarlar',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.black)),
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.person, color: Color(0xFF504C52), size: 28),
                title: const Text('Profil', style: TextStyle(fontSize: 17)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(
                    context,
                    '/profile',
                    arguments: widget.token,
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.logout, color: Color(0xFF504C52), size: 28),
                title: const Text('Çıkış Yap', style: TextStyle(fontSize: 17)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Future.delayed(const Duration(milliseconds: 50));
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Çıkış Yap"),
                      content:
                          const Text("Çıkış yapmak istediğinize emin misiniz?"),
                      actions: [
                        TextButton(
                          child: const Text("Hayır"),
                          onPressed: () => Navigator.of(ctx).pop(false),
                        ),
                        TextButton(
                          child: const Text("Evet"),
                          onPressed: () => Navigator.of(ctx).pop(true),
                        ),
                      ],
                    ),
                  );
                  if (shouldLogout == true) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    Navigator.of(context, rootNavigator: true)
                        .pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: null,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0B0B0C), // çok koyu siyah
                    Color(0xFF12041D), // çok hafif mor dokunuş
                    Color(0xFF000000), // siyah
                  ],
                  stops: [0.0, 0.28, 1.0],
                ),
              ),
            ),
          ),
          IndexedStack(
            index: _currentIndex,
            children: <Widget>[
              ZodiacScreen(
                zodiacName: userZodiac ?? "Oğlak",
                fullHoroscope: fullHoroscope ?? "Burç yorumu yok.",
                token: widget.token,
              ),
              _buildHomeBody(),
              (_currentUserId == null || userName == null)
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Colors.white))
                  : PaylasimlarScreen(
                      userId: _currentUserId!, username: userName!),
              (_currentUserId == null)
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Colors.white))
                  : MessageListScreen(
                      currentUserId: _currentUserId!,
                      token: widget.token,
                    ),
            ],
          ),
          if (showLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.72),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      GoldLoadingAnimation(),
                      SizedBox(height: 18),
                      Text(
                        "Yükleniyor...",
                        style: TextStyle(
                          color: Color(0xFF44216A),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF44216A),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome, size: 28),
            label: 'Burçlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 28),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_stream, size: 28),
            label: 'Akış',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline, size: 26),
            label: 'Gelen Kutusu',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeBody() {
    return FutureBuilder<Profile>(
      future: _futureProfile,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snap.hasError || snap.data == null) {
          return const Center(
              child: Text("Profil bilgileri yüklenemedi.",
                  style: TextStyle(color: Colors.white)));
        }
        final profile = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(0),
          children: [
            Container(
              height: 300,
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 100, left: 20, right: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage:
                          const AssetImage("assets/images/profile_placeholder.png"),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hoşgeldiniz ve kullanıcı adı yan yana
                          Row(
                            children: [
                              const Text(
                                "Hoşgeldiniz, ",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              Flexible(
                                child: Text(
                                  profile.username,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            formatBirthDate(profile.birthDate),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                          if (userZodiac != null && userZodiac!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Row(
                                children: [
                                  Image.asset(
                                    zodiacIconAsset(userZodiac!),
                                    width: 22,
                                    height: 22,
                                    fit: BoxFit.contain,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      "$userZodiac",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      margin: const EdgeInsets.only(top: 140),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(1),
                        child: Image.asset('assets/images/chart2.png',
                            height: 120, width: 120, fit: BoxFit.cover),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (dailyHoroscope != null) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF816d90),
                        Color(0xFF12041D),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Günlük Burç Yorumunuz",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dailyHoroscope!.length > 120
                            ? dailyHoroscope!.substring(0, 120) + "..."
                            : dailyHoroscope!,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14, height: 1.4),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _currentIndex = 0;
                            });
                          },
                          child: const Text(
                            "Devamını Gör >>",
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Opacity(
                opacity: 0.7,
                child: _chartCard(
                  context: context,
                  title: 'Doğum Haritanı Oluştur',
                  imagePath: 'assets/images/chart.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NatalChartScreen(
                          profile: profile,
                          token: widget.token,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: 0.7,
                      child: _chartCard(
                        context: context,
                        title: 'Sinastri Haritası',
                        imagePath: 'assets/images/synastrychart.png',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Opacity(
                      opacity: 0.7,
                      child: _chartCard(
                        context: context,
                        title: 'Solar Return',
                        imagePath: 'assets/images/natal_chart_icon.png',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }

  Widget _chartCard({
    required BuildContext context,
    required String title,
    required String imagePath,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        width: 180,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF816d90),
              Color(0xFF12041D),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.7),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              backgroundImage: AssetImage(imagePath),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Doğum tarihi stringini güzel gösteren yardımcı
String formatBirthDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return "";
  try {
    final dt = DateTime.parse(dateStr);
    const aylar = [
      "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz",
      "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
    ];
    return "${dt.day} ${aylar[dt.month - 1]}, ${dt.year}";
  } catch (_) {
    return dateStr;
  }
}

// GOLD LOADING ANIMATION
class GoldLoadingAnimation extends StatefulWidget {
  const GoldLoadingAnimation({Key? key}) : super(key: key);

  @override
  State<GoldLoadingAnimation> createState() => _GoldLoadingAnimationState();
}

class _GoldLoadingAnimationState extends State<GoldLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 6.3,
          child: CustomPaint(
            painter: _GoldGlowPainter(),
            child: const SizedBox(
              width: 56,
              height: 56,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x77FFD96B),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromARGB(119, 255, 252, 242),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: SizedBox(width: 18, height: 18),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GoldGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2);
    final sweep = 2 * 3.1416 * 0.82;
    final paint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0x00FFD96B),
          Color(0xFFFFD96B),
          Color(0x33FFD96B),
          Color(0x00FFD96B),
        ],
        stops: [0.0, 0.8, 0.95, 1.0],
        startAngle: 0.0,
        endAngle: 6.283185 * 0.82,
        transform: GradientRotation(-0.6),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
