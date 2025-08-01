import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapboxService {
  // ✅ TOKEN PÚBLICO DE MAPBOX (necesitas crear cuenta gratuita)
  static const String _accessToken = 'pk.eyJ1IjoidHUtbW90b3MiLCJhIjoiY2x4eHh4eHh4eDAwMG1lcWVyYWFhYWEifQ.xxxxxxxxxxxxxx';
  static const String _baseUrl = 'https://api.mapbox.com';

  // ✅ BUSCAR LUGARES (reemplaza Google Places)
  static Future<List<Map<String, dynamic>>> buscarLugares({
    required String consulta,
    LatLng? proximidad,
    int limite = 10,
  }) async {
    try {
      String url = '$_baseUrl/geocoding/v5/mapbox.places/${Uri.encodeComponent(consulta)}.json?'
          'access_token=$_accessToken&'
          'limit=$limite&'
          'language=es&'
          'country=CO'; // ✅ Solo Colombia
      
      if (proximidad != null) {
        url += '&proximity=${proximidad.longitude},${proximidad.latitude}';
      }

      print('🔍 Mapbox buscar: $url');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = List<Map<String, dynamic>>.from(data['features'] ?? []);
        
        print('✅ Mapbox encontró: ${features.length} lugares');
        
        return features.map((feature) => {
          'id': feature['id'],
          'nombre': feature['place_name'],
          'direccion': feature['properties']['address'] ?? '',
          'coordenadas': LatLng(
            feature['geometry']['coordinates'][1], // lat
            feature['geometry']['coordinates'][0], // lng
          ),
          'categoria': _extraerCategoria(feature),
        }).toList();
      }
      
      return [];
    } catch (e) {
      print('❌ Error Mapbox búsqueda: $e');
      return [];
    }
  }

  // ✅ LUGARES CERCANOS por categoría
  static Future<List<Map<String, dynamic>>> lugaresNearby({
    required LatLng ubicacion,
    required String categoria,
    int limite = 10,
  }) async {
    try {
      // ✅ Mapear categorías de Google a Mapbox
      final categoriaMapbox = _mapearCategoria(categoria);
      
      final url = '$_baseUrl/geocoding/v5/mapbox.places/$categoriaMapbox.json?'
          'access_token=$_accessToken&'
          'proximity=${ubicacion.longitude},${ubicacion.latitude}&'
          'limit=$limite&'
          'language=es&'
          'country=CO';

      print('🔍 Mapbox nearby $categoria: $url');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = List<Map<String, dynamic>>.from(data['features'] ?? []);
        
        print('✅ Mapbox $categoria: ${features.length} lugares');
        
        return features.map((feature) => {
          'id': feature['id'],
          'nombre': feature['place_name'],
          'coordenadas': LatLng(
            feature['geometry']['coordinates'][1],
            feature['geometry']['coordinates'][0],
          ),
          'categoria': categoria,
        }).toList();
      }
      
      return [];
    } catch (e) {
      print('❌ Error Mapbox nearby: $e');
      return [];
    }
  }

  // ✅ CALCULAR RUTA (lo que Google no puede hacer gratis)
  static Future<Map<String, dynamic>?> calcularRuta({
    required LatLng origen,
    required LatLng destino,
    String perfil = 'driving', // driving, walking, cycling
  }) async {
    try {
      final url = '$_baseUrl/directions/v5/mapbox/$perfil/'
          '${origen.longitude},${origen.latitude};'
          '${destino.longitude},${destino.latitude}?'
          'access_token=$_accessToken&'
          'steps=true&'
          'banner_instructions=true&'
          'language=es&'
          'voice_instructions=true&'
          'geometries=geojson';

      print('🗺️ Mapbox ruta: $url');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List;
        
        if (routes.isNotEmpty) {
          final route = routes[0];
          final geometry = route['geometry'];
          final coordinates = List<List<dynamic>>.from(geometry['coordinates']);
          
          print('✅ Ruta calculada: ${coordinates.length} puntos');
          
          return {
            'puntos_ruta': coordinates.map((coord) => 
              LatLng(coord[1], coord[0]) // lat, lng
            ).toList(),
            'distancia': route['distance'], // metros
            'duracion': route['duration'], // segundos
            'instrucciones': _extraerInstrucciones(route['legs']),
          };
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error Mapbox ruta: $e');
      return null;
    }
  }

  // ✅ HELPER: Mapear categorías Google → Mapbox
  static String _mapearCategoria(String categoria) {
    switch (categoria) {
      case 'restaurantes': return 'restaurant';
      case 'gasolineras': return 'fuel';
      case 'bancos': return 'bank';
      case 'hoteles': return 'lodging';
      case 'farmacias': return 'pharmacy';
      case 'supermercados': return 'grocery';
      case 'hospitales': return 'hospital';
      default: return categoria;
    }
  }

  static String _extraerCategoria(Map<String, dynamic> feature) {
    final categories = feature['properties']['category']?.split(',') ?? [];
    if (categories.contains('restaurant')) return 'restaurantes';
    if (categories.contains('fuel')) return 'gasolineras';
    if (categories.contains('bank')) return 'bancos';
    return 'lugar';
  }

  static List<String> _extraerInstrucciones(List legs) {
    List<String> instrucciones = [];
    
    for (var leg in legs) {
      final steps = leg['steps'] as List;
      for (var step in steps) {
        final maneuver = step['maneuver'];
        final instruction = maneuver['instruction'] ?? 'Continúa';
        instrucciones.add(instruction);
      }
    }
    
    return instrucciones;
  }
}