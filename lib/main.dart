import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/verify_code_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/comunidades/comunidades_screen.dart';
import 'screens/comunidades/crear_comunidad_screen.dart';
import 'screens/comunidades/unirse_comunidad_screen.dart';
import 'screens/comunidades/ajustes_competencia_screen.dart';
import 'screens/comunidades/historial_competencias_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'widgets/winner_dialog.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.requestPermission();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/verify-code': (context) => const VerifyCodeScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/comunidades': (context) => const ComunidadesScreen(),
        '/crear-comunidad': (context) => const CrearComunidadScreen(),
        '/unirse-comunidad': (context) => const UnirseComunidadScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/ajustes-competencia') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => AjustesCompetenciaScreen(
              comunidadId: args?['comunidadId'] as int,
              duracionInicial: (args?['duracionInicial'] as int?) ?? 7,
            ),
          );
        }
        if (settings.name == '/historial-competencias') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => HistorialCompetenciasScreen(
              comunidadId: args?['comunidadId'] as int,
            ),
          );
        }
        return null;
      },
      builder: (context, child) {
        // Listener de mensajes en foreground
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final data = message.data;
          if ((data['type'] ?? data['evento']) == 'competencia_cerrada') {
            final nombre = data['ganador_nombre']?.toString() ?? 'Usuario ganador';
            final puntos = int.tryParse(data['ganador_puntos']?.toString() ?? '') ?? 0;
            showWinnerDialog(context, nombre: nombre, puntos: puntos);
          }
        });
        return child!;
      },
    );
  }
}
