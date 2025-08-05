import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsService {
  static const String _apiKey = 'AIzaSyCP1xS8HLdxQe-a1KeuXGQzaVIqoQvKmYo';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions';

  // ✅ CALCULAR RUTA ENTRE DOS PUNTOS
  static Future<Map<String, dynamic>?> calcularRuta({
    required LatLng origen,
    required LatLng destino,
    String modo = 'driving', // driving, walking, bicycling, transit
  }) async {
    try {
      final url = '$_baseUrl/json?'
          'origin=${origen.latitude},${origen.longitude}&'
          'destination=${destino.latitude},${destino.longitude}&'
          'mode=$modo&'
          'language=es&'
          'region=co&' // Colombia
          'key=$_apiKey';

      print('🛣️ Calculando ruta: $url');

      final response = await http.get(Uri.parse(url));
      
      print('📱 Directions API Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('📊 Directions Response status: ${data['status']}');
        
        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // ✅ DECODIFICAR POLYLINE
          final puntos = _decodificarPolyline(route['overview_polyline']['points']);
          
          // ✅ EXTRAER INFORMACIÓN DE LA RUTA
          final distancia = leg['distance']['text'];
          final duracion = leg['duration']['text'];
          
          // ✅ OBTENER INSTRUCCIONES PASO A PASO
          final pasos = _extraerPasos(leg['steps']);
          
          final resumen = '$distancia • $duracion';
          
          print('✅ Ruta calculada: $resumen');
          print('📍 ${puntos.length} puntos en la ruta');
          print('👣 ${pasos.length} pasos de navegación');
          
          return {
            'puntos_ruta': puntos,
            'resumen': resumen,
            'distancia': distancia,
            'duracion': duracion,
            'pasos': pasos,
            'data_completa': data, // Por si necesitas más información
          };
        } else {
          print('❌ Directions API Error: ${data['status']} - ${data['error_message'] ?? 'Sin mensaje'}');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Response: ${response.body}');
      }
      
      return null;
    } catch (e) {
      print('❌ Exception en calcularRuta: $e');
      return null;
    }
  }

  // ✅ DECODIFICAR POLYLINE DE GOOGLE MAPS
  static List<LatLng> _decodificarPolyline(String encoded) {
    List<LatLng> puntos = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      puntos.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return puntos;
  }

  // ✅ EXTRAER PASOS DE NAVEGACIÓN
  static List<Map<String, dynamic>> _extraerPasos(List<dynamic> steps) {
    return steps.map<Map<String, dynamic>>((step) {
      // Limpiar HTML de las instrucciones
      String instruccion = step['html_instructions']
          .replaceAll(RegExp(r'<[^>]*>'), '') // Quitar tags HTML
          .replaceAll('&nbsp;', ' ') // Reemplazar espacios HTML
          .trim();
      
      return {
        'instruccion': instruccion,
        'distancia': step['distance']['text'],
        'duracion': step['duration']['text'],
        'ubicacion_inicio': LatLng(
          step['start_location']['lat'],
          step['start_location']['lng'],
        ),
        'ubicacion_fin': LatLng(
          step['end_location']['lat'],
          step['end_location']['lng'],
        ),
      };
    }).toList();
  }
}