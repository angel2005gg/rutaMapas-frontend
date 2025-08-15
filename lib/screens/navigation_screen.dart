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
      final canvas = Canvas(recorder);

      // Fondo transparente
      final bgPaint = Paint()..color = const Color(0x00000000);
      canvas.drawRect(Rect.fromLTWH(0, 0, size, size), bgPaint);

      // Sombra sutil
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);

      // Flecha principal (triángulo)
      final arrowColor = const Color(0xFF1565C0);
      final arrowPaint = Paint()
        ..color = arrowColor
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      final Path head = Path()
        ..moveTo(size * 0.5, size * 0.12) // punta arriba
        ..lineTo(size * 0.78, size * 0.56)
        ..lineTo(size * 0.22, size * 0.56)
        ..close();

      // Cola de la flecha
      final RRect tail = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size * 0.5, size * 0.78),
          width: size * 0.18,
          height: size * 0.34,
        ),
        Radius.circular(size * 0.09),
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

      final motivo = resumen.motivo.isEmpty ? 'Resumen de distracciones' : resumen.motivo;

      // ✅ Si hay delta, mostrar animación y enviar ajuste
      if (resumen.deltaPuntos != 0) {
        setState(() {
          _mostrandoAnimacionPuntos = true;
          _puntosAnimacion = resumen.deltaPuntos.abs();
          _puntosPositivos = resumen.deltaPuntos > 0;
          _motivoPuntos = motivo;
          _pointEvents.add(RoutePointEvent(
            puntos: resumen.deltaPuntos,
            motivo: motivo,
            timestamp: DateTime.now(),
          ));
        });

        final resp = await PointsService.ajustarPuntosPorDistracciones(
          resumen.deltaPuntos,
          'Distracciones durante la ruta: $motivo',
        );
        print('🎯 Ajuste puntos distracciones: $resp');
      } else {
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

    // ✅ NUEVO: DETECTAR LLEGADA AL DESTINO (mostrar una sola vez)
    if (distanciaMetros <= 50 && !_finalResumenMostrado) {
      _finalResumenMostrado = true;
      _otorgarPuntosRutaCompletada();
      // Abrir resumen final con felicitación
      _mostrarResumenFinal();
    }
  }

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
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.only(top: 8),
              child: SingleChildScrollView(
                controller: controller,
                child: RoutePointsSummarySheet(
                  events: _pointEvents,
                  esFinal: true,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _abrirHistoriaManual() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => RoutePointsSummarySheet(events: _pointEvents),
    );
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
    if (_puntosInicioOtorgados) return;
    try {
      // ✅ Primero: si se saltó un día, resetear racha
      await PointsService.verificarRachaYResetSiCorresponde();

      // ✅ Luego: activar racha de hoy (una sola vez por día)
      final rachaResult = await PointsService.activarRachaDiaria();
      bool mostrarPuntosRacha = false;

      if (rachaResult['status'] == 'success' && rachaResult['primera_vez_hoy'] == true) {
        mostrarPuntosRacha = true;
      } else if (rachaResult['ya_activada'] == true) {
        mostrarPuntosRacha = false;
      }
      
      // ✅ DAR PUNTOS POR INICIAR RUTA (siempre)
      final result = await PointsService.darPuntosInicioRuta();
      
      if (result['status'] == 'success') {
        // ✅ MOSTRAR ANIMACIÓN DE PUNTOS
        setState(() {
          final delta = result['puntos_cambio'] is int ? result['puntos_cambio'] as int : int.tryParse('${result['puntos_cambio']}') ?? 0;
          _puntosAnimacion = delta;
          _puntosPositivos = true;
          _motivoPuntos = mostrarPuntosRacha ? 'Inicio + Racha' : 'Inicio';
          _mostrandoAnimacionPuntos = true;
          _puntosInicioOtorgados = true;
          _pointEvents.add(RoutePointEvent(
            puntos: delta,
            motivo: _motivoPuntos ?? 'Inicio',
            timestamp: DateTime.now(),
          ));
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
          final delta = result['puntos_cambio'] is int ? result['puntos_cambio'] as int : int.tryParse('${result['puntos_cambio']}') ?? 0;
          _puntosAnimacion = delta;
          _puntosPositivos = true;
          _motivoPuntos = 'Completada';
          _mostrandoAnimacionPuntos = true;
          _pointEvents.add(RoutePointEvent(
            puntos: delta,
            motivo: 'Ruta completada',
            timestamp: DateTime.now(),
          ));
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

  // ✅ Construir marcadores (flecha + destino)
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

    // Flecha de navegación en la ubicación actual
    if (_currentPosition != null && _navArrowIcon != null) {
      final bearing = _currentPosition!.heading >= 0 ? _currentPosition!.heading : 0.0;
      set.add(
        Marker(
          markerId: const MarkerId('nav_arrow'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: _navArrowIcon!,
          rotation: bearing,
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
            myLocationEnabled: false, // ⛔️ Ocultar punto azul durante navegación
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
}