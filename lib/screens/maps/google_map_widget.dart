import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';
import '../../services/places_service.dart'; // ✅ AGREGAR ESTA LÍNEA

class GoogleMapWidget extends StatefulWidget {
  const GoogleMapWidget({Key? key}) : super(key: key);

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  String _errorMessage = '';
  
  // ✅ AGREGAR ESTAS LÍNEAS NUEVAS
  Set<Marker> _allMarkers = {};
  bool _showingPlaces = false;
  
  // ✅ Tu ubicación real de Colombia (Cali) - SIN CAMBIOS
  static const LatLng _initialPosition = LatLng(3.4968807, -76.5192206);

  // ✅ ESTILO DEL MAPA - SIN CAMBIOS (mantener tu estilo actual)
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
    PlacesService.testPlacesAPI(); // ✅ AGREGAR ESTA LÍNEA PARA TESTING
    _getCurrentLocation();
  }

  // ✅ REEMPLAZAR TODO EL MÉTODO _getCurrentLocation() CON ESTE:
  Future<void> _getCurrentLocation() async {
    try {
      // Verificar permisos
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

      // Obtener ubicación
      Position? position = await LocationService.getCurrentLocation();
      
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
        
        // ✅ ZOOM PRIMERO - SIN ESPERAR
        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 16.0,
                tilt: 0,
                bearing: 0,
              ),
            ),
          );
        }
        
        // ✅ CREAR MARCADOR DE UBICACIÓN
        _updateLocationMarker();
        
        // ✅ CARGAR LUGARES EN BACKGROUND - SIN BLOQUEAR
        _cargarLugaresComerciales(); // Sin await
        
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

  // ✅ AGREGAR ESTE MÉTODO NUEVO
  void _updateLocationMarker() {
    if (_currentPosition == null) return;
    
    final locationMarker = Marker(
      markerId: const MarkerId('current_location'),
      position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      infoWindow: const InfoWindow(
        title: 'Tu ubicación',
        snippet: 'Aquí estás',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
    
    setState(() {
      _allMarkers.removeWhere((marker) => marker.markerId.value == 'current_location');
      _allMarkers.add(locationMarker);
    });
  }

  // ✅ AGREGAR ESTE MÉTODO NUEVO
  Future<void> _cargarLugaresComerciales() async {
    if (_currentPosition == null) return;
    
    try {
      final ubicacionActual = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      
      // ✅ BUSCAR LUGARES - SIN setState de loading
      final lugaresPorCategoria = await PlacesService.buscarLugaresComerciales(
        ubicacion: ubicacionActual,
        radio: 2000, // 2km de radio
      );
      
      // ✅ SOLO actualizar si hay lugares
      if (lugaresPorCategoria.isNotEmpty) {
        Set<Marker> nuevosMarcadores = {};
        
        // ✅ Mantener marcador de ubicación actual
        _updateLocationMarker();
        nuevosMarcadores.addAll(_allMarkers.where((m) => m.markerId.value == 'current_location'));
        
        // ✅ Agregar marcadores de lugares comerciales
        lugaresPorCategoria.forEach((categoria, lugares) {
          for (var lugar in lugares.take(3)) { // ✅ SOLO 3 por categoría
            final marcador = PlacesService.crearMarcadorDeLugar(
              lugar: lugar,
              categoria: categoria,
            );
            nuevosMarcadores.add(marcador);
          }
        });
        
        if (mounted) {
          setState(() {
            _allMarkers = nuevosMarcadores;
          });
        }
        
        print('✅ Cargados ${nuevosMarcadores.length - 1} lugares comerciales');
      }
      
    } catch (e) {
      print('❌ Error cargando lugares comerciales: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ✅ CAMBIAR SOLO ESTA LÍNEA EN EL GoogleMap:
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition != null 
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : _initialPosition,
            zoom: 15.0,
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
          markers: _allMarkers, // ✅ CAMBIAR ESTA LÍNEA: usar _allMarkers en lugar del código anterior
          mapType: MapType.normal,
        ),
        
        // ✅ TODO EL RESTO IGUAL - SIN CAMBIOS
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        
        if (!_isLoading && _errorMessage.isEmpty)
          Positioned(
            bottom: 30,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _getCurrentLocation,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4299e1),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Color(0xFF4299e1),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}