import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/verify_code_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/maps_screen.dart';
import 'screens/community_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruta Map Frontend',
      debugShowCheckedModeBanner: false, // Quita la bandera de DEBUG
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0), // Azul elegante
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0), // Azul para AppBar
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/verify-code': (context) => const VerifyCodeScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/maps': (context) => const MapsScreen(),
        '/community': (context) => const CommunityScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
