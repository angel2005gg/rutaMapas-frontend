import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapTypeSelector extends StatefulWidget {
  final MapType currentMapType;
  final Function(MapType) onMapTypeChanged;

  const MapTypeSelector({
    Key? key,
    required this.currentMapType,
    required this.onMapTypeChanged,
  }) : super(key: key);

  @override
  State<MapTypeSelector> createState() => _MapTypeSelectorState();
}

class _MapTypeSelectorState extends State<MapTypeSelector> {
  bool _isExpanded = false;

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _selectMapType(MapType mapType) {
    widget.onMapTypeChanged(mapType);
    setState(() {
      _isExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Menu desplegable (solo visible cuando está expandido)
        if (_isExpanded) ...[
          // ✅ OPCIÓN 1: Normal (tu estilo personalizado)
          _buildMapTypeOption(
            mapType: MapType.normal,
            icon: Icons.map,
            label: 'Normal',
            isSelected: widget.currentMapType == MapType.normal,
          ),
          const SizedBox(height: 8),
          
          // ✅ OPCIÓN 2: Satélite
          _buildMapTypeOption(
            mapType: MapType.satellite,
            icon: Icons.satellite_alt,
            label: 'Satélite',
            isSelected: widget.currentMapType == MapType.satellite,
          ),
          const SizedBox(height: 8),
          
          // ✅ OPCIÓN 3: Claro (Google Maps por defecto) - CAMBIO AQUÍ
          _buildMapTypeOption(
            mapType: MapType.terrain, // ✅ USAR TERRAIN como "claro"
            icon: Icons.terrain,
            label: 'Montaña',
            isSelected: widget.currentMapType == MapType.terrain,
          ),
          const SizedBox(height: 8),
        ],
        
        // Botón principal
        FloatingActionButton(
          onPressed: _toggleMenu,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1565C0),
          elevation: 4,
          mini: true,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isExpanded ? Icons.close : Icons.layers,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapTypeOption({
    required MapType mapType,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return AnimatedScale(
      scale: _isExpanded ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF1565C0) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: () => _selectMapType(mapType),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected ? const Color(0xFF1565C0) : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF1565C0) : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}