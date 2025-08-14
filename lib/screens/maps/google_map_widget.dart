import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../services/location_service.dart';
import '../../services/places_service.dart';
import '../../services/directions_service.dart';
import '../../services/multi_routes_service.dart';
import '../../widgets/map_type_selector.dart';
import '../../widgets/map_view_toggle.dart'; // ✅ NUEVO IMPORT
import '../../widgets/center_location_button.dart'; // ✅ NUEVO IMPORT
// import '../../widgets/route_time_widget.dart';
import '../../widgets/safety_warning_widget.dart';
class GoogleMapWidget extends StatefulWidget {
  final Function(String)? onRutaCalculada;

  const GoogleMapWidget({
    Key? key,
    this.onRutaCalculada,
  }) : super(key: key);

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  String _errorMessage = '';
  Set<Marker> _allMarkers = {};
  bool _showingPlaces = false;
  
  // Variables para rutas
  Set<Polyline> _polylines = {};
  String? _rutaInfo;
  bool _mostrandoRuta = false;
  MapType _currentMapType = MapType.normal;

  // ✅ NUEVO: trackear permiso para activar el punto azul en release
  bool _hasLocationPermission = false;

  // ✅ NUEVAS VARIABLES
  bool _is3DMode = true; // Por defecto 3D
  bool _isFollowingUser = false; // Si está siguiendo al usuario
  StreamSubscription<Position>? _locationSubscription; // Para seguimiento en tiempo real
  List<LatLng> _puntosRutaActual = [];

  // Rutas múltiples
  List<Map<String, dynamic>> _rutasDisponibles = [];
  int _rutaSeleccionada = 0;
  bool _mostrandoRutasMultiples = false;

  static const String _colorfulMapStyle = '''
[
  { "elementType": "geometry", "stylers": [ { "color": "#0d1421" } ] },

  // 🔵 HABILITAR ICONOS/ETIQUETAS DE POI
  { "elementType": "labels.icon", "stylers": [ { "visibility": "on" } ] },
  { "featureType": "poi", "elementType": "labels.icon", "stylers": [ { "visibility": "on" } ] },

  { "elementType": "labels.text.fill", "stylers": [ { "color": "#e5e7eb" } ] },
  { "elementType": "labels.text.stroke", "stylers": [ { "color": "#0d1421" } ] },

  { "featureType": "administrative", "elementType": "geometry", "stylers": [ { "color": "#1e40af" } ] },
  { "featureType": "administrative.country", "elementType": "labels.text.fill", "stylers": [ { "color": "#f3f4f6" } ] },
  { "featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [ { "color": "#f3f4f6" } ] },
  { "featureType": "administrative.neighborhood", "elementType": "labels.text.fill", "stylers": [ { "color": "#9ca3af" } ] },

  { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [ { "color": "#d1d5db" } ] },
  { "featureType": "poi.park", "elementType": "geometry", "stylers": [ { "color": "#065f46" } ] },
  { "featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [ { "color": "#34d399" } ] },

  { "featureType": "road", "elementType": "geometry.fill", "stylers": [ { "color": "#1f2937" } ] },
  { "featureType": "road", "elementType": "labels.text.fill", "stylers": [ { "color": "#d1d5db" } ] },
  { "featureType": "road.arterial", "elementType": "geometry", "stylers": [ { "color": "#374151" } ] },
  { "featureType": "road.arterial", "elementType": "labels.text.fill", "stylers": [ { "color": "#e5e7eb" } ] },
  { "featureType": "road.highway", "elementType": "geometry", "stylers": [ { "color": "#4b5563" } ] },
  { "featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [ { "color": "#f3f4f6" } ] },
  { "featureType": "road.local", "elementType": "geometry", "stylers": [ { "color": "#1f2937" } ] },
  { "featureType": "road.local", "elementType": "labels.text.fill", "stylers": [ { "color": "#9ca3af" } ] },

  { "featureType": "transit", "stylers": [ { "visibility": "off" } ] },

  { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#1e3a5f" } ] },
  { "featureType": "water", "elementType": "labels.text.fill", "stylers": [ { "color": "#93c5fd" } ] }
]
''';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _checkAndRequestLocationPermission(); // ✅ primero pide permiso
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  // ✅ NUEVO: Cargar preferencias guardadas
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _is3DMode = prefs.getBool('map_3d_mode') ?? true; // Por defecto 3D
    });
    print('📱 Preferencia de vista cargada: ${_is3DMode ? "3D" : "2D"}');
  }

  // ✅ NUEVO: asegurar permiso y servicio de ubicación
  Future<void> _checkAndRequestLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Opcional: abrir ajustes si está apagado
        // await Geolocator.openLocationSettings();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final granted = permission == LocationPermission.always ||
                      permission == LocationPermission.whileInUse;
      if (mounted) {
        setState(() {
          _hasLocationPermission = granted;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasLocationPermission = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // ✅ usar el helper y salir si no hay permiso
      await _checkAndRequestLocationPermission();
      if (!_hasLocationPermission) {
        setState(() {
          _errorMessage = 'Permiso de ubicación no concedido';
          _isLoading = false;
        });
        return;
      }

      Position? position = await LocationService.getCurrentLocation();
      
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
        
        if (_mapController != null) {
          print('🎯 Centrando mapa en ubicación obtenida');
          await _centerToCurrentLocation();
        }
        
        _updateLocationMarker();
        _cargarLugaresComerciales();
        
      } else {
        setState(() {
          _errorMessage = 'No se pudo obtener la ubicación';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // ✅ NUEVO: Centrar en ubicación actual
  Future<void> _centerToCurrentLocation() async {
    if (_currentPosition != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 16.0,
            tilt: _is3DMode ? 45.0 : 0.0, // ✅ 3D o 2D según preferencia
            bearing: 0,
          ),
        ),
      );
    }
  }

  // ✅ NUEVO: Toggle entre 2D y 3D
  void _onViewModeToggle(bool is3D) async {
    setState(() {
      _is3DMode = is3D;
    });

    if (_mapController != null && _currentPosition != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 16.0,
            tilt: is3D ? 45.0 : 0.0, // ✅ 45° para 3D, 0° para 2D
            bearing: is3D ? 30.0 : 0.0, // ✅ Rotación ligera en 3D
          ),
        ),
      );
    }

    print('🗺️ Vista cambiada a: ${is3D ? "3D" : "2D"}');
  }

  // ✅ NUEVO: Centrar y seguir usuario
  void _onCenterLocation() async {
    if (_isFollowingUser) {
      // Si ya está siguiendo, detener
      _stopFollowingUser();
    } else {
      // Si no está siguiendo, comenzar
      _startFollowingUser();
    }
  }

  // ✅ NUEVO: Comenzar a seguir al usuario
  void _startFollowingUser() async {
    setState(() {
      _isFollowingUser = true;
    });

    // Centrar primero
    await _centerToCurrentLocation();

    // Comenzar seguimiento en tiempo real
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Actualizar cada 5 metros
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
      });

      // Solo seguir si está en modo seguimiento
      if (_isFollowingUser && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 16.0,
              tilt: _is3DMode ? 45.0 : 0.0,
              bearing: _is3DMode ? 30.0 : 0.0,
            ),
          ),
        );
      }
    });

    print('🎯 Iniciado seguimiento del usuario');
  }

  // ✅ NUEVO: Detener seguimiento
  void _stopFollowingUser() {
    setState(() {
      _isFollowingUser = false;
    });
    _locationSubscription?.cancel();
    print('⏹️ Detenido seguimiento del usuario');
  }

  // ✅ MODIFICAR: Método existente
  void _updateLocationMarker() {
    setState(() {
      _allMarkers.removeWhere((marker) => marker.markerId.value == 'current_location');
    });
    print('✅ Ubicación actualizada - Google Maps mostrará punto azul nativo');
  }

  Future<void> _cargarLugaresComerciales() async {
    if (_currentPosition == null) return;
    
    try {
      final ubicacionActual = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      
      print('🌍 Buscando lugares con GOOGLE PLACES cerca de: ${ubicacionActual.latitude}, ${ubicacionActual.longitude}');
      
      final lugaresComerciales = await PlacesService.buscarLugaresComerciales(
        ubicacion: ubicacionActual,
        radio: 3000,
      );
      
      Set<Marker> nuevosMarcadores = {};
      
      // ✅ CAMBIO: Ya no agregar marcador de ubicación porque Google Maps lo maneja
      _updateLocationMarker(); // Solo limpia marcadores antiguos
      
      print('🎯 Total de categorías con resultados: ${lugaresComerciales.length}');
      
      for (var categoria in lugaresComerciales.keys) {
        final lugares = lugaresComerciales[categoria]!;
        
        if (lugares.isNotEmpty) {
          print('✅ Google Places $categoria: ${lugares.length} lugares encontrados');
          
          for (var lugar in lugares.take(5)) {
            final marcador = await PlacesService.crearMarcadorDeLugar(
              lugar: lugar,
              categoria: categoria,
            );
            nuevosMarcadores.add(marcador);
          }
        } else {
          print('⚠️ Google Places $categoria: No se encontraron lugares');
        }
      }
      
      if (mounted && nuevosMarcadores.isNotEmpty) {
        setState(() {
          _allMarkers = nuevosMarcadores;
        });
        print('✅ Google Places: ${nuevosMarcadores.length} lugares cargados en el mapa');
      }
      
    } catch (e) {
      print('❌ Error cargando lugares con Google Places: $e');
    }
  }

  // ✅ MÉTODO COMPLETAMENTE NUEVO para rutas múltiples
  Future<void> mostrarRutaADestino(LatLng destino, String nombreDestino) async {
    if (_currentPosition == null) {
      print('❌ No hay ubicación actual para calcular ruta');
      return;
    }

    try {
      setState(() {
        _mostrandoRuta = true;
        _rutaInfo = 'Calculando rutas...';
      });

      widget.onRutaCalculada?.call('Calculando rutas...');

      final origen = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      
      print('🗺️ Calculando rutas múltiples desde $origen hacia $destino');
      
      // ✅ USAR EL NUEVO SERVICIO DE RUTAS MÚLTIPLES
      final rutasData = await MultiRoutesService.calcularRutasMultiples(
        origen: origen,
        destino: destino,
      );

      if (rutasData != null && rutasData['rutas'] != null) {
        final rutas = List<Map<String, dynamic>>.from(rutasData['rutas']);
        
        // ✅ CREAR POLYLINES PARA TODAS LAS RUTAS
        Set<Polyline> polylines = {};
        
        for (int i = 0; i < rutas.length; i++) {
          final ruta = rutas[i];
          final esPrincipal = i == _rutaSeleccionada;
          final esMasRapida = ruta['es_mas_rapida'] == true;
          
          polylines.add(Polyline(
            polylineId: PolylineId('ruta_$i'),
            points: List<LatLng>.from(ruta['puntos']),
            color: MultiRoutesService.getColorForRoute(i, esPrincipal, esMasRapida),
            width: esPrincipal ? 6 : 4, // ✅ Ruta principal más gruesa
            patterns: [], // ✅ QUITAR líneas punteadas
            consumeTapEvents: true, // ✅ AGREGAR: Permitir tap en la polyline
            onTap: () => _onRutaTapped(i), // ✅ AGREGAR: Método para tap normal
          ));
        }

        // ✅ MARCADOR DE DESTINO
        final marcadorDestino = Marker(
          markerId: const MarkerId('destino_ruta'),
          position: destino,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: nombreDestino,
            snippet: 'Destino seleccionado',
          ),
        );

        setState(() {
          _rutasDisponibles = rutas;
          _polylines = polylines;
          _allMarkers = {marcadorDestino};
          _rutaInfo = rutas[_rutaSeleccionada]['resumen'];
          _mostrandoRuta = true;
          _mostrandoRutasMultiples = rutas.length > 1;
          _puntosRutaActual = List<LatLng>.from(rutas[_rutaSeleccionada]['puntos']);
        });

        _ajustarVistaParaRuta(rutas[_rutaSeleccionada]['puntos']);

        print('✅ ${rutas.length} rutas calculadas');
        widget.onRutaCalculada?.call(rutas[_rutaSeleccionada]['resumen']);
        
      } else {
        setState(() {
          _rutaInfo = 'No se pudieron calcular las rutas';
          _mostrandoRuta = false;
        });
        widget.onRutaCalculada?.call('Error al calcular rutas');
      }
    } catch (e) {
      setState(() {
        _rutaInfo = 'Error al calcular rutas: $e';
        _mostrandoRuta = false;
      });
      print('❌ Error calculando rutas: $e');
      widget.onRutaCalculada?.call('Error al calcular rutas');
    }
  }

  // ✅ NUEVO MÉTODO: Cambiar ruta seleccionada
  void _cambiarRutaSeleccionada(int index) {
    if (index < _rutasDisponibles.length) {
      setState(() {
        _rutaSeleccionada = index;
        _rutaInfo = _rutasDisponibles[index]['resumen'];
        _puntosRutaActual = List<LatLng>.from(_rutasDisponibles[index]['puntos']);
      });

      // ✅ REGENERAR POLYLINES CON NUEVA SELECCIÓN
      Set<Polyline> polylines = {};
      for (int i = 0; i < _rutasDisponibles.length; i++) {
        final ruta = _rutasDisponibles[i];
        final esPrincipal = i == _rutaSeleccionada;
        final esMasRapida = ruta['es_mas_rapida'] == true;
        
        polylines.add(Polyline(
          polylineId: PolylineId('ruta_$i'),
          points: List<LatLng>.from(ruta['puntos']),
          color: MultiRoutesService.getColorForRoute(i, esPrincipal, esMasRapida),
          width: esPrincipal ? 6 : 4,
          patterns: [], // ✅ QUITAR líneas punteadas
          consumeTapEvents: true, // ✅ AGREGAR: Permitir tap en la polyline
          onTap: () => _onRutaTapped(i), // ✅ AGREGAR: Método para tap normal
        ));
      }

      setState(() {
        _polylines = polylines;
      });

      _ajustarVistaParaRuta(_rutasDisponibles[index]['puntos']);
      widget.onRutaCalculada?.call(_rutasDisponibles[index]['resumen']);
    }
  }

  // ✅ NUEVO: Método para ir a mi ubicación
  Future<void> _goToMyLocation() async {
    if (_currentPosition != null && _mapController != null) {
      print('📍 Centrando en mi ubicación: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
    
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 14.0, // ✅ CAMBIO: De 17.0 a 26.0 (el doble de zoom)
            tilt: 0,
            bearing: 0,
          ),
        ),
      );
    
      print('✅ Mapa centrado en mi ubicación actual');
    } else {
      print('🔄 No hay ubicación disponible, obteniendo ubicación...');
      // Si no hay ubicación, intentar obtenerla de nuevo
      await _getCurrentLocation();
    
      // Después de obtener la ubicación, centrar automáticamente
      if (_currentPosition != null && _mapController != null) {
        await _goToMyLocation(); // ✅ AHORA SÍ FUNCIONA CON await
      }
    }
  }

  // ✅ MÉTODO MEJORADO para los 3 tipos
  void _onMapTypeChanged(MapType tipo) {
    setState(() {
      _currentMapType = tipo;
    });
    if (_mapController != null) {
      if (tipo == MapType.normal) {
        _mapController!.setMapStyle(_colorfulMapStyle); // tus colores + POIs visibles
      } else {
        _mapController!.setMapStyle(null); // satélite/terreno sin estilo
      }
    }
    print('🗺️ Tipo de mapa cambiado a: ${tipo.toString()}');
  }

  // ✅ NUEVO: Método faltante para ajustar vista
  Future<void> _ajustarVistaParaRuta(List<LatLng> puntos) async {
    if (_mapController == null || puntos.isEmpty) return;

    try {
      // Calcular los límites de la ruta
      double minLat = puntos.first.latitude;
      double maxLat = puntos.first.latitude;
      double minLng = puntos.first.longitude;
      double maxLng = puntos.first.longitude;

      for (final punto in puntos) {
        minLat = minLat < punto.latitude ? minLat : punto.latitude;
        maxLat = maxLat > punto.latitude ? maxLat : punto.latitude;
        minLng = minLng < punto.longitude ? minLng : punto.longitude;
        maxLng = maxLng > punto.longitude ? maxLng : punto.longitude;
      }

      // Crear bounds
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      // Ajustar la cámara a los bounds
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          100.0, // Padding
        ),
      );

      print('✅ Vista ajustada para mostrar ruta completa');
    } catch (e) {
      print('❌ Error ajustando vista: $e');
    }
  }

  // ✅ NUEVO: Método para limpiar ruta (también faltaba)
  void limpiarRuta() {
    setState(() {
      _polylines.clear();
      _rutaInfo = null;
      _mostrandoRuta = false;
      _rutasDisponibles.clear();
      _rutaSeleccionada = 0;
      _mostrandoRutasMultiples = false;
      _puntosRutaActual.clear();
      
      // Limpiar marcadores de ruta pero mantener los lugares
      _allMarkers.removeWhere((marker) => 
          marker.markerId.value == 'destino_ruta');
    });
    
    // Recargar lugares comerciales
    _cargarLugaresComerciales();
    
    print('✅ Ruta limpiada');
  }

  // ✅ NUEVO: Getter para acceder a puntos de ruta desde MapsScreen
  List<LatLng> get puntosRutaActual => _puntosRutaActual;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ✅ GOOGLE MAPS
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition != null 
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : const LatLng(0, 0),
            zoom: _currentPosition != null ? 13.0 : 2.0,
            tilt: _is3DMode ? 45.0 : 0.0,
            bearing: _is3DMode ? 30.0 : 0.0,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            if (_currentMapType == MapType.normal) {
              _mapController!.setMapStyle(_colorfulMapStyle);
            } else {
              _mapController!.setMapStyle(null);
            }
            print('✅ Mapa creado exitosamente');
          },
          onCameraMove: (CameraPosition position) {
            if (_mostrandoRutasMultiples && _rutasDisponibles.isNotEmpty) {
              setState(() {});
            }
          },
          myLocationEnabled: _hasLocationPermission, // ✅ se activa tras permiso
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          markers: _allMarkers,
          polylines: _polylines,
          mapType: _currentMapType,
          padding: const EdgeInsets.only(
            top: 120,
            bottom: 160,
            left: 20,
            right: 20,
          ),
          onLongPress: (LatLng position) {
            if (_rutasDisponibles.isNotEmpty) {
              _showRouteInfoDialog();
            }
          },
        ),
        
        // ✅ LOADING/ERROR OVERLAYS (sin cambios)
        if (_isLoading)
          Container(
            color: const Color(0xFF1a1a2e),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF4299e1),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando mapa...',
                    style: TextStyle(
                      color: Color(0xFF4299e1),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        if (_errorMessage.isNotEmpty && !_isLoading)
          Container(
            color: const Color(0xFF1a1a2e),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFe53e3e),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _getCurrentLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4299e1),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        
        // ✅ SOLO SELECTOR DE TIPO DE MAPA (mantener)
        if (!_isLoading && _errorMessage.isEmpty)
          Positioned(
            top: 110,
            right: 16,
            child: MapTypeSelector(
              currentMapType: _currentMapType,
              onMapTypeChanged: _onMapTypeChanged,
            ),
          ),
      
        // ✅ SOLO BOTÓN DE MI UBICACIÓN BACKUP (mantener)
        if (!_isLoading && _errorMessage.isEmpty)
          Positioned(
            bottom: 120,
            right: 16,
            child: FloatingActionButton(
              onPressed: _centerToCurrentLocation,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1565C0),
              elevation: 4,
              mini: true,
              child: const Icon(
                Icons.my_location,
                size: 20,
              ),
            ),
          ),
        
        // ✅ WIDGET DE ADVERTENCIA DE SEGURIDAD
        if (!_isLoading && _errorMessage.isEmpty)
          Positioned(
            top: 180, // ✅ Posición en la parte superior izquierda
            left: 16,
            child: SafetyWarningWidget(
              onWarningRead: () {
                print('📋 Usuario leyó la advertencia de seguridad');
                // ✅ AQUÍ LUEGO AGREGAREMOS LA LÓGICA DE PUNTOS
              },
            ),
          ),
      ],
    );
  }

  // NUEVO: Manejar tap normal en ruta
  void _onRutaTapped(int index) {
  if (index != _rutaSeleccionada) {
    print('🎯 Cambiando a ruta $index');
    _cambiarRutaSeleccionada(index);
  }
}

  // NUEVO: Mostrar información de la ruta principal
  void _showRouteInfoDialog() {
  if (_rutaSeleccionada >= _rutasDisponibles.length) return;
  
  final rutaPrincipal = _rutasDisponibles[_rutaSeleccionada];
  
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.route,
              color: const Color(0xFF1565C0),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Información de Ruta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiempo estimado
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tiempo: ${rutaPrincipal['duracion_texto']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Distancia
            Row(
              children: [
                Icon(Icons.straighten, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Distancia: ${rutaPrincipal['distancia_texto']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Badge si es la más rápida
            if (rutaPrincipal['es_mas_rapida'] == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flash_on, color: Colors.orange[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Ruta más rápida',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}
}