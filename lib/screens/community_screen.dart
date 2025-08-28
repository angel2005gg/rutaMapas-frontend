import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ NUEVO: Para copiar al portapapeles
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // ✅ NUEVO: Persistir comunidad actual
import '../services/comunidad_service.dart';
import '../widgets/community_drawer.dart';
import '../widgets/community_management_sheet.dart';
import '../widgets/ranking_position_widget.dart'; // ✅ NUEVO IMPORT

// ✅ MOVIDO: Enum a nivel superior
enum RankingView { competencia, total }

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ComunidadService _comunidadService = ComunidadService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(); // ✅
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _misComunidades = [];
  Map<String, dynamic>? _comunidadActual;
  
  // ✅ NUEVO: Estado para controlar el desplegable
  bool _isExpanded = false;

  // ✅ NUEVO: Estado de ranking de competencia vs total
  List<Map<String, dynamic>> _rankingCompetencia = [];
  List<Map<String, dynamic>> _rankingTotal = [];
  int _rankingDuracionDias = 7; // por defecto
  bool _isLoadingRanking = false;

  // Selector de vista (enum definido a nivel superior)
  RankingView _selectedRanking = RankingView.competencia;

  void _cambiarComunidad(Map<String, dynamic> comunidad) async {
    setState(() {
      _comunidadActual = comunidad;
      _isExpanded = false;
      _rankingCompetencia = [];
      _rankingTotal = List<Map<String, dynamic>>.from(comunidad['usuarios'] ?? []);
    });
    // ✅ Persistir selección
    final id = comunidad['id'];
    if (id != null) {
      await _storage.write(key: 'comunidad_actual_id', value: '$id');
    }
    Navigator.pop(context);
    _cargarRankingCompetencia();
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
              _rankingTotal = [];
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
              _rankingTotal = List<Map<String, dynamic>>.from(_comunidadActual?['usuarios'] ?? []);
            }
          });

          // ✅ Persistir o limpiar selección
          final idSel = _comunidadActual?['id'];
          if (idSel != null) {
            await _storage.write(key: 'comunidad_actual_id', value: '$idSel');
          } else {
            await _storage.delete(key: 'comunidad_actual_id');
          }

          // ✅ Una vez elegida la comunidad actual, cargar ranking
          if (_comunidadActual != null) {
            await _cargarRankingCompetencia();
          }
        } else {
          setState(() {
            _misComunidades = [];
            _comunidadActual = null;
            _rankingCompetencia = [];
          });
          // ✅ limpiar selección si no hay comunidades
          await _storage.delete(key: 'comunidad_actual_id');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _misComunidades = [];
          _comunidadActual = null;
          _rankingCompetencia = [];
        });
        await _storage.delete(key: 'comunidad_actual_id');
        
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

  // ✅ NUEVO: carga de ranking de competencia activa (sin sobrescribir comunidad)
  Future<void> _cargarRankingCompetencia() async {
    if (_comunidadActual == null) return;
    setState(() => _isLoadingRanking = true);
    try {
      final id = _comunidadActual!['id'] is int
          ? _comunidadActual!['id']
          : int.tryParse('${_comunidadActual!['id']}');
      if (id == null) return;

      final res = await _comunidadService.getRankingActual(
        comunidadId: id,
        duracionDias: _rankingDuracionDias,
      );

      if (!mounted) return;

      if (res['status'] == 'success') {
        final List data = (res['data'] ?? []) as List;
        final ranking = data.map<Map<String, dynamic>>((e) => {
              'usuario_id': e['usuario_id'],
              'nombre': e['nombre'],
              'puntaje': e['puntos'],
              'posicion': e['posicion'],
              'racha_actual': e['racha_actual'],
            }).toList();

        setState(() {
          _rankingCompetencia = ranking;
        });
      } else {
        // mensaje informativo
        final msg = (res['message'] ?? 'No se pudo cargar el ranking').toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar ranking: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingRanking = false);
    }
  }

  // ✅ Actualizar para recibir la lista a evaluar
  Map<String, dynamic> _obtenerMiPosicion(List<Map<String, dynamic>> usuarios) {
    if (_comunidadActual == null) {
      return {'posicion': null, 'puntos': 0};
    }
    if (usuarios.isEmpty) return {'posicion': null, 'puntos': 0};

    // 1) Intentar encontrar al usuario actual por la marca del backend
    Map<String, dynamic> yo = usuarios.firstWhere(
      (u) => u['es_usuario_actual'] == true || u['es_actual'] == true,
      orElse: () => {},
    );

    if (yo.isNotEmpty) {
      // Si ya viene la posición desde el backend, úsala
      final pos = (yo['posicion'] is int) ? yo['posicion'] as int : null;
      final pts = (yo['puntaje'] ?? 0) is int ? yo['puntaje'] as int : 0;

      if (pos != null && pos > 0) {
        return {'posicion': pos, 'puntos': pts};
      }

      // Si no viene 'posicion', calcularla por orden de puntaje desc
      final ordenados = [...usuarios]..sort(
        (a, b) => (b['puntaje'] ?? 0).compareTo(a['puntaje'] ?? 0),
      );
      final idx = ordenados.indexWhere((u) => identical(u, yo));
      return {
        'posicion': idx >= 0 ? idx + 1 : null,
        'puntos': pts,
      };
    }

    // 2) Si no hay marca del backend, usar el orden por 'posicion' si existe
    if (usuarios.isNotEmpty && usuarios.first.containsKey('posicion')) {
      // Buscar el primer elemento marcado como actual por comparación simple:
      // si backend no marca, devolver null (evita mostrar posición errónea)
      return {'posicion': null, 'puntos': 0};
    }

    // 3) Fallback: orden por puntaje desc y no sabemos cuál es "yo"
    // Dejar "sin clasificar" para evitar indicar una posición incorrecta.
    return {'posicion': null, 'puntos': 0};
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
    final rankingMiembros = _selectedRanking == RankingView.competencia
        ? _rankingCompetencia
        : _rankingTotal;
    final miRanking = _obtenerMiPosicion(rankingMiembros);

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
          onRefresh: () async {
            await _cargarMisComunidades();
            await _cargarRankingCompetencia();
          },
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
                    Expanded(
                      child: Text(
                        'Ranking de Miembros',
                        style: const TextStyle(
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
                const SizedBox(height: 12),

                // ✅ NUEVO: Botones de cambio de vista (horizontal, responsive)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _selectedRanking = RankingView.competencia),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _selectedRanking == RankingView.competencia
                              ? const Color(0xFF1565C0)
                              : Colors.white,
                          foregroundColor: _selectedRanking == RankingView.competencia
                              ? Colors.white
                              : const Color(0xFF1565C0),
                          side: BorderSide(
                            color: _selectedRanking == RankingView.competencia
                                ? const Color(0xFF1565C0)
                                : Colors.grey[400]!,
                          ),
                        ),
                        child: const Text('Competencia'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _selectedRanking = RankingView.total),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _selectedRanking == RankingView.total
                              ? const Color(0xFF1565C0)
                              : Colors.white,
                          foregroundColor: _selectedRanking == RankingView.total
                              ? Colors.white
                              : const Color(0xFF1565C0),
                          side: BorderSide(
                            color: _selectedRanking == RankingView.total
                                ? const Color(0xFF1565C0)
                                : Colors.grey[400]!,
                          ),
                        ),
                        child: const Text('Total'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Loader cuando se selecciona competencia y aún no cargó
                if (_selectedRanking == RankingView.competencia && _isLoadingRanking && _rankingCompetencia.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                    ),
                  )
                else if (rankingMiembros.isNotEmpty)
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
                            _selectedRanking == RankingView.competencia
                                ? 'Aún no hay actividad en la competencia'
                                : 'Aún no hay miembros con puntaje',
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

                const SizedBox(height: 100),
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

  // ✅ Widget para cada item del ranking (usa puntos de competencia: 'puntaje')
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
                      '${miembro['puntaje'] ?? 0} pts', // puntos de competencia
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (miembro['racha_actual'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Racha: ${miembro['racha_actual']}',
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

    // ✅ LÓGICA PRINCIPAL
    if (_comunidadActual == null) {
      return _buildSinComunidades();
    } else {
      return _buildDashboardComunidad();
    }
  }

  // ✅ NUEVOS MÉTODOS: abrir gestión y copiar código
  void _abrirGestionComunidades() {
    if (_comunidadActual == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return CommunityManagementSheet(
          misComunidades: _misComunidades,
          comunidadActual: _comunidadActual!,
          onComunidadUpdated: () {
            Navigator.of(ctx).pop();
            _cargarMisComunidades();
          },
        );
      },
    );
  }

  Future<void> _copiarCodigo() async {
    final code = _comunidadActual?['codigo_unico']?.toString();
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado')),
    );
  }
}