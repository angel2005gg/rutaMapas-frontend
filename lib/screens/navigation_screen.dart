import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:ui' as ui; // Flecha de navegación dibujada
import '../widgets/map_view_toggle.dart';
import '../widgets/center_location_button.dart';
import '../services/points_service.dart';
import '../widgets/points_animation_widget.dart';
import '../services/distraction_monitor_service.dart';
import '../widgets/driving_safety_overlay.dart';
import '../widgets/route_points_history_widget.dart'; // RoutePointEvent
import '../widgets/route_points_summary_sheet.dart';
import 'dart:math' as math; // ➕ Para cálculos de navegación

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
    with WidgetsBindingObserver {
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

  // ➕ Evita desactivar seguimiento durante movimientos programáticos
  bool _isProgrammaticCameraMove = false;

  // ✅ Icono de flecha de navegación
  BitmapDescriptor? _navArrowIcon;

  // ✅ AGREGAR DESPUÉS DE LAS VARIABLES EXISTENTES:
  // Variables para puntos
  bool _mostrandoAnimacionPuntos = false;
  int _puntosAnimacion = 0;
  bool _puntosPositivos = true;
  String? _motivoPuntos;
  bool _puntosInicioOtorgados = false; // Para dar puntos solo 1 vez al iniciar

  // ✅ NUEVAS VARIABLES para detección de salida:
  bool _navegacionActiva = false;

  final DistractionMonitorService _monitor = DistractionMonitorService.instance; // ✅ NUEVO

  // ✅ NUEVO: Variable para overlay de seguridad
  bool _showAvisoSeguridad = true; // ✅ mostrar overlay al iniciar

  // Historial en vivo de puntos de la ruta
  final List<RoutePointEvent> _pointEvents = [];
  // Flag para mostrar resumen final una sola vez
  bool _finalResumenMostrado = false;

  // ➕ Estado de ruta y progreso (flecha en polyline)
  List<LatLng> _route = [];
  int _progressIndex = 0;
  LatLng? _arrowPos;
  double _arrowBearing = 0.0;
  Set<Polyline> _navPolylines = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _iniciarNavegacion();
    _loadNavArrowIcon(); // Cargar flecha de navegación
    WidgetsBinding.instance.addObserver(this);
    _navegacionActiva = true;
    _monitor.startSession();
    // _showAvisoSeguridad ya true por defecto
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _locationSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    // ✅ Detener monitoreo
    _monitor.stopSession();

    super.dispose();
  }

  // ✅ DIBUJAR ICONO DE FLECHA PARA NAVEGACIÓN
  Future<void> _loadNavArrowIcon() async {
    try {
      const double size = 120; // px
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Fondo transparente
      final bgPaint = ui.Paint()..color = const Color(0x00000000);
      canvas.drawRect(ui.Rect.fromLTWH(0, 0, size, size), bgPaint);

      // Sombra sutil
      final shadowPaint = ui.Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);

      // Flecha principal (triángulo)
      final arrowColor = const Color(0xFF1565C0);
      final arrowPaint = ui.Paint()
        ..color = arrowColor
        ..style = ui.PaintingStyle.fill;
      final borderPaint = ui.Paint()
        ..color = Colors.white
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 4;

      final ui.Path head = ui.Path()
        ..moveTo(size * 0.5, size * 0.12) // punta arriba
        ..lineTo(size * 0.78, size * 0.56)
        ..lineTo(size * 0.22, size * 0.56)
        ..close();

      // Cola de la flecha
      final ui.RRect tail = ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(
          center: ui.Offset(size * 0.5, size * 0.78),
          width: size * 0.18,
          height: size * 0.34,
        ),
        ui.Radius.circular(size * 0.09),
      );

      // Dibujar sombra
      canvas.save();
      canvas.translate(2, 4);
      canvas.drawPath(head, shadowPaint);
      canvas.drawRRect(tail, shadowPaint);
      canvas.restore();

      // Dibujar flecha
      canvas.drawPath(head, arrowPaint);
      canvas.drawPath(head, borderPaint);
      canvas.drawRRect(tail, arrowPaint);
      canvas.drawRRect(tail, borderPaint);

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      if (!mounted) return;
      setState(() {
        _navArrowIcon = BitmapDescriptor.fromBytes(bytes);
      });
    } catch (e) {
      // Si falla, no bloquea UI
      debugPrint('Error generando icono de flecha: $e');
    }
  }

  // ✅ DETECCIÓN de ciclo de vida: medimos sólo cuando hay navegación activa
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!_navegacionActiva) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _monitor.markBackgroundStart();
      print('📱 App en background (monitoreo activo)');
    } else if (state == AppLifecycleState.resumed) {
      _procesarRegresoDesdeBackground();
    }
  }

  Future<void> _procesarRegresoDesdeBackground() async {
    try {
      final resumen = await _monitor.summarizeOnForeground();
      if (!mounted) return;

      // Mostrar burbujas separadas por categoría para evitar confusiones
      void _pushEvent(int puntos, String motivo) {
        if (puntos == 0) return;
        _pointEvents.add(RoutePointEvent(
          puntos: puntos,
          motivo: motivo,
          timestamp: DateTime.now(),
        ));
        setState(() {
          _mostrandoAnimacionPuntos = true;
          _puntosAnimacion = puntos.abs();
          _puntosPositivos = puntos > 0;
          _motivoPuntos = motivo;
        });
      }

      // Apps abiertas (si hubo)
      if (resumen.deltaApps != 0) {
        _pushEvent(resumen.deltaApps, '${resumen.appsAbiertas} app(s) abiertas');
        await PointsService.ajustarPuntosPorDistracciones(
          resumen.deltaApps,
          'Uso de otras apps durante la ruta',
        );
      }

      // Llamadas contestadas (negativas)
      if (resumen.deltaLlamadasContestadas != 0) {
        _pushEvent(resumen.deltaLlamadasContestadas, '${resumen.llamadasContestadas} llamada(s) contestada(s)');
        await PointsService.ajustarPuntosPorDistracciones(
          resumen.deltaLlamadasContestadas,
          'Llamada contestada en ruta',
        );
      }

      // Llamadas rechazadas/no contestadas (positivas)
      if (resumen.deltaLlamadasRechazadas != 0) {
        _pushEvent(resumen.deltaLlamadasRechazadas, '${resumen.llamadasRechazadasONoContestadas} llamada(s) rechazadas/no contestadas');
        await PointsService.ajustarPuntosPorDistracciones(
          resumen.deltaLlamadasRechazadas,
          'Llamada rechazada/no contestada (bien)',
        );
      }

      if (resumen.deltaPuntos == 0) {
        print('✅ Sin cambios de puntos en este regreso');
      }
    } catch (e) {
      print('❌ Error procesando regreso: $e');
    }
  }

  // 🚫 Desactivado: ya no se restan puntos por salir de la app
  // Future<void> _restarPuntosPorSalida() async {
  //   print('ℹ️ _restarPuntosPorSalida() desactivado');
  //   return; // no-op
  // }

  // ✅ NUEVO: Mostrar notificación cuando regresa (no usado)
  // void _mostrarNotificacionRegreso() {
  //   if (_tiempoSalidaApp != null) {
  //     final tiempoFuera = DateTime.now().difference(_tiempoSalidaApp!);
  //     final minutosFuera = tiempoFuera.inMinutes;
  //     if (tiempoFuera.inSeconds > 3) {
  //       setState(() {
  //         _puntosAnimacion = -10;
  //         _puntosPositivos = false;
  //         _motivoPuntos = 'Saliste ${minutosFuera}min';
  //         _mostrandoAnimacionPuntos = true;
  //       });
  //     }
  //   }
  // }

  // ✅ NUEVO: Cargar preferencias 2D/3D
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _is3DMode = prefs.getBool('map_3d_mode') ?? true;
    });
  }

  Future<void> _iniciarNavegacion() async {
    // Obtener ubicación inicial (solo para métricas; NO posiciona flecha)
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    
    setState(() {
      _currentPosition = position;
      // ➕ Inicializar flecha al INICIO DE LA RUTA
      _route = List<LatLng>.from(widget.puntosRuta);
      _progressIndex = 0;
      _arrowPos = _route.isNotEmpty ? _route.first : null;
      _arrowBearing = (_route.length >= 2)
          ? _bearingBetween(_route[0], _route[1])
          : 0.0;
    });

    // ➕ Construir polyline restante al inicio
    _rebuildRemainingPolyline();

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

  // ➕ Recalcula polyline restante (recorta el tramo ya pasado)
  void _rebuildRemainingPolyline() {
    if (_route.isEmpty || _progressIndex >= _route.length - 1) {
      setState(() => _navPolylines = {});
      return;
    }
    final remaining = _route.sublist(_progressIndex);
    setState(() {
      _navPolylines = {
        Polyline(
          polylineId: const PolylineId('ruta_restante'),
          points: remaining,
          color: const Color(0xFF1565C0),
          width: 6,
        ),
      };
    });
  }

  // ➕ Avanza el progreso de la flecha sobre la ruta según la ubicación real
  void _updateRouteProgress(Position pos) {
    if (_route.isEmpty) return;

    // Buscar el punto más cercano desde el índice actual hacia adelante (no retroceder)
    double best = double.infinity;
    int bestIdx = _progressIndex;
    for (int i = _progressIndex; i < _route.length; i++) {
      final p = _route[i];
      final d = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        p.latitude,
        p.longitude,
      );
      if (d < best) {
        best = d;
        bestIdx = i;
        if (best < 8) break; // suficiente cercanía, salir temprano
      }
    }

    // Actualizar progreso solo si avanzó
    if (bestIdx > _progressIndex) {
      setState(() {
        _progressIndex = bestIdx;
        _arrowPos = _route[_progressIndex];
        if (_progressIndex + 1 < _route.length) {
          _arrowBearing = _bearingBetween(
            _route[_progressIndex],
            _route[_progressIndex + 1],
          );
        }
      });
      _rebuildRemainingPolyline();
    } else {
      // Mantener orientación hacia el siguiente punto si existe
      if (_progressIndex + 1 < _route.length) {
        _arrowBearing = _bearingBetween(
          _route[_progressIndex],
          _route[_progressIndex + 1],
        );
      }
      // Asegurar posición en el punto actual de la ruta
      _arrowPos = _route[_progressIndex];
    }
  }

  // ➕ Bearing geodésico entre dos coordenadas
  double _bearingBetween(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    double brng = math.atan2(y, x);
    brng = brng * 180.0 / math.pi;
    return (brng + 360.0) % 360.0;
  }

  // ✅ MODIFICAR _onLocationUpdate para usar flecha y recorte
  void _onLocationUpdate(Position position) {
    setState(() {
      _currentPosition = position;
    });

    _updateRouteProgress(position);

    if (_isFollowingUser && _mapController != null && _arrowPos != null) {
      _isProgrammaticCameraMove = true;
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _arrowPos!,
            zoom: 18.0,
            bearing: _is3DMode ? _arrowBearing : 0.0,
            tilt: _is3DMode ? 60.0 : 0.0,
          ),
        ),
      ).whenComplete(() {
        // Esperar a onCameraIdle para limpiar bandera
      });
    }

    _calcularDistanciaRestante(position);
  }

  // ✅ Construir marcadores (flecha en la ruta + destino)
  Set<Marker> _buildMarkers() {
    final set = <Marker>{};

    // Marcador de destino
    set.add(
      Marker(
        markerId: const MarkerId('destino'),
        position: widget.destino,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: widget.nombreDestino,
          snippet: 'Destino',
        ),
        zIndex: 1,
      ),
    );

    // Flecha de navegación pegada a la ruta (NO al GPS crudo)
    if (_arrowPos != null && _navArrowIcon != null) {
      set.add(
        Marker(
          markerId: const MarkerId('nav_arrow'),
          position: _arrowPos!,
          icon: _navArrowIcon!,
          rotation: _arrowBearing,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          zIndex: 9999,
        ),
      );
    }

    return set;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _arrowPos ?? (widget.puntosRuta.isNotEmpty ? widget.puntosRuta.first : widget.destino),
              zoom: 18.0,
              bearing: _is3DMode ? _arrowBearing : 0.0,
              tilt: _is3DMode ? 60.0 : 0.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _mapController!.setMapStyle(null);
            },
            myLocationEnabled: false, // ⛔️ Ocultar punto azul
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            onCameraMoveStarted: () {
              // No hacer nada aquí; onCameraMove decide si fue gesto
            },
            onCameraMove: (CameraPosition position) {
              if (!_isFollowingUser || _arrowPos == null) return;

              // Si el movimiento NO es programático y el usuario desplazó el mapa lejos, salir de seguimiento
              if (!_isProgrammaticCameraMove) {
                final distance = Geolocator.distanceBetween(
                  _arrowPos!.latitude,
                  _arrowPos!.longitude,
                  position.target.latitude,
                  position.target.longitude,
                );
                if (distance > 30) {
                  setState(() {
                    _isFollowingUser = false;
                  });
                }
              }
            },
            onCameraIdle: () {
              // Fin de animación programática
              _isProgrammaticCameraMove = false;
            },
            // ➕ Polyline restante (el tramo pasado desaparece)
            polylines: _navPolylines,
            markers: _buildMarkers(),
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

          // ✅ NUEVO: Botón flotante para abrir historial cuando se quiera
          Positioned(
            bottom: 130,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'historial_puntos',
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1565C0),
              elevation: 4,
              onPressed: _abrirHistoriaManual,
              child: const Icon(Icons.receipt_long),
            ),
          ),

          // ✅ NUEVO: OVERLAY DE SEGURIDAD (siempre arriba)
          if (_showAvisoSeguridad)
            DrivingSafetyOverlay(
              onAccept: () => setState(() => _showAvisoSeguridad = false),
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

  // ➕ Otorgar puntos al iniciar la ruta (una sola vez por sesión)
  Future<void> _otorgarPuntosInicioRuta() async {
    if (_puntosInicioOtorgados) return;
    try {
      await PointsService.darPuntosInicioRuta();
      if (!mounted) return;
      setState(() {
        _puntosInicioOtorgados = true;
        _mostrandoAnimacionPuntos = true;
        _puntosAnimacion = 1; // antes 5
        _puntosPositivos = true;
        _motivoPuntos = 'Ruta iniciada';
        _pointEvents.add(RoutePointEvent(
          puntos: 1, // antes 5
          motivo: 'Ruta iniciada',
          timestamp: DateTime.now(),
        ));
      });

      // Activar racha diaria (si corresponde)
      await PointsService.activarRachaDiaria();
    } catch (e) {
      debugPrint('❌ Error otorgando puntos inicio: $e');
    }
  }

  // ➕ Cálculo de distancia restante y tiempo estimado. Dispara llegada si aplica.
  void _calcularDistanciaRestante(Position position) {
    try {
      final dist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        widget.destino.latitude,
        widget.destino.longitude,
      );
      String tiempo = 'Calculando...';
      final v = position.speed; // m/s
      if (v > 0.3) {
        final segundos = (dist / v).round();
        final m = (segundos / 60).floor();
        final s = (segundos % 60).toString().padLeft(2, '0');
        tiempo = m > 0 ? '${m}m ${s}s' : '${segundos}s';
      }
      setState(() {
        _distanciaRestante = dist;
        _tiempoRestante = tiempo;
      });

      // Llegada al destino
      if (dist <= 50 && !_finalResumenMostrado) {
        _onLlegadaADestino();
      }
    } catch (e) {
      debugPrint('❌ Error calculando distancia restante: $e');
    }
  }

  // ➕ Handler de llegada: otorgar puntos y mostrar resumen final una sola vez
  Future<void> _onLlegadaADestino() async {
    if (_finalResumenMostrado) return;
    _finalResumenMostrado = true;
    try {
      await PointsService.darPuntosRutaCompletada();
      if (!mounted) return;
      setState(() {
        _mostrandoAnimacionPuntos = true;
        _puntosAnimacion = 15;
        _puntosPositivos = true;
        _motivoPuntos = 'Ruta completada';
        _pointEvents.add(RoutePointEvent(
          puntos: 15,
          motivo: 'Ruta completada',
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      debugPrint('❌ Error otorgando puntos de llegada: $e');
    }

    // Mostrar resumen final
    _mostrarResumenFinal();

    // detener navegación
    _positionStream?.cancel();
    _navegacionActiva = false;
  }

  // ➕ Abrir hoja con resumen final
  void _mostrarResumenFinal() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(12),
            child: RoutePointsSummarySheet(
              events: _pointEvents,
              esFinal: true,
            ),
          ),
        );
      },
    );
  }

  // ➕ Salir de navegación limpiamente
  void _salirDeNavegacion() {
    _positionStream?.cancel();
    _locationSubscription?.cancel();
    _navegacionActiva = false;
    _monitor.stopSession();
    if (mounted) Navigator.of(context).maybePop();
  }

  // ➕ Toggle 2D/3D desde el widget de UI
  void _onViewModeToggle(bool is3D) {
    setState(() {
      _is3DMode = is3D;
    });

    if (_isFollowingUser && _mapController != null) {
      final target = _arrowPos ?? (widget.puntosRuta.isNotEmpty ? widget.puntosRuta.first : widget.destino);
      _isProgrammaticCameraMove = true;
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: 18.0,
            bearing: _is3DMode ? _arrowBearing : 0.0,
            tilt: _is3DMode ? 60.0 : 0.0,
          ),
        ),
      );
    }
  }

  // ➕ Centrar la cámara en la flecha y retomar seguimiento
  void _onCenterLocation() {
    setState(() {
      _isFollowingUser = true;
    });
    final target = _arrowPos ?? (widget.puntosRuta.isNotEmpty ? widget.puntosRuta.first : widget.destino);
    if (_mapController != null) {
      _isProgrammaticCameraMove = true;
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: 18.0,
            bearing: _is3DMode ? _arrowBearing : 0.0,
            tilt: _is3DMode ? 60.0 : 0.0,
          ),
        ),
      );
    }
  }

  // ➕ Callback al terminar animación de puntos
  void _onAnimacionPuntosComplete() {
    if (!mounted) return;
    setState(() {
      _mostrandoAnimacionPuntos = false;
      _motivoPuntos = null;
    });
  }

  // ➕ Abrir historial manual en hoja inferior
  void _abrirHistoriaManual() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(12),
            child: RoutePointsSummarySheet(
              events: _pointEvents,
              esFinal: false,
            ),
          ),
        );
      },
    );
  }
}