import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  late AnimationController _textController;
  late Animation<double> _textFade;
  bool showButtons = false;
  bool isVideoReady = false;

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset("assets/videos/intro.mp4")
      ..initialize().then((_) {
        _videoController!.setLooping(true);
        _videoController!.setVolume(0);
        _videoController!.play();
        setState(() {
          isVideoReady = true;
        });
      }).catchError((e) {
        print("❌ Video yüklenemedi: $e");
      });

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeIn);
    _textController.forward();

    Timer(const Duration(seconds: 3), () {
      setState(() {
        showButtons = true;
      });
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isVideoReady
          ? Stack(
              children: [
                // Video arka plan
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                ),
                // GÖLGE
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.78),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Center(
                          child: Image.asset(
                            'assets/images/astromend_logo.png',
                            width: 180,
                            height: 180,
                          ),
                        ),
                        const SizedBox(height: 100),

                        FadeTransition(
                          opacity: _textFade,
                          child: Column(
                            children: [
                              Text(
                                "Astromend Dünyasına Hoşgeldin!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 100,
                                      color: Colors.white.withOpacity(0.99),
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),

                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 65, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Text(
                                  "Kayıt Ol",
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        if (showButtons) ...[
                          Text(
                            "Zaten hesabın var mı?",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 10),

                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              "Giriş Yap",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            ),
    );
  }
}

