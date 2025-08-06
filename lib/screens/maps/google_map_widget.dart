import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';
import '../../services/places_service.dart';
import '../../services/directions_service.dart';
import '../../widgets/map_type_selector.dart'; // ✅ NUEVO IMPORT

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

  static const String _colorfulMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#0d1421"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#e5e7eb"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#0d1421"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#1e40af"
      }
    ]
  },
  {
    "featureType": "administrative.country",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#f3f4f6"
      }
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#f3f4f6"
      }
    ]
  },
  {
    "featureType": "administrative.neighborhood",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9ca3af"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d1d5db"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#065f46"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#34d399"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#1f2937"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d1d5db"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#374151"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#e5e7eb"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#4b5563"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#f3f4f6"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#1f2937"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9ca3af"
      }
    ]
  },
  {
    "featureType": "transit",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#1e3a5f"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#93c5fd"
      }
    ]
  }
]
''';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Permisos de ubicación denegados';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Permisos de ubicación permanentemente denegados';
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
        
        // ✅ CAMBIO: Centrar automáticamente cuando se obtiene la ubicación
        if (_mapController != null) {
          print('🎯 Centrando mapa en ubicación obtenida');
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 14.0, // ✅ CAMBIO: De 16.0 a 14.0 (más alejado al cargar)
                tilt: 0,
                bearing: 0,
              ),
            ),
          );
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

  // ✅ CAMBIAR TODO ESTE MÉTODO:
  void _updateLocationMarker() {
    // ✅ YA NO CREAR MARCADOR ROJO - Google Maps mostrará el punto azul automáticamente
    // Solo limpiar cualquier marcador de ubicación anterior si existe
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
      
      if (mounted && nuevosMarcadores.length > 1) {
        setState(() {
          _allMarkers = nuevosMarcadores;
        });
        print('✅ Google Places: ${nuevosMarcadores.length - 1} lugares cargados en el mapa');
      }
      
    } catch (e) {
      print('❌ Error cargando lugares con Google Places: $e');
    }
  }

  Future<void> mostrarRutaADestino(LatLng destino, String nombreDestino) async {
    if (_currentPosition == null) {
      print('❌ No hay ubicación actual para calcular ruta');
      return;
    }

    try {
      setState(() {
        _mostrandoRuta = true;
        _rutaInfo = 'Calculando ruta...';
      });

      widget.onRutaCalculada?.call('Calculando ruta...');

      final origen = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      
      print('🗺️ Calculando ruta desde $origen hacia $destino');
      
      final rutaData = await DirectionsService.calcularRuta(
        origen: origen,
        destino: destino,
      );

      if (rutaData != null) {
        final polyline = Polyline(
          polylineId: const PolylineId('ruta_navegacion'),
          points: rutaData['puntos_ruta'],
          color: const Color(0xFF1565C0),
          width: 5,
          patterns: [],
        );

        // ✅ CAMBIO: NO crear marcador de origen porque Google Maps ya muestra el punto azul
        // Solo crear marcador de destino
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
          _polylines = {polyline};
          _allMarkers = {marcadorDestino}; // ✅ SOLO marcador de destino
          _rutaInfo = rutaData['resumen'];
          _mostrandoRuta = true;
        });

        _ajustarVistaParaRuta(rutaData['puntos_ruta']);

        print('✅ Ruta calculada: ${rutaData['resumen']}');
        
        widget.onRutaCalculada?.call(rutaData['resumen']);
      } else {
        setState(() {
          _rutaInfo = 'No se pudo calcular la ruta';
          _mostrandoRuta = false;
        });
        widget.onRutaCalculada?.call('Error al calcular ruta');
      }
    } catch (e) {
      setState(() {
        _rutaInfo = 'Error al calcular ruta: $e';
        _mostrandoRuta = false;
      });
      print('❌ Error calculando ruta: $e');
      widget.onRutaCalculada?.call('Error al calcular ruta');
    }
  }

  void _ajustarVistaParaRuta(List<LatLng> puntos) {
    if (puntos.isEmpty || _mapController == null) return;

    double minLat = puntos.first.latitude;
    double maxLat = puntos.first.latitude;
    double minLng = puntos.first.longitude;
    double maxLng = puntos.first.longitude;

    for (var punto in puntos) {
      if (punto.latitude < minLat) minLat = punto.latitude;
      if (punto.latitude > maxLat) maxLat = punto.latitude;
      if (punto.longitude < minLng) minLng = punto.longitude;
      if (punto.longitude > maxLng) maxLng = punto.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  void limpiarRuta() {
    setState(() {
      _polylines.clear();
      _rutaInfo = null;
      _mostrandoRuta = false;
    });
    
    _cargarLugaresComerciales();
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
    
    // ✅ LÓGICA CORREGIDA:
    // Normal = Tu estilo personalizado
    // Satelital = Sin estilo (Google satelital)  
    // Claro = Sin estilo (Google por defecto)
    if (_mapController != null) {
      if (tipo == MapType.normal) {
        // Tu estilo personalizado oscuro
        _mapController!.setMapStyle(_colorfulMapStyle);
      } else {
        // Satélite y Claro = sin estilo personalizado
        _mapController!.setMapStyle(null);
      }
    }
    
    print('🗺️ Tipo de mapa cambiado a: ${tipo.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ✅ GOOGLE MAPS
        GoogleMap(
          initialCameraPosition: CameraPosition(
            // ✅ CAMBIO: Solo usar ubicación real, sin por defecto
            target: _currentPosition != null 
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : const LatLng(0, 0),
            zoom: _currentPosition != null ? 13.0 : 2.0, // ✅ CAMBIO: De 15.0 a 13.0 (más alejado)
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            _mapController!.setMapStyle(_colorfulMapStyle);
            print('✅ Mapa creado exitosamente con estilo colorido');
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          markers: _allMarkers,
          polylines: _polylines,
          mapType: _currentMapType,
          // ✅ PADDING AJUSTADO PARA PUNTO AZUL MÁS GRANDE
          padding: const EdgeInsets.only(
            top: 120,
            bottom: 160,
            left: 20,
            right: 20, // ✅ AGREGAR padding derecho para mejor balance
          ),
        ),
        
        // ✅ LOADING OVERLAY (sin cambios)
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
        
        // ✅ ERROR OVERLAY (sin cambios)
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
        
        // ✅ NUEVO: SELECTOR DE TIPO DE MAPA
        if (!_isLoading && _errorMessage.isEmpty)
          Positioned(
            top: 110, // ✅ CAMBIO: de 80 a 110 (más abajo del buscador)
            right: 16,
            child: MapTypeSelector(
              currentMapType: _currentMapType,
              onMapTypeChanged: _onMapTypeChanged,
            ),
          ),
      
        // ✅ BOTÓN DE MI UBICACIÓN (SIN CAMBIOS)
        if (!_isLoading && _errorMessage.isEmpty)
          Positioned(
            bottom: 120,
            right: 16,
            child: FloatingActionButton(
              onPressed: _goToMyLocation,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1565C0),
              elevation: 4,
              mini: false,
              child: const Icon(
                Icons.my_location,
                size: 24,
              ),
            ),
          ),
      ],
    );
  }
}