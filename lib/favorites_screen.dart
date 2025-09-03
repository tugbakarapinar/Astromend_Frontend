import 'package:flutter/material.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoriler'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Text(
          'Favoriler sayfası henüz hazır değil.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
