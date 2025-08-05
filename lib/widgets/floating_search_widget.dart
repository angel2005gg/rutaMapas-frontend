import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/places_service.dart';

class FloatingSearchWidget extends StatefulWidget {
  final Function(LatLng, String) onPlaceSelected;
  final LatLng? currentLocation;

  const FloatingSearchWidget({
    Key? key,
    required this.onPlaceSelected,
    this.currentLocation,
  }) : super(key: key);

  @override
  State<FloatingSearchWidget> createState() => _FloatingSearchWidgetState();
}

class _FloatingSearchWidgetState extends State<FloatingSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _buscarLugares(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _isExpanded = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final lugares = await PlacesService.buscarLugaresPorTexto(
        consulta: query.trim(),
        ubicacionActual: widget.currentLocation,
        radio: 5000,
      );

      if (mounted) {
        setState(() {
          _searchResults = lugares;
          _isSearching = false;
          _isExpanded = lugares.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _isExpanded = false;
        });
        print('❌ Error en búsqueda: $e');
      }
    }
  }

  void _seleccionarLugar(Map<String, dynamic> lugar) {
    widget.onPlaceSelected(lugar['coordenadas'], lugar['nombre']);
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isExpanded = false;
    });
    _focusNode.unfocus();
  }

  void _limpiarBusqueda() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ AJUSTAR MARGIN: Subir el buscador y dar más espacio a los lados
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0), // ✅ Top más pequeño (era 60)
      child: Column(
        children: [
          // ✅ BARRA DE BÚSQUEDA MÁS DELGADA
          Container(
            // ✅ ALTURA REDUCIDA
            height: 48, // ✅ Altura fija más pequeña (era automática)
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24), // ✅ Más redondeado
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8, // ✅ Sombra más sutil
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _buscarLugares,
              decoration: InputDecoration(
                hintText: 'Buscar lugares...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 15, // ✅ Texto más pequeño
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[600],
                  size: 22, // ✅ Icono más pequeño
                ),
                suffixIcon: _isSearching 
                  ? Container(
                      width: 16, // ✅ Más pequeño
                      height: 16,
                      margin: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                      ),
                    )
                  : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey[600],
                          size: 20, // ✅ Icono más pequeño
                        ),
                        onPressed: _limpiarBusqueda,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, // ✅ Padding horizontal reducido
                  vertical: 12,  // ✅ Padding vertical reducido para hacer más delgado
                ),
              ),
              style: const TextStyle(
                fontSize: 15, // ✅ Texto más pequeño
                color: Colors.black87,
              ),
            ),
          ),
          
          // ✅ RESULTADOS (sin cambios mayores)
          if (_isExpanded && _searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4), // ✅ Menos espacio
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
              constraints: const BoxConstraints(maxHeight: 250), // ✅ Un poco más bajo
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6), // ✅ Padding reducido
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey[200],
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final lugar = _searchResults[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2, // ✅ Menos padding vertical
                    ),
                    dense: true, // ✅ Hacer los items más compactos
                    leading: Container(
                      width: 36, // ✅ Más pequeño
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1565C0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.place,
                        color: Colors.white,
                        size: 18, // ✅ Icono más pequeño
                      ),
                    ),
                    title: Text(
                      lugar['nombre'] ?? 'Sin nombre',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14, // ✅ Texto más pequeño
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: lugar['direccion'] != null
                        ? Text(
                            lugar['direccion'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12, // ✅ Texto más pequeño
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    onTap: () => _seleccionarLugar(lugar),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}