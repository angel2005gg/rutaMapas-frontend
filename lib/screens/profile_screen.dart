import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userData = await _authService.getCurrentUser();
      
      if (userData != null) {
        print('Datos recibidos: $userData'); // Para debug
        final user = UserModel.fromJson(userData);
        setState(() {
          _user = user;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No se pudieron obtener los datos del usuario';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error al cargar datos del usuario: $e');
      setState(() {
        _errorMessage = 'Error al cargar datos: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _authService.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ Widget para avatar que maneja correctamente usuarios sin foto
  Widget _buildProfileAvatar() {
    // Verificar si tiene foto real de Google
    if (_user!.fotoPerfil != null && 
        _user!.fotoPerfil!.isNotEmpty && 
        !_user!.fotoPerfil!.contains('gravatar')) { // ✅ Excluir Gravatar
      
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF1565C0), width: 3),
        ),
        child: ClipOval(
          child: Image.network(
            _user!.fotoPerfil!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1565C0),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // Si hay error cargando la imagen, mostrar avatar por defecto
              return _buildDefaultAvatar();
            },
          ),
        ),
      );
    } else {
      // Usuario sin foto real (registrado con email)
      return _buildDefaultAvatar();
    }
  }

  // ✅ Avatar por defecto con iniciales mejorado
  Widget _buildDefaultAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1565C0), width: 3),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0),
            const Color(0xFF1976D2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ✅ Método para obtener iniciales
  String _getInitials() {
    if (_user?.nombre == null || _user!.nombre.isEmpty) return 'U';
    
    // Si es "Usuario" genérico, usar inicial del email
    if (_user!.nombre.toLowerCase() == 'usuario') {
      final emailParts = _user!.correo.split('@');
      if (emailParts.isNotEmpty) {
        return emailParts[0].substring(0, 1).toUpperCase();
      }
      return 'U';
    }
    
    // Si tiene nombre real, usar iniciales normales
    final palabras = _user!.nombre.trim().split(' ');
    if (palabras.length >= 2) {
      return '${palabras[0][0]}${palabras[1][0]}'.toUpperCase();
    } else {
      return palabras[0][0].toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF1565C0),
              ),
              SizedBox(height: 16),
              Text(
                'Cargando perfil...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_user == null || _errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar datos del usuario',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'No se pudieron cargar los datos del perfil',
                style: const TextStyle(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // ✅ Avatar inteligente (foto real o iniciales)
              _buildProfileAvatar(),
              const SizedBox(height: 20),
              
              // Nombre inteligente
              Text(
                _user!.nombre == 'Usuario' ? 'Usuario Anónimo' : _user!.nombre,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Email
              Text(
                _user!.correo,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 30),
              
              // Estadísticas
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Estadísticas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Racha Actual',
                            '${_user!.rachaActual}',
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                          _buildStatItem(
                            'Clasificación',
                            _user!.clasificacionId == 0 ? 'Sin clasificar' : '${_user!.clasificacionId}',
                            Icons.emoji_events,
                            Colors.amber,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // Botón de cerrar sesión
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}