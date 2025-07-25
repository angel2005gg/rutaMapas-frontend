import 'package:flutter/material.dart';

class ComunidadesScreen extends StatefulWidget {
  const ComunidadesScreen({Key? key}) : super(key: key);

  @override
  State<ComunidadesScreen> createState() => _ComunidadesScreenState();
}

class _ComunidadesScreenState extends State<ComunidadesScreen> {
  
  void _navegarACrearComunidad() {
    Navigator.pushNamed(context, '/crear-comunidad');
  }

  void _navegarAUnirseComunidad() {
    Navigator.pushNamed(context, '/unirse-comunidad');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '🏘️ Comunidades',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono principal
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1565C0),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.groups,
                  size: 60,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 30),
              
              // Título
              const Text(
                'Únete a la Comunidad',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Descripción
              Text(
                'Crea tu propia comunidad con amigos o únete a una existente usando un código único',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              
              // Botón CREAR COMUNIDAD
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _navegarACrearComunidad,
                  icon: const Icon(Icons.add_circle_outline, size: 24),
                  label: const Text(
                    'CREAR COMUNIDAD',
                    style: TextStyle(
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
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Botón UNIRSE A COMUNIDAD
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _navegarAUnirseComunidad,
                  icon: const Icon(Icons.link, size: 24),
                  label: const Text(
                    'UNIRSE A COMUNIDAD',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1565C0),
                    side: const BorderSide(
                      color: Color(0xFF1565C0),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Footer informativo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Las comunidades te permiten competir con amigos y seguir sus rutas favoritas',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
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