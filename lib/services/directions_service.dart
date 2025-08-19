import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsService {
  static const String _apiKey = 'AIzaSyCP1xS8HLdxQe-a1KeuXGQzaVIqoQvKmYo';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions';

  // ✅ CALCULAR RUTA ENTRE DOS PUNTOS (mejorada precisión)
  static Future<Map<String, dynamic>?> calcularRuta({
    required LatLng origen,
    required LatLng destino,
    String modo = 'driving', // driving, walking, bicycling, transit
  }) async {
    try {
      // Usar overview=full para una geometría más densa y departure_time=now para tráfico
      final url = '$_baseUrl/json?'
          'origin=${origen.latitude},${origen.longitude}&'
          'destination=${destino.latitude},${destino.longitude}&'
          'mode=$modo&'
          'alternatives=true&' // permite evaluar varias rutas
          'language=es&'
          'region=co&' // Colombia
          'units=metric&'
          'overview=full&'
          // Tráfico solo aplica a driving
          '${modo == 'driving' ? 'departure_time=now&traffic_model=best_guess&' : ''}'
          'key=$_apiKey';

      print('🛣️ Calculando ruta: $url');

      final response = await http.get(Uri.parse(url));

      print('📱 Directions API Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('📊 Directions Response status: ${data['status']}');

        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          // ✅ Elegir la mejor ruta considerando duración en tráfico (si existe)
          final routes = List<Map<String, dynamic>>.from(data['routes']);
          Map<String, dynamic> bestRoute = routes.first;
          int bestScore = _getDurationScore(bestRoute);
          for (final r in routes.skip(1)) {
            final score = _getDurationScore(r);
            if (score < bestScore) {
              bestRoute = r;
              bestScore = score;
            }
          }

          final leg = bestRoute['legs'][0];

          // ✅ POLILÍNEA DETALLADA: concatenar polilíneas de cada paso para seguir calzadas reales
          final List<LatLng> detailedPoints = [];
          final steps = List<Map<String, dynamic>>.from(leg['steps']);
          for (final step in steps) {
            final encoded = step['polyline']?['points'];
            if (encoded is String && encoded.isNotEmpty) {
              final pts = _decodificarPolyline(encoded);
              if (detailedPoints.isNotEmpty && pts.isNotEmpty &&
                  detailedPoints.last.latitude == pts.first.latitude &&
                  detailedPoints.last.longitude == pts.first.longitude) {
                // evitar duplicar el punto de unión
                detailedPoints.addAll(pts.skip(1));
              } else {
                detailedPoints.addAll(pts);
              }
            }
          }

          // ✅ POLILÍNEA OVERVIEW (respaldo)
          final overviewEncoded = bestRoute['overview_polyline']?['points'];
          final overviewPoints = (overviewEncoded is String && overviewEncoded.isNotEmpty)
              ? _decodificarPolyline(overviewEncoded)
              : <LatLng>[];

          // Usar la detallada si tiene suficiente densidad; si no, fallback al overview
          final puntos = detailedPoints.length >= 10 ? detailedPoints : overviewPoints;

          // ✅ EXTRAER INFORMACIÓN DE LA RUTA
          final distancia = leg['distance']['text'];
          final duracion = leg['duration']['text'];
          final duracionEnTrafico = leg['duration_in_traffic']?['text'];

          // ✅ OBTENER INSTRUCCIONES PASO A PASO
          final pasos = _extraerPasos(steps);

          final resumen = duracionEnTrafico != null
              ? '$distancia • $duracionEnTrafico'
              : '$distancia • $duracion';

          print('✅ Ruta calculada: $resumen');
          print('📍 ${puntos.length} puntos en la ruta (detallados=${detailedPoints.length}, overview=${overviewPoints.length})');
          print('👣 ${pasos.length} pasos de navegación');

          return {
            'puntos_ruta': puntos,
            'resumen': resumen,
            'distancia': distancia,
            'duracion': duracion,
            if (duracionEnTrafico != null) 'duracion_trafico': duracionEnTrafico,
            'pasos': pasos,
            'data_completa': data,
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

  // ✅ Score para elegir ruta: duration_in_traffic.value si existe, si no duration.value
  static int _getDurationScore(Map<String, dynamic> route) {
    try {
      final leg = route['legs'][0];
      final dTraffic = leg['duration_in_traffic']?['value'];
      if (dTraffic is int) return dTraffic;
      final d = leg['duration']?['value'];
      if (d is int) return d;
    } catch (_) {}
    return 1 << 30; // grande por defecto
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