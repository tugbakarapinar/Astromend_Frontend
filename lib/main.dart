import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Ekranlar
import 'intro.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'favorites_screen.dart';
import 'gifts_screen.dart';
import 'scores_screen.dart';
import 'messages_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AstroMend',
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr', 'TR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR')],
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      // 🔥 Artık intro ekranla başlıyor!
      initialRoute: '/',
      routes: {
        '/': (ctx) => const IntroScreen(),           // 👈 Uygulama açılışta buraya gider
        '/login': (ctx) => const LoginScreen(),
        '/register': (ctx) => const RegisterScreen(),
        '/home': (ctx) {
          final token = ModalRoute.of(ctx)!.settings.arguments as String;
          return HomeScreen(token: token);
        },
        '/profile': (ctx) {
          final token = ModalRoute.of(ctx)!.settings.arguments as String;
          return ProfileScreen(token: token);
        },
        '/favorites': (ctx) => const FavoritesScreen(),
        '/gifts': (ctx) => const GiftsScreen(),
        '/scores': (ctx) => const ScoresScreen(),
        '/messages': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
          return MessagesScreen(
            currentUserId: args['currentUserId'],
            receiverId: args['receiverId'],
            receiverName: args['receiverName'],
            token: args['token'],
          );
        },
      },
    );
  }
}
