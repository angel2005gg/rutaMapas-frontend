import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ NUEVO: Para copiar al portapapeles
import '../services/comunidad_service.dart';
import '../widgets/community_drawer.dart';
import '../widgets/community_management_sheet.dart';
import '../widgets/ranking_position_widget.dart'; // ✅ NUEVO IMPORT

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ComunidadService _comunidadService = ComunidadService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _misComunidades = [];
  Map<String, dynamic>? _comunidadActual;
  
  // ✅ NUEVO: Estado para controlar el desplegable
  bool _isExpanded = false;

  void _cambiarComunidad(Map<String, dynamic> comunidad) {
    setState(() {
      _comunidadActual = comunidad;
      _isExpanded = false; // ✅ Cerrar desplegable al cambiar comunidad
    });
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    print('🏘️ CommunityScreen initState ejecutado');
    _cargarMisComunidades();
  }

  @override
  void didUpdateWidget(CommunityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('🏘️ CommunityScreen didUpdateWidget ejecutado');
    // ✅ ELIMINAR TODA LA LÓGICA DE RECARGA AUTOMÁTICA
    // Esto evitará los errores de frames y reconstrucciones innecesarias
  }

  Future<void> _cargarMisComunidades() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _comunidadService.obtenerMisComunidades();
      
      if (mounted) {
        if (result['status'] == 'success' && result['comunidades'] != null) {
          final comunidades = List<Map<String, dynamic>>.from(result['comunidades']);
          
          setState(() {
            _misComunidades = comunidades;
            
            if (comunidades.isEmpty) {
              _comunidadActual = null;
            } else {
              Map<String, dynamic>? comunidadCreador;
              Map<String, dynamic>? otraComunidad;
              
              for (var comunidad in comunidades) {
                if (comunidad['es_creador'] == true) {
                  comunidadCreador = comunidad;
                  break;
                } else {
                  otraComunidad ??= comunidad;
                }
              }
              
              _comunidadActual = comunidadCreador ?? otraComunidad;
            }
          });
        } else {
          setState(() {
            _misComunidades = [];
            _comunidadActual = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _misComunidades = [];
          _comunidadActual = null;
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
        onComunidadUpdated: _cargarMisComunidades,
      ),
    );
  }

  // ✅ NUEVO: Método para copiar código al portapapeles
  void _copiarCodigo() {
    final codigo = _comunidadActual!['codigo_unico'];
    Clipboard.setData(ClipboardData(text: codigo));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado al portapapeles'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ✅ NUEVO: Método para obtener mi posición en el ranking
  Map<String, dynamic> _obtenerMiPosicion() {
    if (_comunidadActual == null) {
      return {'posicion': null, 'puntos': 0};
    }

    final rankingMiembros = List<Map<String, dynamic>>.from(_comunidadActual!['usuarios'] ?? []);
    
    // Buscar mi posición en el ranking (esto depende de cómo identifiques al usuario actual)
    // Por ahora asumiré que hay alguna manera de identificar al usuario actual
    // Puedes ajustar esta lógica según tu implementación
    
    for (var miembro in rankingMiembros) {
      // Aquí deberías comparar con el ID del usuario actual
      // Por ahora usaré una lógica temporal
      if (miembro['es_usuario_actual'] == true) { // Necesitarás agregar este campo en el backend
        return {
          'posicion': miembro['posicion'],
          'puntos': miembro['puntos'] ?? 0,
        };
      }
    }
    
    // Si no se encuentra, asumir última posición
    return {
      'posicion': rankingMiembros.length > 0 ? rankingMiembros.length : null,
      'puntos': 0,
    };
  }

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

  Widget _buildDashboardComunidad() {
    final rankingMiembros = List<Map<String, dynamic>>.from(_comunidadActual!['usuarios'] ?? []);
    final miRanking = _obtenerMiPosicion(); // ✅ OBTENER MI POSICIÓN
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      
      drawer: CommunityDrawer(
        comunidades: _misComunidades,
        comunidadActual: _comunidadActual,
        onComunidadSelected: _cambiarComunidad,
      ),
      
      appBar: AppBar(
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
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _abrirGestionComunidades,
            icon: const Icon(Icons.settings),
            tooltip: 'Gestionar Comunidades',
          ),
        ],
      ),
      
      // ✅ BODY SIN STACK - NORMAL
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarMisComunidades,
          color: const Color(0xFF1565C0),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16), // ✅ PADDING NORMAL
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ CARD PRINCIPAL MEJORADO CON DESPLEGABLE
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1565C0),
                          const Color(0xFF1976D2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // ✅ HEADER DESPLEGABLE
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                            bottom: Radius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Nombre de la comunidad y rol
                                Row(
                                  children: [
                                    Icon(
                                      _comunidadActual!['es_creador'] == true 
                                          ? Icons.admin_panel_settings 
                                          : Icons.groups,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _comunidadActual!['nombre'] ?? 'Mi Comunidad',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _comunidadActual!['es_creador'] == true 
                                                ? 'Eres ADMINISTRADOR' 
                                                : 'Eres MIEMBRO',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white.withOpacity(0.9),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // ✅ FLECHA DESPLEGABLE
                                    AnimatedRotation(
                                      turns: _isExpanded ? 0.5 : 0,
                                      duration: const Duration(milliseconds: 200),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // ✅ CONTENIDO DESPLEGABLE
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          height: _isExpanded ? null : 0,
                          child: _isExpanded ? Container(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Column(
                              children: [
                                const Divider(color: Colors.white54, height: 1),
                                const SizedBox(height: 16),
                                
                                // Stats en fila
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
                                        'Ranking',
                                        '#${rankingMiembros.isNotEmpty ? rankingMiembros.length : 0}',
                                        Icons.emoji_events,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // ✅ CÓDIGO CON ICONO PEQUEÑO AL LADO
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.vpn_key,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'Código de invitación',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _comunidadActual!['codigo_unico'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // ✅ SOLO UN PEQUEÑO ICONO DE COPIAR
                                          GestureDetector(
                                            onTap: _copiarCodigo,
                                            child: const Icon(
                                              Icons.copy,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ) : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Título del ranking
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Color(0xFF1565C0),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Ranking de Miembros',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${rankingMiembros.length} participantes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Ranking completo
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
                            Icons.people_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aún no hay actividad en el ranking',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 100), // ✅ ESPACIO PARA EL WIDGET FLOTANTE
              ],
            ),
          ),
        ),
      ),
      
      // ✅ NUEVO: FLOATING ACTION BUTTON CUSTOMIZADO EN LUGAR DE POSITIONED
      floatingActionButton: Container(
        width: MediaQuery.of(context).size.width - 32, // ✅ ANCHO COMPLETO MENOS MARGIN
        height: 70, // ✅ ALTURA FIJA
        margin: const EdgeInsets.only(bottom: 20), // ✅ MARGEN DEL FONDO
        child: RankingPositionWidget(
          comunidadActual: _comunidadActual,
          miPosicion: miRanking['posicion'],
          misPuntos: miRanking['puntos'],
          totalMiembros: _comunidadActual!['total_miembros'] ?? 0,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // ✅ CENTRADO Y FLOTANTE
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