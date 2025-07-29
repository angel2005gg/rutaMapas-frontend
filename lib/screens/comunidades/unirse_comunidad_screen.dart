import 'package:flutter/material.dart';
import '../../services/comunidad_service.dart';

class UnirseComunidadScreen extends StatefulWidget {
  const UnirseComunidadScreen({Key? key}) : super(key: key);

  @override
  State<UnirseComunidadScreen> createState() => _UnirseComunidadScreenState();
}

class _UnirseComunidadScreenState extends State<UnirseComunidadScreen> {
  final ComunidadService _comunidadService = ComunidadService();
  final TextEditingController _codigoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _unirseAComunidad() async {
    final codigo = _codigoController.text.trim().toUpperCase();
    
    if (codigo.isEmpty) {
      _showError('Ingresa el código de la comunidad');
      return;
    }
    
    if (codigo.length != 6) {
      _showError('El código debe tener 6 caracteres');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final result = await _comunidadService.unirseAComunidad(
        codigoUnico: codigo,
      );
      
      if (mounted) {
        if (result['status'] == 'success') {
          final nombreComunidad = result['comunidad']['nombre'];
          final totalMiembros = result['comunidad']['total_miembros'];
          
          _showSuccessDialog(nombreComunidad, totalMiembros);
        } else {
          String errorMessage = result['message'] ?? 'Error al unirse a la comunidad';
          
          if (result['errors'] != null) {
            final errors = result['errors'] as Map<String, dynamic>;
            final errorList = <String>[];
            
            errors.forEach((field, messages) {
              if (messages is List) {
                errorList.addAll(messages.cast<String>());
              }
            });
            
            if (errorList.isNotEmpty) {
              errorMessage = errorList.join('\n');
            }
          }
          
          _showError(errorMessage);
          _codigoController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Error inesperado: ${e.toString()}');
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessDialog(String nombreComunidad, int totalMiembros) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('¡Bienvenido!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.groups,
                size: 60,
                color: Color(0xFF1565C0),
              ),
              const SizedBox(height: 16),
              Text(
                'Te has unido exitosamente a:',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                nombreComunidad,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  '$totalMiembros miembros',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                // ✅ ARREGLADO: Navegar directamente al dashboard Y recargar
                Navigator.of(context).popUntil((route) => route.isFirst); // Ir al dashboard
                // Esto hará que CommunityScreen se recargue automáticamente
              },
              child: const Text('¡Ver mi comunidad!'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '🔗 Unirse a Comunidad',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.group_add,
                  size: 50,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Únete a una comunidad',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                'Ingresa el código de 6 caracteres que te compartió tu amigo',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'Código de la comunidad',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: _codigoController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: Color(0xFF1565C0),
                        ),
                        maxLength: 6,
                        decoration: InputDecoration(
                          hintText: 'XY8Z9K',
                          hintStyle: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[400],
                            letterSpacing: 4,
                          ),
                          counterText: '',
                          prefixIcon: const Icon(Icons.vpn_key),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1565C0),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                        ),
                        onChanged: (value) {
                          if (value != value.toUpperCase()) {
                            _codigoController.text = value.toUpperCase();
                            _codigoController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _codigoController.text.length),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _unirseAComunidad,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.group_add, size: 24),
                          label: Text(
                            _isLoading ? 'UNIÉNDOSE...' : 'UNIRSE',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pide a tu amigo que comparta contigo el código de su comunidad',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.amber[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}