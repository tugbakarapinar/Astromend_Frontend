import 'dart:math';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'models/profile.dart';

final Map<String, String> planetTR = { /* ... (Aynı) ... */ };
final Map<String, String> signTR = { /* ... (Aynı) ... */ };
final Map<String, String> signAssets = { /* ... (Aynı) ... */ };

class NatalChartScreen extends StatefulWidget {
  final Profile profile;
  final String token;

  const NatalChartScreen({
    Key? key,
    required this.profile,
    required this.token,
  }) : super(key: key);

  @override
  State<NatalChartScreen> createState() => _NatalChartScreenState();
}

class _NatalChartScreenState extends State<NatalChartScreen> with TickerProviderStateMixin {
  List<_StarData>? stars;
  final int starCount = 23;
  final Random random = Random();

  bool isLoading = true;
  String? errorMessage;
  String? chartUrl;
  List<dynamic> planets = [];

  @override
  void initState() {
    super.initState();
    stars = List.generate(starCount, (_) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1200 + random.nextInt(2000)),
      )..repeat(reverse: true);
      return _StarData(
        controller: controller,
        x: random.nextDouble(),
        y: random.nextDouble() * 0.95,
        size: 1.5 + random.nextDouble() * 2.5,
      );
    });
    fetchAll();
  }

  Future<void> fetchAll() async {
    try {
      final dateStr = (widget.profile.birthDate ?? "2000-01-01").split('T')[0];
      final timeStr = (widget.profile.birthTime ?? "12:00");
      final birthPlace = widget.profile.birthPlace ?? "İstanbul";
      final dateParts = dateStr.split('-');
      final timeParts = timeStr.split(':');
      int year = int.tryParse(dateParts[0]) ?? 2000;
      int month = int.tryParse(dateParts[1]) ?? 1;
      int day = int.tryParse(dateParts[2]) ?? 1;
      int hour = int.tryParse(timeParts[0]) ?? 12;
      int min = int.tryParse(timeParts.length > 1 ? timeParts[1] : "0") ?? 0;
      double tzone = 3.0;
      double lat = 41.0082, lon = 28.9784;
      try {
        List<Location> locations = await locationFromAddress("$birthPlace, Türkiye");
        if (locations.isNotEmpty) {
          lat = locations[0].latitude;
          lon = locations[0].longitude;
        }
      } catch (_) {}
      const userId = "643181";
      const apiKey = "d6d72b3ce00b7d4bf8f87aea2e616feb76411f23";
      final basicAuth = 'Basic ' + base64Encode(utf8.encode('$userId:$apiKey'));

      // Harita
      final chartResponse = await http.post(
        Uri.parse("https://json.astrologyapi.com/v1/natal_wheel_chart"),
        headers: {
          "Authorization": basicAuth,
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "day": day, "month": month, "year": year,
          "hour": hour, "min": min,
          "lat": lat, "lon": lon, "tzone": tzone
        }),
      );
      String? chartUrl;
      if (chartResponse.statusCode == 200) {
        final body = jsonDecode(chartResponse.body);
        chartUrl = body["chart_url"];
      }

      // Gezegenler
      final planetsResponse = await http.post(
        Uri.parse("https://json.astrologyapi.com/v1/planets"),
        headers: {
          "Authorization": basicAuth,
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "day": day, "month": month, "year": year,
          "hour": hour, "min": min,
          "lat": lat, "lon": lon, "tzone": tzone
        }),
      );
      List<dynamic> fetchedPlanets = [];
      if (planetsResponse.statusCode == 200) {
        fetchedPlanets = jsonDecode(planetsResponse.body);
      }

      setState(() {
        isLoading = false;
        this.chartUrl = chartUrl;
        this.planets = fetchedPlanets;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Bir hata oluştu: $e";
      });
    }
  }

  @override
  void dispose() {
    stars?.forEach((s) => s.controller.dispose());
    super.dispose();
  }

  Widget buildChartVisual(String? url) {
    if (url == null) {
      return const Center(
        child: Text(
          "Doğum haritası görseli bulunamadı",
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    if (url.endsWith(".svg")) {
      return SvgPicture.network(
        url,
        width: 340,
        height: 340,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => const GoldLoadingAnimation(),
      );
    }
    return Image.network(
      url,
      width: 340,
      height: 340,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Text("Harita görseli yüklenemedi"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0736),
      body: Stack(
        children: [
          if (stars != null)
            Positioned.fill(
              child: Stack(
                children: stars!
                    .map((star) => AnimatedBuilder(
                          animation: star.controller,
                          builder: (ctx, _) {
                            final size = MediaQuery.of(ctx).size;
                            return Positioned(
                              left: star.x * size.width,
                              top: star.y * size.height,
                              child: Opacity(
                                opacity: 0.4 + 0.6 * star.controller.value,
                                child: Container(
                                  width: star.size,
                                  height: star.size,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.32),
                                        blurRadius: 5,
                                        spreadRadius: 0.3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ))
                    .toList(),
              ),
            ),

          SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Üst bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                            (route) => false,
                            arguments: widget.token,
                          );
                        },
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                const SizedBox(height: 4),
                Center(
                  child: Text(
                    "Doğum Haritası",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Yükleniyor / hata / içerik
                if (isLoading)
                  const Center(child: GoldLoadingAnimation())
                else if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 18),
                      ),
                    ),
                  )
                else ...[
                  // Harita: sadece zoom
                  Center(
                    child: InteractiveViewer(
                      panEnabled: false,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: buildChartVisual(chartUrl),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tablo container
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.48,
                          ),
                          child: buildNatalChartTable(planets),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Tablo widget'ı ---
Widget buildNatalChartTable(List planets) {
  return DataTable(
    columnSpacing: 28,
    headingRowHeight: 42,
    dataRowHeight: 38,
    border: TableBorder.all(
      color: Colors.black87,
      width: 0.7,
    ),
    columns: [
      DataColumn(label: Text("Gezegen", style: TextStyle(color: Color(0xFFFFB300)))),
      DataColumn(label: Text("Burç", style: TextStyle(color: Color(0xFFFFB300)))),
      DataColumn(label: Text("Ev", style: TextStyle(color: Color(0xFFFFB300)))),
      DataColumn(label: Text("Poz.", style: TextStyle(color: Color(0xFFFFB300))), numeric: true),
    ],
    rows: planets.map<DataRow>((p) {
      final planetName = planetTR[p['name']] ?? p['name'] ?? "-";
      final sign = signTR[p['sign']] ?? p['sign'] ?? "-";
      final iconPath = signAssets[sign] ?? "";
      return DataRow(cells: [
        DataCell(Text(planetName, style: TextStyle(color: Colors.black))),
        DataCell(Row(children: [
          if (iconPath.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Image.asset(iconPath, width: 20, height: 20),
            ),
          Text(sign, style: TextStyle(color: Colors.black)),
        ])),
        DataCell(Text(p['house'].toString(), style: TextStyle(color: Colors.black))),
        DataCell(Text(
          p['normDegree'] != null
              ? double.parse(p['normDegree'].toString()).toStringAsFixed(2)
              : "-",
          style: TextStyle(color: Colors.black),
        )),
      ]);
    }).toList(),
  );
}

// ---- Parlayan Yıldız Modeli ----
class _StarData {
  final AnimationController controller;
  final double x;
  final double y;
  final double size;
  _StarData({
    required this.controller,
    required this.x,
    required this.y,
    required this.size,
  });
}

// ---- Gold Yükleniyor Animasyonu ----
class GoldLoadingAnimation extends StatefulWidget {
  const GoldLoadingAnimation({Key? key}) : super(key: key);

  @override
  State<GoldLoadingAnimation> createState() => _GoldLoadingAnimationState();
}

class _GoldLoadingAnimationState extends State<GoldLoadingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
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
      builder: (ctx, _) {
        return Transform.rotate(
          angle: _controller.value * 6.3,
          child: CustomPaint(
            painter: _GoldGlowPainter(),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFD96B),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x77FFD96B),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ],
                  ),
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
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2);
    final sweep = 2 * 3.1416 * 0.82;
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          const Color(0xFFFFD96B).withOpacity(0.0),
          const Color(0xFFFFD96B),
          const Color(0xFFFFD96B).withOpacity(0.2),
          const Color(0x00FFD96B),
        ],
        stops: const [0.0, 0.8, 0.95, 1.0],
        startAngle: 0.0,
        endAngle: sweep,
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
