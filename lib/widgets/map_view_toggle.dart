import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // ✅ AGREGAR este import si no está
class MapViewToggle extends StatefulWidget {
  final bool is3DMode;
  final Function(bool) onToggle;

  const MapViewToggle({
    Key? key,
    required this.is3DMode,
    required this.onToggle,
  }) : super(key: key);

  @override
  State<MapViewToggle> createState() => _MapViewToggleState();
}

class _MapViewToggleState extends State<MapViewToggle> {
  bool _isExpanded = false;

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _selectMode(bool is3D) async {
    widget.onToggle(is3D);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('map_3d_mode', is3D);
    
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
        if (_isExpanded) ...[
          _buildViewOption(
            is3D: false,
            icon: Icons.layers_outlined,
            label: '2D',
            isSelected: !widget.is3DMode,
          ),
          const SizedBox(height: 8),
          
          _buildViewOption(
            is3D: true,
            icon: Icons.view_in_ar,
            label: '3D',
            isSelected: widget.is3DMode,
          ),
          const SizedBox(height: 8),
        ],
        
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
              _isExpanded ? Icons.close : (widget.is3DMode ? Icons.view_in_ar : Icons.layers_outlined),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewOption({
    required bool is3D,
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
            onTap: () => _selectMode(is3D),
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