import 'package:flutter/material.dart';
import 'maps/google_map_widget.dart';

class MapsScreen extends StatelessWidget {
  const MapsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // ✅ ELIMINAR AppBar completamente para pantalla completa
      backgroundColor: Color(0xFF1a1a2e),
      body: GoogleMapWidget(), // ✅ Solo el mapa, sin AppBar
    );
  }
}