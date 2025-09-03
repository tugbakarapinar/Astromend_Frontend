import 'package:flutter/material.dart';
import 'activity_main_screen.dart';
import 'dashboard_screen.dart';
import 'message_list_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainBottomNavScreen extends StatefulWidget {
  final String token;
  final int currentUserId;

  const MainBottomNavScreen({
    super.key,
    required this.token,
    required this.currentUserId,
  });

  @override
  State<MainBottomNavScreen> createState() => _MainBottomNavScreenState();
}

class _MainBottomNavScreenState extends State<MainBottomNavScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      const ActivityMainScreen(),
      const DashboardScreen(),
      MessageListScreen(
        token: widget.token,
        currentUserId: widget.currentUserId,
      ),
      const NotificationScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 2
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF7059AE),
              child: const Icon(Icons.chat, color: Colors.white),
              onPressed: () {
                // 👇 buraya modal açma fonksiyonunu taşı
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) {
                    return Padding(
                      padding: MediaQuery.of(ctx).viewInsets,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        height: MediaQuery.of(ctx).size.height * 0.6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Yeni Sohbet",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              decoration: InputDecoration(
                                hintText: "Kullanıcı ara...",
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.grey.shade200,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (val) {
                                print("Arama: $val");
                              },
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: Center(
                                child: Text(
                                  "Kullanıcı listesi burada çıkacak",
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Panel'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Mesaj'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Bildirim'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }
}
