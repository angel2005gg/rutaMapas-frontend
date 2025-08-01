import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/mapbox_service.dart';

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

  Future<void> _buscarLugares(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await MapboxService.buscarLugares(
        consulta: query,
        proximidad: widget.currentLocation,
        limite: 5,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
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