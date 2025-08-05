import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'maps/google_map_widget.dart';
import '../widgets/floating_search_widget.dart';
import '../widgets/navigation_bottom_sheet.dart'; // ✅ NUEVO IMPORT

class MapsScreen extends StatefulWidget {
  const MapsScreen({Key? key}) : super(key: key);

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final GlobalKey _mapKey = GlobalKey();
  
  // ✅ NUEVAS VARIABLES para el bottom sheet
  String? _rutaInfo;
  String? _nombreDestino;
  LatLng? _coordenadasDestino;
  bool _mostrandoRuta = false;

  void _onPlaceSelected(LatLng location, String placeName) {
    print('📍 Lugar seleccionado: $placeName en $location');
    
    // ✅ LLAMAR AL MÉTODO DE NAVEGACIÓN DEL MAPA
    (_mapKey.currentState as dynamic)?.mostrarRutaADestino(location, placeName);
    
    // ✅ ACTUALIZAR ESTADO DEL BOTTOM SHEET
    setState(() {
      _coordenadasDestino = location;
      _nombreDestino = placeName;
      _mostrandoRuta = true;
      // _rutaInfo se actualizará cuando GoogleMapWidget calcule la ruta
    });
  }

  // ✅ NUEVO: Método para actualizar información de ruta desde GoogleMapWidget
  void _onRutaCalculada(String rutaInfo) {
    setState(() {
      _rutaInfo = rutaInfo;
    });
  }

  // ✅ NUEVO: Método para cerrar la ruta
  void _onCerrarRuta() {
    (_mapKey.currentState as dynamic)?.limpiarRuta();
    setState(() {
      _rutaInfo = null;
      _nombreDestino = null;
      _coordenadasDestino = null;
      _mostrandoRuta = false;
    });
  }

  // ✅ NUEVO: Método para comenzar navegación
  void _onComenzarNavegacion() {
    // Aquí puedes implementar lógica adicional para navegación paso a paso
    print('🧭 Comenzando navegación hacia $_nombreDestino');
    
    // Por ejemplo, abrir Google Maps nativo
    // O implementar navegación paso a paso en la app
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Stack(
        children: [
          // ✅ GOOGLE MAPS (fondo)
          GoogleMapWidget(
            key: _mapKey,
            onRutaCalculada: _onRutaCalculada, // ✅ NUEVO CALLBACK
          ),
          
          // ✅ BUSCADOR FLOTANTE (arriba)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: FloatingSearchWidget(
                onPlaceSelected: _onPlaceSelected,
                currentLocation: null,
              ),
            ),
          ),
          
          // ✅ NAVIGATION BOTTOM SHEET (abajo, siempre visible)
          NavigationBottomSheet(
            rutaInfo: _rutaInfo,
            nombreDestino: _nombreDestino,
            coordenadasDestino: _coordenadasDestino,
            mostrandoRuta: _mostrandoRuta,
            onCerrarRuta: _onCerrarRuta,
            onComenzarNavegacion: _onComenzarNavegacion,
          ),
        ],
      ),
    );
  }
}