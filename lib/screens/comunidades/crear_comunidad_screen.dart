import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/comunidad_service.dart';

class CrearComunidadScreen extends StatefulWidget {
  const CrearComunidadScreen({Key? key}) : super(key: key);

  @override
  State<CrearComunidadScreen> createState() => _CrearComunidadScreenState();
}

class _CrearComunidadScreenState extends State<CrearComunidadScreen> {
  final ComunidadService _comunidadService = ComunidadService();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _crearComunidad() async {
    if (_nombreController.text.trim().isEmpty) {
      _showError('Ingresa el nombre de la comunidad');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // ✅ LLAMADA REAL AL BACKEND
      final result = await _comunidadService.crearComunidad(
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty 
            ? null 
            : _descripcionController.text.trim(),
      );
      
      if (mounted) {
        if (result['status'] == 'success') {
          // ✅ CÓDIGO REAL del backend
          final codigoReal = result['comunidad']['codigo_unico'];
          final nombreComunidad = result['comunidad']['nombre'];
          
          _showSuccessDialog(codigoReal, nombreComunidad);
        } else {
          // Manejar errores de validación
          String errorMessage = result['message'] ?? 'Error al crear la comunidad';
          
          // Si hay errores específicos de campos
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

  void _showSuccessDialog(String codigoReal, String nombreComunidad) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('¡Comunidad Creada!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tu comunidad "$nombreComunidad" ha sido creada exitosamente.'),
              const SizedBox(height: 16),
              const Text(
                'Código de la comunidad:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      codigoReal, // ✅ CÓDIGO REAL del backend
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                        letterSpacing: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        // ✅ COPIAR CÓDIGO REAL al portapapeles
                        Clipboard.setData(ClipboardData(text: codigoReal));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Código copiado al portapapeles'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Comparte este código con tus amigos para que se unan',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(); // Volver a comunidades
              },
              child: const Text('Entendido'),
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
          '📝 Crear Comunidad',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono y título
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.group_add,
                        size: 40,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Crea tu propia comunidad',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Invita a tus amigos a unirse y compite en rutas',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Formulario
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campo nombre
                      const Text(
                        'Nombre de la comunidad *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nombreController,
                        decoration: InputDecoration(
                          hintText: 'Ej: Moteros Colombia',
                          prefixIcon: const Icon(Icons.group),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF1565C0),
                              width: 2,
                            ),
                          ),
                        ),
                        maxLength: 100, // ✅ Límite del backend
                      ),
                      const SizedBox(height: 20),
                      
                      // Campo descripción
                      const Text(
                        'Descripción (opcional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descripcionController,
                        decoration: InputDecoration(
                          hintText: 'Describe tu comunidad...',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF1565C0),
                              width: 2,
                            ),
                          ),
                        ),
                        maxLines: 3,
                        maxLength: 500, // Sin límite estricto en backend
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // Botón crear
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _crearComunidad,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.add_circle, size: 24),
                  label: Text(
                    _isLoading ? 'CREANDO...' : 'CREAR COMUNIDAD',
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
    );
  }
}