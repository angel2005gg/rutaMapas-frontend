import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // ✅ Esperar un momento para mostrar splash
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      // ✅ Verificar si hay token y usuario válido
      final user = await _authService.getCurrentUser();
      
      if (mounted) {
        if (user != null && user['status'] == 'success') {
          // ✅ HAY SESIÓN VÁLIDA - IR DIRECTO AL DASHBOARD
          print('✅ Sesión válida encontrada, navegando al dashboard');
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          // ✅ NO HAY SESIÓN - IR AL LOGIN
          print('❌ No hay sesión válida, navegando al login');
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      // ✅ ERROR DE CONEXIÓN - IR AL LOGIN
      print('❌ Error verificando sesión: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animado
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.map,
                size: 60,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 30),
            
            // Título
            const Text(
              'Mapas Rutas',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 50),
            
            // Loading indicator
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Cargando...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}