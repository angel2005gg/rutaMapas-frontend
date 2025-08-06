import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; // ✅ NUEVO IMPORT
import 'screens/login_screen.dart';
import 'screens/verify_code_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/comunidades/comunidades_screen.dart';
import 'screens/comunidades/crear_comunidad_screen.dart';
import 'screens/comunidades/unirse_comunidad_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapas Rutas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // ✅ CAMBIO: Iniciar con splash en lugar de login
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(), // ✅ NUEVA RUTA INICIAL
        '/login': (context) => const LoginScreen(),
        '/verify-code': (context) => const VerifyCodeScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/comunidades': (context) => const ComunidadesScreen(),
        '/crear-comunidad': (context) => const CrearComunidadScreen(),
        '/unirse-comunidad': (context) => const UnirseComunidadScreen(),
      },
    );
  }
}
