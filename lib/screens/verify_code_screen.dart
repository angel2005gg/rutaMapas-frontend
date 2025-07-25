import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';

class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({Key? key}) : super(key: key);

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _canResend = false;
  int _countdownSeconds = 60;
  Timer? _timer;
  String? _email;
  String? _password;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _email = args['email'];
        _password = args['password'];
      }
      _startCountdown();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _canResend = false;
    _countdownSeconds = 60;
    _timer?.cancel();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdownSeconds > 0) {
            _countdownSeconds--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _verifyCode() async {
    if (_isLoading) return;
    
    if (_codeController.text.length != 6) {
      _showError('Ingresa un código de 6 dígitos');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final result = await _authService.verifyCode(_email!, _codeController.text);
      
      if (mounted) {
        if (result['status'] == 'success') {
          _showSuccess('¡Verificación exitosa!');
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } else {
          _showError(result['message'] ?? 'Código inválido');
          _codeController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _resendCode() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await _authService.sendVerificationCode(_email!, _password ?? '123456');
      
      if (mounted) {
        if (result['status'] == 'success') {
          _showSuccess('Código reenviado');
          _startCountdown();
          _codeController.clear();
        } else {
          _showError(result['message'] ?? 'Error al reenviar');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                        MediaQuery.of(context).padding.top - 
                        kToolbarHeight - 40,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read,
                    size: 40,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Verifica tu código',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                Text(
                  'Código enviado a:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _email ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Card principal
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Campo código
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          color: Color(0xFF1565C0),
                        ),
                        decoration: InputDecoration(
                          hintText: '• • • • • •',
                          hintStyle: TextStyle(
                            fontSize: 24,
                            color: Colors.grey[400],
                            letterSpacing: 8,
                          ),
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onChanged: (value) {
                          if (value.length == 6) {
                            _verifyCode();
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Botón verificar
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Verificar código',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Reenviar código
                      if (_canResend)
                        TextButton.icon(
                          onPressed: _isLoading ? null : _resendCode,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Reenviar código'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1565C0),
                          ),
                        )
                      else
                        Text(
                          'Reenviar en $_countdownSeconds segundos',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                Text(
                  'El código expira en 10 minutos',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}