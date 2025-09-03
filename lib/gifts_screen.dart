import 'package:flutter/material.dart';

class GiftsScreen extends StatelessWidget {
  const GiftsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hediyeler'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text(
          'Hediyeler sayfası henüz hazır değil.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
