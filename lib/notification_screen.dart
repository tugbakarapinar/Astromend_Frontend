import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade100,
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 10, // örnek olarak 10 bildirim
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: const Icon(Icons.notifications, color: Colors.white),
              ),
              title: Text(
                'Bildirim Başlığı ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Bu, örnek bildirim mesajıdır. Bildirim ${index + 1} detayları burada yer alır.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Bildirime tıklandığında yapılacaklar
              },
            ),
          );
        },
      ),
    );
  }
}
