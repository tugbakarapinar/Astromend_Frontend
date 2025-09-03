import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Ortak ikon asset fonksiyonu
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

class ZodiacScreen extends StatefulWidget {
  final String zodiacName;
  final String fullHoroscope;
  final String token;

  const ZodiacScreen({
    Key? key,
    required this.zodiacName,
    required this.fullHoroscope,
    required this.token,
  }) : super(key: key);

  @override
  _ZodiacScreenState createState() => _ZodiacScreenState();
}

class _ZodiacScreenState extends State<ZodiacScreen> {
  bool _dailySelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔹 Gradient arka plan
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0B0B0C), // siyah
                    Color(0xFF2A0A3D), // morumsu
                    Color(0xFF000000), // siyah
                  ],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    // Geri butonu
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (route) => false,
                          arguments: widget.token,
                        );
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.zodiacName,
                          style: GoogleFonts.pacifico(
                            fontSize: 28,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),

                const SizedBox(height: 20),

                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                            stops: const [0.3, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.7),
                              spreadRadius: 12,
                              blurRadius: 30,
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        zodiacIconAsset(widget.zodiacName, gold: true),
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Günlük / Aylık butonları
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor:
                            _dailySelected ? Colors.white : Colors.white24,
                        foregroundColor:
                            _dailySelected ? Colors.black : Colors.white70,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _dailySelected = true;
                        });
                      },
                      child: const Text('Günlük'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor:
                            !_dailySelected ? Colors.white : Colors.white24,
                        foregroundColor:
                            !_dailySelected ? Colors.black : Colors.white70,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _dailySelected = false;
                        });
                      },
                      child: const Text('Aylık'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      _dailySelected
                          ? widget.fullHoroscope
                          : 'Aylık yorumlarınız burada görünecek',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
