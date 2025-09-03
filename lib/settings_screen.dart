import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'change_password_screen.dart'; // BU SATIRI SİL

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Çıkış işlemi
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayarlar"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          _buildSettingsSectionTitle("HESAP"),
          _buildSettingsTile(Icons.person, "Profil Bilgileri", () {}),
          _buildSettingsTile(Icons.lock, "Şifreyi Değiştir", () {
            // Buraya ileri tarihte şifre ekranı ekleyeceksin
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bu özellik yakında eklenecek.')),
            );
          }),
          _buildSettingsTile(Icons.phone_android, "Telefon Numarası", () {}),

          const Divider(height: 32),

          _buildSettingsSectionTitle("UYGULAMA"),
          _buildSettingsTile(Icons.notifications, "Bildirim Ayarları", () {}),
          _buildSettingsTile(Icons.privacy_tip, "Gizlilik Politikası", () {}),
          _buildSettingsTile(Icons.info_outline, "Hakkında", () {}),

          const Divider(height: 32),

          _buildSettingsSectionTitle("DİĞER"),
          _buildSettingsTile(Icons.logout, "Çıkış Yap", () {
            _logout(context);
          }),
        ],
      ),
    );
  }

  Widget _buildSettingsSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: icon == Icons.logout ? Colors.red : Colors.blue),
      title: Text(
        title,
        style: TextStyle(
          color: icon == Icons.logout ? Colors.red : Colors.black,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
