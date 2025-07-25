import 'package:flutter/material.dart';
import '../services/comunidad_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ComunidadService _comunidadService = ComunidadService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _misComunidades = [];
  Map<String, dynamic>? _comunidadActual;
  List<Map<String, dynamic>> _rankingMiembros = [];

  @override
  void initState() {
    super.initState();
    _cargarMisComunidades();
  }

  Future<void> _cargarMisComunidades() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _comunidadService.obtenerMisComunidades();
      
      if (mounted) {
        // ✅ ARREGLADO: Manejar correctamente la respuesta del backend reparado
        if (result['status'] == 'success' && result['comunidades'] != null) {
          final comunidades = List<Map<String, dynamic>>.from(result['comunidades']);
          
          print('Comunidades cargadas: ${comunidades.length}'); // Debug
          
          setState(() {
            _misComunidades = comunidades;
            
            if (comunidades.isNotEmpty) {
              // ✅ LÓGICA ARREGLADA: Buscar primero la comunidad donde es CREADOR/DUEÑO
              Map<String, dynamic>? comunidadCreador;
              Map<String, dynamic>? otraComunidad;
              
              for (var comunidad in comunidades) {
                print('Comunidad: ${comunidad['nombre']}, es_creador: ${comunidad['es_creador']}'); // Debug
                
                if (comunidad['es_creador'] == true) {
                  comunidadCreador = comunidad;
                  break; // Encontró su comunidad como creador
                } else {
                  otraComunidad ??= comunidad; // Guardar la primera donde es miembro
                }
              }
              
              // ✅ PRIORIDAD: 1° Su comunidad como creador, 2° Cualquier otra
              _comunidadActual = comunidadCreador ?? otraComunidad;
              
              print('Comunidad actual seleccionada: ${_comunidadActual?['nombre']}, es_creador: ${_comunidadActual?['es_creador']}'); // Debug
              
              if (_comunidadActual != null) {
                _cargarDetallesComunidad(_comunidadActual!['id']);
              }
            }
          });
        } else {
          // ✅ Sin comunidades o error del servidor
          print('Sin comunidades o error: ${result.toString()}'); // Debug
          setState(() {
            _misComunidades = [];
            _comunidadActual = null;
          });
        }
      }
    } catch (e) {
      print('Error al cargar comunidades: $e');
      if (mounted) {
        setState(() {
          _misComunidades = [];
          _comunidadActual = null;
        });
        
        // ✅ Mostrar error al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar comunidades: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _cargarDetallesComunidad(int comunidadId) async {
    try {
      final result = await _comunidadService.obtenerDetallesComunidad(
        comunidadId: comunidadId,
      );
      
      print('Detalles comunidad response: $result'); // Debug
      
      if (mounted && result['status'] == 'success') {
        setState(() {
          _rankingMiembros = List<Map<String, dynamic>>.from(result['ranking'] ?? []);
        });
        print('Ranking cargado: ${_rankingMiembros.length} miembros'); // Debug
      }
    } catch (e) {
      print('Error al cargar detalles de comunidad: $e');
    }
  }

  void _abrirConfiguracionComunidades() {
    Navigator.pushNamed(context, '/comunidades').then((_) {
      _cargarMisComunidades();
    });
  }

  // ✅ VISTA CUANDO NO TIENE COMUNIDADES
  Widget _buildSinComunidades() {
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
        automaticallyImplyLeading: false,
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
                  onPressed: () {
                    Navigator.pushNamed(context, '/crear-comunidad').then((_) {
                      _cargarMisComunidades(); // Recargar después de crear
                    });
                  },
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
                  onPressed: () {
                    Navigator.pushNamed(context, '/unirse-comunidad').then((_) {
                      _cargarMisComunidades(); // Recargar después de unirse
                    });
                  },
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

  // ✅ VISTA CUANDO SÍ TIENE COMUNIDADES - MUESTRA SU COMUNIDAD PRINCIPAL
  Widget _buildConComunidades() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          // ✅ TÍTULO DINÁMICO según si es creador o miembro
          _comunidadActual!['es_creador'] == true ? 'Mi Comunidad' : 'Comunidad',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // ✅ Botón de configuración arriba a la derecha
          IconButton(
            onPressed: _abrirConfiguracionComunidades,
            icon: const Icon(Icons.settings),
            tooltip: 'Gestionar Comunidades',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Card de información de SU comunidad principal
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        // ✅ COLOR DIFERENTE si es creador vs miembro
                        _comunidadActual!['es_creador'] == true 
                            ? const Color(0xFF1565C0) 
                            : const Color(0xFF2E7D32), // Verde si es miembro
                        _comunidadActual!['es_creador'] == true 
                            ? const Color(0xFF1976D2) 
                            : const Color(0xFF388E3C),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            // ✅ ÍCONO DIFERENTE si es creador vs miembro
                            _comunidadActual!['es_creador'] == true 
                                ? Icons.admin_panel_settings 
                                : Icons.groups,
                            color: Colors.white,
                            size: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _comunidadActual!['nombre'] ?? 'Sin nombre',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _comunidadActual!['descripcion'] ?? 'Sin descripción',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(
                            'Código: ${_comunidadActual!['codigo_unico'] ?? 'N/A'}',
                            Icons.vpn_key,
                          ),
                          _buildInfoChip(
                            '${_comunidadActual!['total_miembros'] ?? 0} miembros',
                            Icons.person,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoChip(
                        // ✅ MENSAJE CLARO sobre su rol
                        _comunidadActual!['es_creador'] == true 
                            ? '🎖️ Eres el Administrador' 
                            : '👤 Eres Miembro',
                        Icons.emoji_events,
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // ✅ Título del ranking
              Row(
                children: [
                  const Icon(
                    Icons.leaderboard,
                    color: Color(0xFF1565C0),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Ranking de Miembros',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // ✅ Lista del ranking REAL
              if (_rankingMiembros.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _rankingMiembros.length,
                  itemBuilder: (context, index) {
                    final miembro = _rankingMiembros[index];
                    final isTopThree = (miembro['posicion'] ?? 999) <= 3;
                    return _buildRankingItem(miembro, isTopThree);
                  },
                )
              else
                // Mensaje cuando no hay ranking
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _comunidadActual!['es_creador'] == true 
                              ? 'Tu comunidad está lista.\n¡Invita amigos para crear competencia!'
                              : 'Aún no hay actividad en el ranking.\n¡Completa rutas para ganar puntos!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // ✅ Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _comunidadActual!['es_creador'] == true 
                      ? Colors.blue[50] 
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _comunidadActual!['es_creador'] == true 
                        ? Colors.blue[200]! 
                        : Colors.green[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _comunidadActual!['es_creador'] == true 
                          ? Icons.info_outline 
                          : Icons.local_fire_department,
                      color: _comunidadActual!['es_creador'] == true 
                          ? Colors.blue[600] 
                          : Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _comunidadActual!['es_creador'] == true 
                            ? 'Comparte el código de tu comunidad con amigos para que se unan'
                            : 'Completa rutas y actividades para ganar puntos y subir en el ranking',
                        style: TextStyle(
                          fontSize: 14,
                          color: _comunidadActual!['es_creador'] == true 
                              ? Colors.blue[700] 
                              : Colors.green[700],
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

  // Widget para construir cada item del ranking CON DATOS REALES
  Widget _buildRankingItem(Map<String, dynamic> miembro, bool isTopThree) {
    // ✅ Obtener avatar real (iniciales del nombre)
    String getAvatar(String? nombre) {
      if (nombre == null || nombre.isEmpty) return 'U';
      
      final palabras = nombre.trim().split(' ');
      if (palabras.length >= 2) {
        return '${palabras[0][0]}${palabras[1][0]}'.toUpperCase();
      } else {
        return palabras[0][0].toUpperCase();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: isTopThree ? [
          BoxShadow(
            color: _getTopThreeColor(miembro['posicion'] ?? 999).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Row(
        children: [
          // Posición and medalla
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTopThree 
                  ? _getTopThreeColor(miembro['posicion'] ?? 999)
                  : Colors.grey[400],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isTopThree
                  ? Icon(
                      _getTopThreeIcon(miembro['posicion'] ?? 999),
                      color: Colors.white,
                      size: 20,
                    )
                  : Text(
                      '${miembro['posicion'] ?? '?'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Avatar del usuario REAL
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                getAvatar(miembro['nombre']),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Información del usuario REAL
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  miembro['nombre'] ?? 'Usuario sin nombre',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                // ✅ ARREGLADO: Usar Wrap para evitar overflow en puntos y racha
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${miembro['puntaje'] ?? 0} pts',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Racha: ${miembro['racha_actual'] ?? 0}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTopThreeColor(int posicion) {
    switch (posicion) {
      case 1: return Colors.amber; // Oro
      case 2: return Colors.grey[400]!; // Plata  
      case 3: return Colors.orange[300]!; // Bronce
      default: return Colors.grey[400]!;
    }
  }

  IconData _getTopThreeIcon(int posicion) {
    switch (posicion) {
      case 1: return Icons.emoji_events; // Trofeo
      case 2: return Icons.military_tech; // Medalla
      case 3: return Icons.military_tech; // Medalla
      default: return Icons.person;
    }
  }

  Widget _buildInfoChip(String text, IconData icon, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight 
            ? Colors.white.withOpacity(0.2)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: isHighlight 
            ? Border.all(color: Colors.white.withOpacity(0.5))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Comunidades'),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF1565C0),
              ),
              SizedBox(height: 16),
              Text(
                'Cargando comunidades...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ LÓGICA PRINCIPAL: Mostrar vista según si tiene comunidades o no
    if (_comunidadActual == null) {
      return _buildSinComunidades(); // Sin comunidades
    } else {
      return _buildConComunidades(); // Con SU comunidad principal
    }
  }
}