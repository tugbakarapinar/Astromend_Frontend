import 'package:flutter/material.dart';

class ScoresScreen extends StatelessWidget {
  const ScoresScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puanlar'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text(
          'Puanlar sayfası henüz hazır değil.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
