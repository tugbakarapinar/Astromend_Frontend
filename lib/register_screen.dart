import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool agreed = false, _loading = false;
  String fullName = '', email = '', password = '', confirmPassword = '';
  String birthDate = '', birthPlace = '', birthTime = '', phone = '';
  bool hasUpper = false, hasLower = false, hasSpecial = false, hasMin = false;
  bool emailTaken = false, phoneTaken = false;
  bool _showPasswordRules = false;

  final List<String> _cities = [
    "Adana","Adıyaman","Afyonkarahisar","Ağrı","Amasya","Ankara","Antalya","Artvin","Aydın",
    "Balıkesir","Bilecik","Bingöl","Bitlis","Bolu","Burdur","Bursa","Çanakkale","Çankırı","Çorum",
    "Denizli","Diyarbakır","Edirne","Elazığ","Erzincan","Erzurum","Eskişehir","Gaziantep","Giresun",
    "Gümüşhane","Hakkari","Hatay","Isparta","Mersin","İstanbul","İzmir","Kars","Kastamonu","Kayseri",
    "Kırklareli","Kırşehir","Kocaeli","Konya","Kütahya","Malatya","Manisa","Kahramanmaraş","Mardin",
    "Muğla","Muş","Nevşehir","Niğde","Ordu","Rize","Sakarya","Samsun","Siirt","Sinop","Sivas",
    "Tekirdağ","Tokat","Trabzon","Tunceli","Şanlıurfa","Uşak","Van","Yozgat","Zonguldak","Aksaray",
    "Bayburt","Karaman","Kırıkkale","Batman","Şırnak","Bartın","Ardahan","Iğdır","Yalova","Karabük",
    "Kilis","Osmaniye","Düzce"
  ];

  TextEditingController _birthTimeController = TextEditingController();
  TextEditingController _birthPlaceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate() || !agreed) {
      if (!agreed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kullanıcı sözleşmesini onaylamalısınız.")),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiService.registerUser({
        'name': fullName,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        'birthdate': birthDate,
        'birthplace': birthPlace,
        'birthtime': birthTime,
        'phone': phone,
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Başarılı'),
          content: const Text('Kayıt tamamlandı.'),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      setState(() {
        emailTaken = msg.contains('e-posta') || msg.contains('email');
        phoneTaken = msg.contains('telefon') || msg.contains('phone');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${e.toString().replaceFirst('Exception: ', '')}")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void checkPassword(String v) {
    setState(() {
      password = v;
      hasUpper = v.contains(RegExp(r'[A-Z]'));
      hasLower = v.contains(RegExp(r'[a-z]'));
      hasSpecial = v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
      hasMin = v.length >= 8;
    });
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      locale: const Locale('tr', 'TR'),
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() {
        birthDate = DateFormat('yyyy-MM-dd').format(d);
      });
    }
  }

  Future<void> pickTimeCupertino() async {
    FocusScope.of(context).unfocus();
    TimeOfDay? pickedTime;
    await showModalBottomSheet(
      context: context,
      builder: (_) {
        TimeOfDay tempTime = TimeOfDay.now();
        return Container(
          height: 250,
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime.now(),
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime value) {
                    tempTime = TimeOfDay(hour: value.hour, minute: value.minute);
                  },
                ),
              ),
              TextButton(
                child: const Text('Seç'),
                onPressed: () {
                  pickedTime = tempTime;
                  Navigator.of(context).pop();
                },
              )
            ],
          ),
        );
      },
    );
    if (pickedTime != null) {
      setState(() {
        birthTime = pickedTime!.format(context);
        _birthTimeController.text = birthTime;
      });
    }
  }

  Future<void> pickCityBottomSheet() async {
    FocusScope.of(context).unfocus();
    String filter = "";
    List<String> filteredCities = _cities;
    String? selected;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.5,
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: "Şehir ara",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        filter = val;
                        filteredCities = _cities
                            .where((c) => c.toLowerCase().contains(filter.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCities.length,
                      itemBuilder: (context, i) => ListTile(
                        title: Text(filteredCities[i]),
                        onTap: () {
                          selected = filteredCities[i];
                          Navigator.pop(context, selected);
                        },
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    ).then((val) {
      if (val != null) {
        setState(() {
          birthPlace = val;
          _birthPlaceController.text = val;
        });
      }
    });
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 🔹 Gradient Arka plan
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0B0B0C), // siyah
                    Color(0xFF2A0A3D), // morumsu koyu ton
                    Color(0xFF000000), // siyah
                  ],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 64),
                Image.asset('assets/images/astromend_logo.png', height: 250),
                const SizedBox(height: 8),
                const Text(
                  "Kayıt Ol",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _field("Ad Soyad *", "Adınızı giriniz", onChanged: (v) => fullName = v),
                      const SizedBox(height: 10),
                      _field(
                        "E-posta *",
                        "example@mail.com",
                        inputType: TextInputType.emailAddress,
                        onChanged: (v) {
                          email = v;
                          emailTaken = false;
                        },
                        errorText: emailTaken ? 'Bu e-posta adresi zaten kayıtlıdır.' : null,
                      ),
                      const SizedBox(height: 10),
                      Focus(
                        onFocusChange: (focused) {
                          setState(() {
                            _showPasswordRules = focused;
                          });
                        },
                        child: _field(
                          "Şifre *",
                          "Şifrenizi giriniz",
                          obscure: true,
                          onChanged: checkPassword,
                        ),
                      ),
                      if (_showPasswordRules) ...[
                        const SizedBox(height: 4),
                        _rule("Büyük harf", hasUpper),
                        _rule("Küçük harf", hasLower),
                        _rule("Özel karakter", hasSpecial),
                        _rule("8+ karakter", hasMin),
                      ],
                      const SizedBox(height: 10),
                      _field(
                        "Şifre Tekrarı *",
                        "Tekrar giriniz",
                        obscure: true,
                        onChanged: (v) => confirmPassword = v,
                        validator: (v) => v == password ? null : 'Girilen şifreler eşleşmiyor.',
                      ),
                      const SizedBox(height: 10),

                      // Doğum Tarihi
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Doğum Tarihi *",
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: pickDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: TextEditingController(text: birthDate),
                            decoration: InputDecoration(
                              hintText: "GG/AA/YYYY",
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.7),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Bu alanın doldurulması zorunludur' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Doğum Yeri
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Doğum Yeriniz *",
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9))),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: pickCityBottomSheet,
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _birthPlaceController..text = birthPlace,
                            decoration: InputDecoration(
                              hintText: "Şehir seçiniz *",
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.7),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Bu alanın doldurulması zorunludur' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Doğum Saati
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Doğum Saatiniz *",
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9))),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: pickTimeCupertino,
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _birthTimeController..text = birthTime,
                            decoration: InputDecoration(
                              hintText: "Ör: 23:45",
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.7),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Bu alanın doldurulması zorunludur' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Telefon
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Telefon Numarası ",
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9))),
                      ),
                      const SizedBox(height: 4),
                      IntlPhoneField(
                        decoration: InputDecoration(
                          hintText: "5XX XXX XX XX",
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.7),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          errorText: phoneTaken ? 'Bu cep numarası zaten kayıtlıdır.' : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        ),
                        initialCountryCode: 'TR',
                        onChanged: (p) {
                          phone = p.completeNumber;
                          phoneTaken = false;
                        },
                      ),

                      Row(
                        children: [
                          Checkbox(
                            value: agreed,
                            onChanged: (v) => setState(() => agreed = v!),
                            activeColor: Colors.deepPurple,
                          ),
                          Expanded(
                            child: Text(
                              "Sözleşmeyi okudum, onaylıyorum.",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loading ? null : registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 247, 247, 248),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Kayıt Ol!', style: TextStyle(color: Color.fromARGB(255, 41, 11, 50))),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    String hint, {
    bool obscure = false,
    TextInputType? inputType,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    String? errorText,
  }) {
    Color labelColor = Colors.white.withOpacity(0.92);
    Color hintColor = Colors.black.withOpacity(0.44);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: labelColor)),
        const SizedBox(height: 6),
        TextFormField(
          obscureText: obscure,
          keyboardType: inputType,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            filled: true,
            fillColor: Colors.white.withOpacity(0.7),
            hintStyle: TextStyle(color: hintColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          ),
          validator: validator ?? (v) => v == null || v.isEmpty ? 'Bu alanın doldurulması zorunludur' : null,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _rule(String text, bool ok) {
    return Row(
      children: [
        Icon(ok ? Icons.check : Icons.close, color: ok ? Colors.green : Colors.red, size: 18),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.white)),
      ],
    );
  }
}
