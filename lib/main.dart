import 'package:flutter/material.dart';
import 'firebase/firebase_bootstrap.dart';
import 'features/auth/login_screen.dart';
import 'features/feed/feed_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/guilds/guilds_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  runApp(const AscendiaApp());
}

class AscendiaApp extends StatelessWidget {
  const AscendiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ascendia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: Colors.deepPurple, brightness: Brightness.dark),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/feed': (_) => const FeedScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/guilds': (_) => const GuildsScreen(),
      },
    );
  }
}
