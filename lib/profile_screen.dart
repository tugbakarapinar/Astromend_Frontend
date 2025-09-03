import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'models/profile.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

final List<String> sehirler = [
  // ... [şehirler burada, değiştirme]
  'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya', 'Ankara', 'Antalya', 'Ardahan', 'Artvin', 'Aydın',
  'Balıkesir', 'Bartın', 'Batman', 'Bayburt', 'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı',
  'Çorum', 'Denizli', 'Diyarbakır', 'Düzce', 'Edirne', 'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun',
  'Gümüşhane', 'Hakkari', 'Hatay', 'Iğdır', 'Isparta', 'İstanbul', 'İzmir', 'Kahramanmaraş', 'Karabük', 'Karaman', 'Kars',
  'Kastamonu', 'Kayseri', 'Kırıkkale', 'Kırklareli', 'Kırşehir', 'Kilis', 'Kocaeli', 'Konya', 'Kütahya', 'Malatya', 'Manisa',
  'Mardin', 'Mersin', 'Muğla', 'Muş', 'Nevşehir', 'Niğde', 'Ordu', 'Osmaniye', 'Rize', 'Sakarya', 'Samsun', 'Siirt', 'Sinop',
  'Sivas', 'Şanlıurfa', 'Şırnak', 'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli', 'Uşak', 'Van', 'Yalova', 'Yozgat', 'Zonguldak'
];

class ProfileScreen extends StatefulWidget {
  final String? token;
  const ProfileScreen({Key? key, this.token}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  bool hasChanged = false;
  File? _profileImage; // yeni seçilmiş yerel görsel (oturum içi)
  String? _localAvatarPath; // kalıcı: son kaydedilen yerel görselin yolu
  Profile? _profile;
  bool _isLoading = true;
  bool _error = false;

  late TextEditingController phoneController;
  late TextEditingController birthDateController;
  late TextEditingController emailController;

  String? _selectedSehir;
  TimeOfDay? _selectedTime;

  // Hata mesajları
  String? errorBirthPlace;
  String? errorBirthTime;
  String? errorBirthDate;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _loadLocalAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _localAvatarPath = prefs.getString('local_avatar_path');
    });
  }

  Future<void> _saveLocalAvatarPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_avatar_path', path);
    setState(() {
      _localAvatarPath = path;
    });
  }

  Future<void> _clearLocalAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('local_avatar_path');
    setState(() {
      _localAvatarPath = null;
    });
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = false;
    });
    try {
      await _loadLocalAvatarPath(); // yerel avatar yolunu oku
      final prof = await ApiService().fetchProfile(widget.token!);
      _profile = prof;
      phoneController = TextEditingController(text: prof.phoneNumber ?? "");
      emailController = TextEditingController(text: prof.email);
      birthDateController = TextEditingController(text: _formatDate(prof.birthDate));
      _selectedSehir = prof.birthPlace;
      _selectedTime = _parseTimeOfDay(prof.birthTime);
      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = true;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? d) {
    if (d == null || d.isEmpty) return "";
    try {
      final dt = DateTime.parse(d);
      return DateFormat('dd.MM.yyyy').format(dt);
    } catch (_) {
      if (d.length >= 10) {
        final arr = d.substring(0, 10).split("-");
        if (arr.length == 3) return "${arr[2]}.${arr[1]}.${arr[0]}";
      }
      return d;
    }
  }

  // API'ye yyyy-MM-dd formatı göndermek için
  String _dateForApi(String? d) {
    if (d == null || d.isEmpty) return "";
    try {
      return DateFormat('yyyy-MM-dd').format(DateFormat('dd.MM.yyyy').parse(d));
    } catch (_) {
      return d;
    }
  }

  TimeOfDay? _parseTimeOfDay(String? t) {
    if (t == null || t.isEmpty) return null;
    try {
      final parts = t.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  String? _timeToString(TimeOfDay? t) =>
      t == null ? null : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatioPresets: [CropAspectRatioPreset.square],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Fotoğrafı Kırp',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(title: 'Fotoğrafı Kırp'),
      ],
    );
    if (cropped != null) {
      setState(() {
        _profileImage = File(cropped.path);
        hasChanged = true;
      });
    }
  }

  void _toggleEdit() {
    setState(() {
      isEditing = !isEditing;
      hasChanged = false;
      phoneController.text = _profile?.phoneNumber ?? "";
      emailController.text = _profile?.email ?? "";
      birthDateController.text = _formatDate(_profile?.birthDate);
      _selectedSehir = _profile?.birthPlace;
      _selectedTime = _parseTimeOfDay(_profile?.birthTime);
      _profileImage = null;
      errorBirthPlace = null;
      errorBirthTime = null;
      errorBirthDate = null;
    });
  }

  void _onChanged() {
    setState(() {
      hasChanged = true;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('tr', 'TR'),
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        birthDateController.text = DateFormat('dd.MM.yyyy').format(picked);
        hasChanged = true;
      });
    }
  }

  Future<void> _showSehirPicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Container(
          height: 390,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            itemCount: sehirler.length,
            separatorBuilder: (_, __) => Divider(height: 0, color: Colors.grey[200]),
            itemBuilder: (ctx, i) => ListTile(
              title: Text(sehirler[i], style: const TextStyle(fontSize: 17)),
              trailing: _selectedSehir == sehirler[i]
                  ? const Icon(Icons.check_circle, color: Colors.deepPurple)
                  : null,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedSehir = sehirler[i];
                  hasChanged = true;
                  errorBirthPlace = null;
                });
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTimePickerSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        TimeOfDay selected = _selectedTime ?? TimeOfDay(hour: 12, minute: 0);
        return Container(
          height: 270,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Saat seç", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Kapat", style: TextStyle(color: Colors.deepPurple, fontSize: 16)),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey[200]),
              Expanded(
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: Duration(hours: selected.hour, minutes: selected.minute),
                  minuteInterval: 1,
                  onTimerDurationChanged: (d) {
                    selected = TimeOfDay(hour: d.inHours, minute: d.inMinutes % 60);
                  },
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedTime = selected;
                      hasChanged = true;
                      errorBirthTime = null;
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 43),
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                  child: const Text("Seç", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  bool _validateForm() {
    bool valid = true;
    setState(() {
      errorBirthPlace = _selectedSehir == null || _selectedSehir!.isEmpty ? "Zorunlu" : null;
      errorBirthTime = _selectedTime == null ? "Zorunlu" : null;
      errorBirthDate = birthDateController.text.isEmpty ? "Zorunlu" : null;
      if (errorBirthPlace != null || errorBirthTime != null || errorBirthDate != null) valid = false;
    });
    return valid;
  }

  // GÜNCELLEME FONKSİYONU (API'ye güncel verileri yollar)
  Future<void> _saveProfile() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      // Profil güncelleme isteği (multipart)
      var uri = Uri.parse('https://api.astromend.com/api/account/profile');
      var request = http.MultipartRequest('PUT', uri);

      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.fields['phone'] = phoneController.text;
      request.fields['birthplace'] = _selectedSehir ?? "";
      request.fields['birthtime'] = _timeToString(_selectedTime) ?? "";
      request.fields['birthdate'] = _dateForApi(birthDateController.text);

      if (_profileImage != null) {
        request.files.add(await http.MultipartFile.fromPath('profile_image', _profileImage!.path));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        // Yerel avatar yolunu (varsa) persist et
        if (_profileImage != null) {
          await _saveLocalAvatarPath(_profileImage!.path);
        }
        // Başarıyla güncellendi, ekrana yansıtmak için tekrar çek
        await _fetchProfile();
        setState(() {
          isEditing = false;
          hasChanged = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil başarıyla güncellendi!")),
        );
      } else {
        throw Exception("Sunucu hatası: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Aşağısı tamamen UI fonksiyonların ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error || _profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profil")),
        body: const Center(child: Text("Profil bilgileri alınamadı.")),
      );
    }

    // Avatar provider seçimi:
    ImageProvider avatarProvider;
    if (_profileImage != null) {
      avatarProvider = FileImage(_profileImage!);
    } else if (_localAvatarPath != null && _localAvatarPath!.isNotEmpty && File(_localAvatarPath!).existsSync()) {
      avatarProvider = FileImage(File(_localAvatarPath!));
    } else {
      // Sunucudan URL varsa burada kullanmak isterdin;
      // Profile modelinde alan adı bilinmediği için compile-safe yol: placeholder
      avatarProvider = const AssetImage('assets/images/profile_placeholder.png');
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white), // geri butonu beyaz
        title: const Text("Profil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: isEditing
                ? (hasChanged ? _saveProfile : _toggleEdit)
                : _toggleEdit,
            child: Text(
              isEditing
                  ? (hasChanged ? "Kaydet" : "İptal")
                  : "Düzenle",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ✅ Diğer ekranlarla aynı degrade arka plan
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0B0B0C), // koyu siyah
                  Color(0xFF2A0A3D), // mor ton (çok hafif)
                  Color(0xFF000000), // siyah
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(24, 75, 24, 18),
            children: [
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 58,
                      backgroundImage: avatarProvider,
                    ),
                    if (isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.deepPurple.withOpacity(0.92),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.edit, color: Colors.white, size: 23),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              Center(
                child: Text(
                  _profile?.username ?? "",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 18),
              _labeledField("E-posta", emailController, enabled: false, isMail: true),
              const SizedBox(height: 13),
              _labeledField("Telefon Numarası", phoneController, enabled: isEditing, isRequired: false, onChanged: (_) => _onChanged()),
              const SizedBox(height: 13),
              _sehirSheetField(
                label: "Doğum Yeri",
                value: _selectedSehir,
                enabled: isEditing,
                onTap: isEditing ? _showSehirPicker : null,
                errorText: errorBirthPlace,
              ),
              const SizedBox(height: 13),
              _timeSheetField(
                label: "Doğum Saati",
                value: _selectedTime,
                enabled: isEditing,
                onTap: isEditing ? _showTimePickerSheet : null,
                errorText: errorBirthTime,
              ),
              const SizedBox(height: 13),
              _dateField(
                label: "Doğum Tarihi",
                controller: birthDateController,
                enabled: isEditing,
                onTap: isEditing ? _pickDate : null,
                errorText: errorBirthDate,
                onChanged: (_) => _onChanged(),
              ),
              const SizedBox(height: 32),
              if (!isEditing)
                Center(
                  child: Opacity(
                    opacity: 0.80,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, size: 22, color: Colors.white),
                      label: const Text(
                        "Çıkış Yap",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.10),
                        side: const BorderSide(color: Colors.white, width: 1.3),
                        minimumSize: const Size(180, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Çıkış Yap'),
                            content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Hayır'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Evet'),
                              ),
                            ],
                          ),
                        );
                        if (shouldLogout == true) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      },
                    ),
                  ),
                ),
              if (isEditing)
                Center(
                  child: ElevatedButton(
                    onPressed: hasChanged ? _saveProfile : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(170, 47),
                      backgroundColor: hasChanged ? Colors.deepPurple : Colors.grey[400],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("Kaydet", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                ),
              const SizedBox(height: 9),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labeledField(
    String label,
    TextEditingController controller, {
    bool enabled = false,
    ValueChanged<String>? onChanged,
    bool isRequired = true,
    bool isMail = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14.5, color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TextField(
              controller: controller,
              enabled: enabled,
              onChanged: onChanged,
              keyboardType: isMail ? TextInputType.emailAddress : TextInputType.text,
              style: TextStyle(
                fontSize: 17,
                color: enabled ? Colors.black : Colors.black87,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: enabled ? Colors.white : Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
                disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
                hintText: enabled ? label : null,
                hintStyle: TextStyle(color: Colors.grey[500]),
              ),
            ),
            if (enabled && !isMail)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(Icons.edit, size: 20, color: Colors.deepPurple.withOpacity(0.85)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _sehirSheetField({
    required String label,
    required String? value,
    required bool enabled,
    required VoidCallback? onTap,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14.5, color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: AbsorbPointer(
            absorbing: true,
            child: Container(
              decoration: BoxDecoration(
                color: enabled ? Colors.white : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(13),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? '',
                      style: TextStyle(
                        fontSize: 17,
                        color: enabled ? Colors.black : Colors.black87,
                      ),
                    ),
                  ),
                  if (enabled)
                    Icon(Icons.edit_location_alt_rounded, color: Colors.deepPurple, size: 22)
                ],
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 3),
            child: Text(errorText, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
      ],
    );
  }

  Widget _timeSheetField({
    required String label,
    required TimeOfDay? value,
    required bool enabled,
    required VoidCallback? onTap,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14.5, color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: AbsorbPointer(
            absorbing: true,
            child: Container(
              decoration: BoxDecoration(
                color: enabled ? Colors.white : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(13),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value != null
                          ? '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}'
                          : '',
                      style: TextStyle(
                        fontSize: 17,
                        color: enabled ? Colors.black : Colors.black87,
                      ),
                    ),
                  ),
                  if (enabled)
                    Icon(Icons.edit, color: Colors.deepPurple, size: 21)
                ],
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 3),
            child: Text(errorText, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    VoidCallback? onTap,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14.5, color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: AbsorbPointer(
            absorbing: true,
            child: Container(
              decoration: BoxDecoration(
                color: enabled ? Colors.white : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(13),
              ),
              child: TextField(
                controller: controller,
                enabled: enabled,
                onChanged: onChanged,
                style: TextStyle(
                  fontSize: 17,
                  color: enabled ? Colors.black : Colors.black87,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
                  hintText: enabled ? "GG.AA.YYYY" : null,
                  hintStyle: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 3),
            child: Text(errorText, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
      ],
    );
  }
}
