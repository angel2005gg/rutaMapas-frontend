import 'package:flutter/material.dart';
import '../services/comunidad_service.dart';
import '../widgets/community_drawer.dart'; // ✅ NUEVO: Import del drawer
import '../widgets/community_management_sheet.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ComunidadService _comunidadService = ComunidadService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // ✅ NUEVO: Clave para el drawer
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _misComunidades = [];
  Map<String, dynamic>? _comunidadActual;

  // ✅ NUEVO: Método para cambiar de comunidad desde el drawer
  void _cambiarComunidad(Map<String, dynamic> comunidad) {
    setState(() {
      _comunidadActual = comunidad;
    });
    Navigator.pop(context); // Cerrar drawer
  }

  @override
  void initState() {
    super.initState();
    _cargarMisComunidades();
  }

  @override
  void didUpdateWidget(CommunityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarMisComunidades();
    });
  }

  // ✅ ACTUALIZAR el método _cargarMisComunidades() para manejar correctamente cuando no hay comunidades:

  Future<void> _cargarMisComunidades() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _comunidadService.obtenerMisComunidades();
      
      if (mounted) {
        if (result['status'] == 'success' && result['comunidades'] != null) {
          final comunidades = List<Map<String, dynamic>>.from(result['comunidades']);
          
          print('Comunidades cargadas: ${comunidades.length}'); // Debug
          
          setState(() {
            _misComunidades = comunidades;
            
            // ✅ ARREGLO PRINCIPAL: Si no hay comunidades, limpiar _comunidadActual
            if (comunidades.isEmpty) {
              _comunidadActual = null; // ✅ ESTO FORZARÁ A MOSTRAR _buildSinComunidades()
              print('No hay comunidades - limpiando comunidad actual');
            } else {
              // ✅ LÓGICA PRIORITARIA: Buscar primero la comunidad donde es CREADOR
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
            }
          });
        } else {
          print('Sin comunidades o error: ${result.toString()}'); // Debug
          setState(() {
            _misComunidades = [];
            _comunidadActual = null; // ✅ LIMPIAR TAMBIÉN AQUÍ
          });
        }
      }
    } catch (e) {
      print('Error al cargar comunidades: $e');
      if (mounted) {
        setState(() {
          _misComunidades = [];
          _comunidadActual = null; // ✅ LIMPIAR EN CASO DE ERROR TAMBIÉN
        });
        
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

  void _abrirGestionComunidades() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CommunityManagementSheet(
        misComunidades: _misComunidades,
        comunidadActual: _comunidadActual!,
        onComunidadUpdated: _cargarMisComunidades, // ✅ Callback para recargar
      ),
    );
  }

  // ✅ VISTA CUANDO NO TIENE COMUNIDADES (solo se muestra si realmente no tiene)
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
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/crear-comunidad').then((_) {
                      _cargarMisComunidades();
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
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/unirse-comunidad').then((_) {
                      _cargarMisComunidades();
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

  // ✅ VISTA PRINCIPAL: Dashboard de su comunidad con podium completo
  Widget _buildDashboardComunidad() {
    final rankingMiembros = List<Map<String, dynamic>>.from(_comunidadActual!['usuarios'] ?? []);
    
    return Scaffold(
      key: _scaffoldKey, // ✅ NUEVO: Clave para el drawer
      backgroundColor: Colors.grey[50],
      
      // ✅ NUEVO: Drawer con todas las comunidades
      drawer: CommunityDrawer(
        comunidades: _misComunidades,
        comunidadActual: _comunidadActual,
        onComunidadSelected: _cambiarComunidad,
      ),
      
      appBar: AppBar(
        // ✅ NUEVO: Menú hamburguesa a la izquierda
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            Icon(
              _comunidadActual!['es_creador'] == true 
                  ? Icons.admin_panel_settings 
                  : Icons.groups,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _comunidadActual!['nombre'] ?? 'Mi Comunidad',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // ✅ CAMBIAR: Ya no es false
        actions: [
          // ✅ Botón de ajustes a la derecha (como antes)
          IconButton(
            onPressed: _abrirGestionComunidades,
            icon: const Icon(Icons.settings),
            tooltip: 'Gestionar Comunidades',
          ),
        ],
      ),
      
      // ... TODO EL BODY IGUAL SIN CAMBIOS ...
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarMisComunidades,
          color: const Color(0xFF1565C0),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Card principal de la comunidad (más compacto para dashboard)
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _comunidadActual!['es_creador'] == true 
                              ? const Color(0xFF1565C0) 
                              : const Color(0xFF2E7D32),
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
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _comunidadActual!['es_creador'] == true 
                                    ? Icons.emoji_events 
                                    : Icons.groups,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _comunidadActual!['nombre'] ?? 'Sin nombre',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _comunidadActual!['es_creador'] == true 
                                        ? '👑 Eres el Administrador' 
                                        : '👤 Miembro de la comunidad',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Estadísticas en fila
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Miembros',
                                '${_comunidadActual!['total_miembros'] ?? 0}',
                                Icons.people,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Código',
                                '${_comunidadActual!['codigo_unico'] ?? 'N/A'}',
                                Icons.vpn_key,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // ✅ Título del ranking con icono
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.leaderboard,
                        color: Color(0xFF1565C0),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Ranking de Miembros',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                    // Chip con total de participantes
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${rankingMiembros.length} participantes',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // ✅ PODIUM/RANKING completo con datos reales
                if (rankingMiembros.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: rankingMiembros.length,
                    itemBuilder: (context, index) {
                      final miembro = rankingMiembros[index];
                      final isTopThree = (miembro['posicion'] ?? 999) <= 3;
                      return _buildRankingItem(miembro, isTopThree);
                    },
                  )
                else
                  // Mensaje cuando no hay ranking
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
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
                                ? 'Tu comunidad está lista!\n¡Invita amigos para crear competencia!'
                                : 'Aún no hay actividad en el ranking.\n¡Completa rutas para ganar puntos!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // ✅ Información adicional/tips
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
                            ? Icons.share 
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
                              ? 'Comparte el código ${_comunidadActual!['codigo_unico']} con amigos para que se unan'
                              : 'Completa rutas y actividades para ganar puntos y subir en el ranking',
                          style: TextStyle(
                            fontSize: 14,
                            color: _comunidadActual!['es_creador'] == true 
                                ? Colors.blue[700] 
                                : Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Espaciado final para scroll
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Widget para estadísticas en el card principal
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Widget para cada item del ranking (IGUAL que antes)
  Widget _buildRankingItem(Map<String, dynamic> miembro, bool isTopThree) {
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
        ] : [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Posición con medalla
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
          
          // Avatar del usuario
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
          
          // Información del usuario
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
      case 1: return Colors.amber;
      case 2: return Colors.grey[400]!;
      case 3: return Colors.orange[300]!;
      default: return Colors.grey[400]!;
    }
  }

  IconData _getTopThreeIcon(int posicion) {
    switch (posicion) {
      case 1: return Icons.emoji_events;
      case 2: return Icons.military_tech;
      case 3: return Icons.military_tech;
      default: return Icons.person;
    }
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

    // ✅ LÓGICA PRINCIPAL: 
    // - Si NO tiene comunidades → Mostrar pantalla de crear/unirse
    // - Si SÍ tiene comunidades → Mostrar dashboard de su comunidad principal
    if (_comunidadActual == null) {
      return _buildSinComunidades(); // Solo cuando NO tiene comunidades
    } else {
      return _buildDashboardComunidad(); // Dashboard principal de su comunidad
    }
  }
}