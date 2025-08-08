import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ NUEVO
import 'dart:async';
import '../widgets/map_view_toggle.dart'; // ✅ NUEVO IMPORT
import '../widgets/center_location_button.dart'; // ✅ NUEVO IMPORT
// ✅ AGREGAR ESTOS IMPORTS AL INICIO
import '../services/points_service.dart';
import '../widgets/points_animation_widget.dart'; 
import 'package:flutter/services.dart';

class NavigationScreen extends StatefulWidget {
  final LatLng destino;
  final String nombreDestino;
  final List<LatLng> puntosRuta;
  final String rutaInfo;

  const NavigationScreen({
    Key? key,
    required this.destino,
    required this.nombreDestino,
    required this.puntosRuta,
    required this.rutaInfo,
  }) : super(key: key);

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> 
    with WidgetsBindingObserver { // ✅ AGREGAR ESTE MIXIN
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  
  // Estado de navegación
  double _distanciaRestante = 0;
  String _tiempoRestante = '';
  
  // ✅ NUEVAS VARIABLES para 2D/3D y seguimiento
  bool _is3DMode = true; // Por defecto 3D en navegación
  bool _isFollowingUser = true; // Por defecto SIEMPRE siguiendo en navegación
  StreamSubscription<Position>? _locationSubscription;

  // ✅ AGREGAR DESPUÉS DE LAS VARIABLES EXISTENTES:
  // Variables para puntos
  bool _mostrandoAnimacionPuntos = false;
  int _puntosAnimacion = 0;
  bool _puntosPositivos = true;
  String? _motivoPuntos;
  bool _puntosInicioOtorgados = false; // Para dar puntos solo 1 vez al iniciar

  // ✅ NUEVAS VARIABLES para detección de salida:
  bool _appEnPrimerPlano = true;
  DateTime? _tiempoSalidaApp;
  bool _navegacionActiva = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _iniciarNavegacion();
    
    // ✅ AGREGAR: Registrar observer para detectar cambios de app
    WidgetsBinding.instance.addObserver(this);
    _navegacionActiva = true;
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _locationSubscription?.cancel();
    
    // ✅ AGREGAR: Quitar observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ NUEVO: Detectar cambios en el estado de la app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (!_navegacionActiva) return; // Solo si está navegando
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // ✅ APP PASÓ A SEGUNDO PLANO
        if (_appEnPrimerPlano) {
          _appEnPrimerPlano = false;
          _tiempoSalidaApp = DateTime.now();
          _restarPuntosPorSalida();
          print('📱 App pasó a segundo plano - restando puntos');
        }
        break;
        
      case AppLifecycleState.resumed:
        // ✅ APP VOLVIÓ AL PRIMER PLANO
        if (!_appEnPrimerPlano) {
          _appEnPrimerPlano = true;
          _mostrarNotificacionRegreso();
          print('📱 App volvió al primer plano');
        }
        break;
        
      case AppLifecycleState.hidden:
        // No hacer nada especial
        break;
    }
  }

  // ✅ NUEVO: Restar puntos por salir de la app
  Future<void> _restarPuntosPorSalida() async {
    try {
      final result = await PointsService.restarPuntosSalidaApp();
      
      if (result['status'] == 'success') {
        print('❌ Puntos restados por salir: ${result['puntos_cambio']}');
        // Los puntos se mostrarán cuando regrese a la app
      }
    } catch (e) {
      print('❌ Error restando puntos por salida: $e');
    }
  }

  // ✅ NUEVO: Mostrar notificación cuando regresa
  void _mostrarNotificacionRegreso() {
    if (_tiempoSalidaApp != null) {
      final tiempoFuera = DateTime.now().difference(_tiempoSalidaApp!);
      final minutosFuera = tiempoFuera.inMinutes;
      
      // Solo mostrar si estuvo fuera más de 3 segundos
      if (tiempoFuera.inSeconds > 3) {
        setState(() {
          _puntosAnimacion = -10; // Puntos restados
          _puntosPositivos = false;
          _motivoPuntos = 'Saliste ${minutosFuera}min';
          _mostrandoAnimacionPuntos = true;
        });
      }
    }
  }

  // ✅ NUEVO: Cargar preferencias 2D/3D
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _is3DMode = prefs.getBool('map_3d_mode') ?? true;
    });
  }

  Future<void> _iniciarNavegacion() async {
    // Crear icono de flecha personalizado
    
    
    // Obtener ubicación inicial
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    
    setState(() {
      _currentPosition = position;
    });

    // Iniciar seguimiento en tiempo real
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3, // Actualizar cada 3 metros
      ),
    ).listen(_onLocationUpdate);

    // ✅ AGREGAR AL FINAL DEL MÉTODO:
    // Otorgar puntos por iniciar ruta después de un momento
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _otorgarPuntosInicioRuta();
      }
    });
  }

  

  // ✅ MODIFICAR TODO EL MÉTODO _onLocationUpdate:
  void _onLocationUpdate(Position position) {
    setState(() {
      _currentPosition = position;
    });

    // ✅ CENTRAR AUTOMÁTICAMENTE si está en modo seguimiento
    if (_isFollowingUser && _mapController != null) {
      // ✅ MEJORADO: Usar el heading (dirección) del GPS para rotar el mapa
      final bearing = position.heading >= 0 ? position.heading : 0.0;
      
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 18.0,
            bearing: bearing, // ✅ ROTACIÓN AUTOMÁTICA según dirección de movimiento
            tilt: _is3DMode ? 60.0 : 0.0,
          ),
        ),
      );
    }

    // Calcular distancia restante al destino
    _calcularDistanciaRestante(position);
  }

  void _calcularDistanciaRestante(Position position) {
    final distanciaMetros = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      widget.destino.latitude,
      widget.destino.longitude,
    );

    setState(() {
      _distanciaRestante = distanciaMetros;
      
      final velocidadKmh = position.speed * 3.6;
      if (velocidadKmh > 1) {
        final tiempoHoras = (distanciaMetros / 1000) / velocidadKmh;
        final minutos = (tiempoHoras * 60).round();
        _tiempoRestante = '${minutos} min';
      } else {
        _tiempoRestante = 'Calculando...';
      }
    });

    // ✅ NUEVO: DETECTAR LLEGADA AL DESTINO
    if (distanciaMetros <= 50 && !_puntosInicioOtorgados) { // 50 metros = llegada
      _otorgarPuntosRutaCompletada();
    }
  }

  // ✅ NUEVO: Toggle entre 2D y 3D en navegación
  void _onViewModeToggle(bool is3D) async {
    setState(() {
      _is3DMode = is3D;
    });

    // Guardar preferencia
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('map_3d_mode', is3D);

    // Aplicar cambio inmediatamente si está siguiendo
    if (_isFollowingUser && _mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 18.0,
            bearing: _currentPosition!.heading,
            tilt: is3D ? 60.0 : 0.0,
          ),
        ),
      );
    }
  }

  // ✅ NUEVO: Manejar botón centrar en navegación
  void _onCenterLocation() {
    // En navegación, simplemente toggle entre seguir/no seguir
    setState(() {
      _isFollowingUser = !_isFollowingUser;
    });

    if (_isFollowingUser && _currentPosition != null && _mapController != null) {
      // Si activa seguimiento, centrar inmediatamente
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 18.0,
            bearing: _currentPosition!.heading,
            tilt: _is3DMode ? 60.0 : 0.0,
          ),
        ),
      );
    }
  }

  void _salirDeNavegacion() {
    Navigator.pop(context);
  }

  // ✅ AGREGAR ESTE MÉTODO DESPUÉS DE _calcularDistanciaRestante:
  Future<void> _otorgarPuntosInicioRuta() async {
    if (_puntosInicioOtorgados) return; // Solo 1 vez por sesión de navegación
    
    try {
      // ✅ VERIFICAR RACHA DIARIA PRIMERO
      final rachaResult = await PointsService.activarRachaDiaria();
      
      bool mostrarPuntosRacha = false;
      if (rachaResult['status'] == 'success' && rachaResult['primera_vez_hoy'] == true) {
        mostrarPuntosRacha = true;
        print('✅ Primera racha del día activada');
      } else if (rachaResult['ya_activada'] == true) {
        print('⏰ Racha ya activada hoy - no dar puntos extra');
      }
      
      // ✅ DAR PUNTOS POR INICIAR RUTA (siempre)
      final result = await PointsService.darPuntosInicioRuta();
      
      if (result['status'] == 'success') {
        // ✅ MOSTRAR ANIMACIÓN DE PUNTOS
        setState(() {
          _puntosAnimacion = result['puntos_cambio'];
          _puntosPositivos = true;
          _motivoPuntos = mostrarPuntosRacha ? 'Inicio + Racha' : 'Inicio';
          _mostrandoAnimacionPuntos = true;
          _puntosInicioOtorgados = true;
        });
        
        print('✅ Puntos otorgados: +${result['puntos_cambio']}');
        
        // ✅ SI ES PRIMERA RACHA DEL DÍA, MOSTRAR MENSAJE EXTRA
        if (mostrarPuntosRacha) {
          // Esperar un momento y mostrar mensaje de racha
          Timer(const Duration(seconds: 3), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔥 ¡Primera ruta del día! Racha activada'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      print('❌ Error otorgando puntos de inicio: $e');
    }
  }

  // ✅ AGREGAR ESTE MÉTODO PARA CUANDO COMPLETE LA RUTA:
  Future<void> _otorgarPuntosRutaCompletada() async {
    try {
      final result = await PointsService.darPuntosRutaCompletada();
      
      if (result['status'] == 'success') {
        setState(() {
          _puntosAnimacion = result['puntos_cambio'];
          _puntosPositivos = true;
          _motivoPuntos = 'Completada';
          _mostrandoAnimacionPuntos = true;
        });
        
        print('✅ Puntos por completar ruta: +${result['puntos_cambio']}');
      }
    } catch (e) {
      print('❌ Error otorgando puntos de completado: $e');
    }
  }

  // ✅ CALLBACK CUANDO TERMINE LA ANIMACIÓN
  void _onAnimacionPuntosComplete() {
    setState(() {
      _mostrandoAnimacionPuntos = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ MAPA PRINCIPAL CON VISTA 3D/2D DINÁMICA
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null 
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : widget.puntosRuta.first,
              zoom: 18.0,
              bearing: _currentPosition?.heading ?? 0,
              tilt: _is3DMode ? 60.0 : 0.0, // ✅ DINÁMICO según preferencia
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _mapController!.setMapStyle(null); // Estilo claro para navegación
            },
            myLocationEnabled: true, // ✅ ACTIVAR punto azul nativo de Google
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            
            // ✅ DETENER SEGUIMIENTO si el usuario mueve el mapa manualmente
            onCameraMove: (CameraPosition position) {
              if (_isFollowingUser && _currentPosition != null) {
                final distance = Geolocator.distanceBetween(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  position.target.latitude,
                  position.target.longitude,
                );
                // Si se mueve más de 30 metros, detener seguimiento
                if (distance > 30) {
                  setState(() {
                    _isFollowingUser = false;
                  });
                }
              }
            },
            
            // Ruta y marcador
            polylines: {
              Polyline(
                polylineId: const PolylineId('ruta_navegacion'),
                points: widget.puntosRuta,
                color: const Color(0xFF1565C0),
                width: 6,
                patterns: [],
              ),
            },
            markers: {
              // Solo marcador de destino
              Marker(
                markerId: const MarkerId('destino'),
                position: widget.destino,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(
                  title: widget.nombreDestino,
                  snippet: 'Destino',
                ),
              ),
            },
          ),

          // ✅ HEADER CON INFORMACIÓN (sin cambios)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Destino
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1565C0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.place,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.nombreDestino,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Navegando...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _salirDeNavegacion,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Información de progreso (sin velocidad)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoStat(
                          icon: Icons.straighten,
                          label: 'Distancia',
                          value: _distanciaRestante > 1000 
                              ? '${(_distanciaRestante / 1000).toStringAsFixed(1)} km'
                              : '${_distanciaRestante.round()} m',
                        ),
                        _buildInfoStat(
                          icon: Icons.schedule,
                          label: 'Tiempo',
                          value: _tiempoRestante.isNotEmpty ? _tiempoRestante : 'Calculando...',
                        ),
                        // ✅ ESPACIO RESERVADO para direcciones futuras
                        _buildInfoStat(
                          icon: Icons.assistant_navigation,
                          label: 'Dirección',
                          value: 'Recto', // ✅ Placeholder para futuras direcciones
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✅ NUEVO: SELECTOR DE VISTA 2D/3D (REPOSICIONADO)
          Positioned(
            top: 250, // ✅ CAMBIO: De 120 a 160 (40px más abajo)
            right: 16, // ✅ CAMBIO: Movido al lado derecho (era left: 16)
            child: MapViewToggle(
              is3DMode: _is3DMode,
              onToggle: _onViewModeToggle,
            ),
          ),

          // ✅ NUEVO: CONTROLES DEL BOTTOM
          Positioned(
            bottom: 55,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ✅ CÍRCULO DE VELOCIDAD (izquierda)
                  _buildSpeedCircle(),
                  
                  // ✅ BOTÓN CENTRAR (centro)
                  CenterLocationButton(
                    onCenter: _onCenterLocation,
                    isFollowing: _isFollowingUser,
                  ),
                  
                  // ✅ ESPACIO RESERVADO (derecha) para futuras funciones
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Icon(
                      Icons.more_horiz,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ NUEVO: WIDGET DE ANIMACIÓN DE PUNTOS
          if (_mostrandoAnimacionPuntos)
            Positioned(
              top: 120, // ✅ Debajo del header, no estorba
              left: 0,
              right: 0,
              child: Center(
                child: PointsAnimationWidget(
                  puntos: _puntosAnimacion,
                  esPositivo: _puntosPositivos,
                  motivo: _motivoPuntos,
                  onAnimationComplete: _onAnimacionPuntosComplete,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1565C0)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ✅ NUEVO: CÍRCULO DE VELOCIDAD
  Widget _buildSpeedCircle() {
    final velocidadKmh = _currentPosition != null 
        ? (_currentPosition!.speed * 3.6).round() 
        : 0;
    
    // ✅ COLORES DINÁMICOS según velocidad
    Color _getSpeedColor(int speed) {
      if (speed == 0) return Colors.grey[400]!;           // Parado
      if (speed <= 5) return Colors.blue;                 // Caminando
      if (speed <= 15) return Colors.green;               // Bicicleta/trote
      if (speed <= 40) return Colors.orange;              // Carro lento
      if (speed <= 80) return const Color(0xFF1565C0);    // Carro normal
      return Colors.red;                                  // Carro rápido
    }

    // ✅ INTENSIDAD DEL EFECTO según velocidad
    double _getPulseIntensity(int speed) {
      if (speed == 0) return 0.0;      // Sin pulso si está parado
      if (speed <= 5) return 0.3;      // Pulso suave
      if (speed <= 15) return 0.5;     // Pulso moderado
      if (speed <= 40) return 0.7;     // Pulso fuerte
      return 1.0;                      // Pulso máximo
    }

    final speedColor = _getSpeedColor(velocidadKmh);
    final pulseIntensity = _getPulseIntensity(velocidadKmh);

    return Container(
      width: 85, // ✅ MÁS GRANDE (era 60)
      height: 85,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // ✅ GRADIENTE DINÁMICO según velocidad
        gradient: RadialGradient(
          colors: [
            speedColor.withOpacity(0.1),
            Colors.white,
            Colors.white,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        // ✅ SOMBRAS MÁS DRAMÁTICAS
        boxShadow: [
          // Sombra principal
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
          // Sombra de color según velocidad
          BoxShadow(
            color: speedColor.withOpacity(pulseIntensity * 0.4),
            blurRadius: 20,
            offset: const Offset(0, 0),
            spreadRadius: 1,
          ),
        ],
        // ✅ BORDE CON COLOR DINÁMICO
        border: Border.all(
          color: speedColor,
          width: 3,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // ✅ SEGUNDO GRADIENTE INTERNO
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              speedColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ NÚMERO MÁS GRANDE Y CON COLOR DINÁMICO
            Text(
              '$velocidadKmh',
              style: TextStyle(
                fontSize: 22, // ✅ MÁS GRANDE (era 16)
                fontWeight: FontWeight.w900, // ✅ MÁS GRUESO
                color: speedColor,
                letterSpacing: 1.0,
                // ✅ SOMBRA EN EL TEXTO
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                    color: speedColor.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            // ✅ UNIDADES MÁS VISIBLES
            Text(
              'km/h',
              style: TextStyle(
                fontSize: 11, // ✅ MÁS GRANDE (era 8)
                color: speedColor.withOpacity(0.8),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            
            // ✅ INDICADOR VISUAL SEGÚN VELOCIDAD
            Container(
              width: 30,
              height: 2,
              decoration: BoxDecoration(
                color: speedColor,
                borderRadius: BorderRadius.circular(1),
                boxShadow: [
                  BoxShadow(
                    color: speedColor.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}