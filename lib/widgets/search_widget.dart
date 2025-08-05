import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/places_service.dart'; // ✅ CAMBIAR: usar Google Places en lugar de MapboxService

class SearchWidget extends StatefulWidget {
  final Function(LatLng, String) onPlaceSelected;
  final LatLng? currentLocation;

  const SearchWidget({
    Key? key,
    required this.onPlaceSelected,
    this.currentLocation,
  }) : super(key: key);

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ CAMBIAR TODO ESTE MÉTODO para usar Google Places
  Future<void> _buscarLugares(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // ✅ USAR GOOGLE PLACES TEXT SEARCH en lugar de MapboxService
      final lugares = await PlacesService.buscarLugaresPorTexto(
        consulta: query.trim(),
        ubicacionActual: widget.currentLocation,
        radio: 5000,
      );

      // Convertir el formato de Google Places al formato esperado por el widget
      final resultadosFormateados = lugares.map((lugar) {
        return {
          'nombre': lugar['nombre'],
          'direccion': lugar['direccion'],
          'coordenadas': lugar['coordenadas'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _searchResults = resultadosFormateados;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        print('❌ Error en búsqueda: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ✅ BARRA DE BÚSQUEDA FLOTANTE
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _buscarLugares,
            decoration: InputDecoration(
              hintText: 'Buscar lugares...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
              suffixIcon: _isSearching 
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
        
        // ✅ RESULTADOS DE BÚSQUEDA
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: _searchResults.map((result) => 
                ListTile(
                  leading: const Icon(Icons.place, color: Color(0xFF1565C0)),
                  title: Text(
                    result['nombre'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(result['direccion']),
                  onTap: () {
                    widget.onPlaceSelected(
                      result['coordenadas'],
                      result['nombre'],
                    );
                    _searchController.clear();
                    setState(() => _searchResults = []);
                  },
                ),
              ).toList(),
            ),
          ),
      ],
    );
  }
}