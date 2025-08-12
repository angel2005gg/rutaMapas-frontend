import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  
  // ✅ NUEVAS VARIABLES para mejor control
  bool _isChecking = true;
  String _statusMessage = 'Cargando...';
  bool _hasError = false;
  
  // ✅ ANIMACIONES para mejor UX
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthWithTimeout();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ✅ NUEVO: Inicializar animaciones
  void _initializeAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  // ✅ NUEVO: Verificación con timeout y mejor manejo de errores
  Future<void> _checkAuthWithTimeout() async {
    try {
      // ✅ MOSTRAR MENSAJE DE CARGA
      _updateStatus('Verificando sesión...');
      
      // ✅ TIMEOUT DE MÁXIMO 8 SEGUNDOS
      final result = await Future.any([
        _authService.getCurrentUser(),
        Future.delayed(
          const Duration(seconds: 8), 
          () => throw TimeoutException('Timeout'),
        ),
      ]);
      
      if (mounted) {
        if (result != null && result['status'] == 'success') {
          // ✅ SESIÓN VÁLIDA
          _updateStatus('¡Bienvenido de vuelta!');
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } else {
          // ✅ NO HAY SESIÓN VÁLIDA
          _updateStatus('Iniciando...');
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      }
    } on TimeoutException {
      // ✅ TIMEOUT - ASUMIR SIN CONEXIÓN
      if (mounted) {
        _handleConnectionError();
      }
    } catch (e) {
      // ✅ OTROS ERRORES - MOSTRAR ERROR AMIGABLE
      if (mounted) {
        _handleServerError(e.toString());
      }
    }
  }

  // ✅ NUEVO: Manejar error de conexión/timeout
  void _handleConnectionError() {
    setState(() {
      _hasError = true;
      _statusMessage = 'Sin conexión a internet';
      _isChecking = false;
    });
    
    // ✅ IR AL LOGIN DESPUÉS DE 3 SEGUNDOS
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  // ✅ NUEVO: Manejar errores del servidor con mensaje amigable
  void _handleServerError(String originalError) {
    setState(() {
      _hasError = true;
      _isChecking = false;
    });

    // ✅ MENSAJE AMIGABLE SEGÚN EL ERROR
    if (originalError.contains('SocketException') || 
        originalError.contains('HandshakeException') ||
        originalError.contains('Connection refused') ||
        originalError.contains('server 190') ||
        originalError.contains('192.168')) {
      setState(() {
        _statusMessage = 'Aplicación no disponible en este momento.\nIntentalo más tarde.';
      });
    } else if (originalError.contains('TimeoutException') || 
               originalError.contains('timeout')) {
      setState(() {
        _statusMessage = 'La conexión está muy lenta.\nVerifica tu internet.';
      });
    } else {
      setState(() {
        _statusMessage = 'Servicio temporalmente no disponible.\nIntentalo en unos minutos.';
      });
    }

    // ✅ IR AL LOGIN DESPUÉS DE 4 SEGUNDOS
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  // ✅ NUEVO: Actualizar estado con mensaje
  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  // ✅ NUEVO: Reintentar conexión
  void _retry() {
    setState(() {
      _isChecking = true;
      _hasError = false;
      _statusMessage = 'Reintentando...';
    });
    _checkAuthWithTimeout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ LOGO CON ANIMACIÓN OPTIMIZADA
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _hasError ? 1.0 : _pulseAnimation.value,
                        child: Transform.rotate(
                          angle: _hasError ? 0.0 : _rotationController.value * 2 * 3.14159,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _hasError ? Icons.warning_amber_rounded : Icons.map,
                              size: 60,
                              color: _hasError ? Colors.orange[600] : const Color(0xFF1565C0),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 30),
              
              // ✅ TÍTULO
              const Text(
                'Mapas Rutas',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 50),
              
              // ✅ INDICADOR DE CARGA O ERROR
              if (_isChecking) ...[
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ] else if (_hasError) ...[
                Icon(
                  Icons.error_outline,
                  color: Colors.white.withOpacity(0.8),
                  size: 40,
                ),
                const SizedBox(height: 20),
              ],
              
              // ✅ MENSAJE DE ESTADO
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: _hasError ? 16 : 16,
                  color: _hasError ? Colors.white : Colors.white70,
                  fontWeight: _hasError ? FontWeight.w500 : FontWeight.normal,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              // ✅ BOTÓN DE REINTENTAR (solo si hay error)
              if (_hasError) ...[
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'O continúa sin conexión...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ NUEVO: Excepción personalizada para timeout
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}