import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/comunidad_service.dart';

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

  // ✅ MODIFICAR ESTE MÉTODO COMPLETO:
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userData = await _authService.getCurrentUser();
      
      if (userData != null) {
        print('📊 Datos completos recibidos en perfil: $userData');
        var user = UserModel.fromJson(userData);
        
        print('👤 Usuario procesado en perfil:');
        print('   - Nombre: ${user.nombre}');
        print('   - Racha Actual: ${user.rachaActual}');
        print('   - Clasificación ID: ${user.clasificacionId}');
        print('   - Clasificación Nombre: ${_getNombreClasificacion(user.clasificacionId)}');
        final rawUserData = userData['user'] ?? userData;
        print('🔍 Datos RAW de racha: ${rawUserData['racha_actual']}');
        print('🔍 Puntos totales (user endpoint): ${user.puntosTotales}');

        // Fallback: si no tenemos puntos totales (>0), intentar leerlos desde mis comunidades
        int puntosTotales = user.puntosTotales;
        if (puntosTotales <= 0) {
          try {
            final comuSvc = ComunidadService();
            final res = await comuSvc.obtenerMisComunidades();
            if (res['status'] == 'success' && res['comunidades'] is List) {
              final List comunidades = res['comunidades'];
              int maxPuntaje = 0;
              for (final c in comunidades) {
                final usuarios = c['usuarios'];
                if (usuarios is List) {
                  for (final u in usuarios) {
                    if ((u['id'] == user.id) && u['puntaje'] != null) {
                      final p = u['puntaje'] is int ? u['puntaje'] as int : int.tryParse('${u['puntaje']}') ?? 0;
                      if (p > maxPuntaje) maxPuntaje = p;
                    }
                  }
                }
              }
              if (maxPuntaje > 0) {
                puntosTotales = maxPuntaje;
                // reconstruir user con puntosTotales
                user = UserModel(
                  id: user.id,
                  nombre: user.nombre,
                  correo: user.correo,
                  fotoPerfil: user.fotoPerfil,
                  googleUid: user.googleUid,
                  rachaActual: user.rachaActual,
                  clasificacionId: user.clasificacionId,
                  puntosTotales: puntosTotales,
                );
                print('✅ Puntos totales tomados de comunidades: $puntosTotales');
              }
            }
          } catch (e) {
            print('⚠️ No se pudo obtener puntos desde comunidades: $e');
          }
        }
        
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
      print('❌ Error al cargar datos del usuario: $e');
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

  // ✅ Método para obtener nombre de clasificación
  String _getNombreClasificacion(int clasificacionId) {
    switch (clasificacionId) {
      case 1:
        return 'Tornillo Oxidado';
      case 2:
        return 'Tuerca de Bronce';
      case 3:
        return 'Pistón Plateado';
      case 4:
        return 'Turbo Dorado';
      case 5:
        return 'Copa Pistón';
      default:
        return 'Sin clasificar';
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
                'Error al cargar perfil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Error desconocido',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator( // ✅ NUEVO: Agregar RefreshIndicator
          onRefresh: _loadUserData, // ✅ NUEVO: Conectar con método de carga
          color: const Color(0xFF1565C0), // ✅ Color del indicador
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // ✅ IMPORTANTE: Para que funcione el pull-to-refresh
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // ✅ Avatar inteligente (foto real o iniciales)
                _buildProfileAvatar(),
                const SizedBox(height: 20),
                
                // Nombre inteligente
                Text(
                  _user!.nombre.isNotEmpty ? _user!.nombre : 'Usuario',
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
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
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
                          children: [ // ✅ QUITAR mainAxisAlignment
                            _buildStatItem(
                              'Racha Actual',
                              '${_user!.rachaActual} días', // ✅ AGREGAR "días" para claridad
                              Icons.local_fire_department,
                              Colors.orange,
                            ),
                            const SizedBox(width: 16), // ✅ SEPARADOR fijo entre columnas
                            _buildStatItem(
                              'Clasificación',
                              _getNombreClasificacion(_user!.clasificacionId),
                              Icons.emoji_events,
                              Colors.amber,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatItem(
                              'Puntos totales',
                              '${_user!.puntosTotales}',
                              Icons.score_rounded,
                              const Color(0xFF1565C0),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(child: SizedBox()), // mantener estructura a 2 columnas aunque 1 dato
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // // ✅ NUEVO: Indicador de actualización
                // Container(
                //   padding: const EdgeInsets.all(12),
                //   decoration: BoxDecoration(
                //     color: Colors.blue[50],
                //     borderRadius: BorderRadius.circular(8),
                //     border: Border.all(color: Colors.blue[200]!),
                //   ),
                //   child: Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Icon(
                //         Icons.refresh,
                //         color: Colors.blue[600],
                //         size: 16,
                //       ),
                //       const SizedBox(width: 8),
                //       Text(
                //         'Desliza hacia abajo para actualizar',
                //         style: TextStyle(
                //           fontSize: 12,
                //           color: Colors.blue[700],
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                // const SizedBox(height: 20),
                
                // Botón de cerrar sesión
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
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
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Expanded( // ✅ NUEVO: Expandir para usar todo el espacio disponible
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22, // ✅ REDUCIR tamaño para nombres largos
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center, // ✅ CENTRAR texto
            maxLines: 2, // ✅ PERMITIR hasta 2 líneas
            overflow: TextOverflow.ellipsis, // ✅ PUNTOS suspensivos si es muy largo
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12, // ✅ REDUCIR tamaño del título
              color: Colors.grey,
            ),
            textAlign: TextAlign.center, // ✅ CENTRAR texto
            maxLines: 1, // ✅ SOLO 1 línea para el título
            overflow: TextOverflow.ellipsis, // ✅ PUNTOS suspensivos
          ),
        ],
      ),
    );
  }
}