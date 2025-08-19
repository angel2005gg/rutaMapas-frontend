import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart'; // ✅ AGREGAR este import para Color
class MultiRoutesService {
  static const String _apiKey = 'AIzaSyCP1xS8HLdxQe-a1KeuXGQzaVIqoQvKmYo';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions';

  // ✅ CALCULAR MÚLTIPLES RUTAS CON ALTERNATIVAS (mejorado)
  static Future<Map<String, dynamic>?> calcularRutasMultiples({
    required LatLng origen,
    required LatLng destino,
    String modo = 'driving',
  }) async {
    try {
      final url = '$_baseUrl/json?'
          'origin=${origen.latitude},${origen.longitude}&'
          'destination=${destino.latitude},${destino.longitude}&'
          'mode=$modo&'
          'alternatives=true&' // ✅ Solicitar alternativas
          'language=es&'
          'region=co&'
          'units=metric&'
          'overview=full&'
          '${modo == 'driving' ? 'departure_time=now&traffic_model=best_guess&' : ''}'
          'key=$_apiKey';

      print('🛣️ Calculando rutas múltiples: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final routes = List<Map<String, dynamic>>.from(data['routes']);
          List<Map<String, dynamic>> rutasProcesadas = [];

          // ✅ PROCESAR CADA RUTA
          for (int i = 0; i < routes.length; i++) {
            final route = routes[i];
            final leg = route['legs'][0];

            // Polilínea detallada concatenando pasos
            final List<LatLng> detailedPoints = [];
            final steps = List<Map<String, dynamic>>.from(leg['steps']);
            for (final step in steps) {
              final encoded = step['polyline']?['points'];
              if (encoded is String && encoded.isNotEmpty) {
                final pts = _decodificarPolyline(encoded);
                if (detailedPoints.isNotEmpty && pts.isNotEmpty &&
                    detailedPoints.last.latitude == pts.first.latitude &&
                    detailedPoints.last.longitude == pts.first.longitude) {
                  detailedPoints.addAll(pts.skip(1));
                } else {
                  detailedPoints.addAll(pts);
                }
              }
            }

            // Fallback a overview si la detallada es corta
            final overviewEncoded = route['overview_polyline']?['points'];
            final overviewPoints = (overviewEncoded is String && overviewEncoded.isNotEmpty)
                ? _decodificarPolyline(overviewEncoded)
                : <LatLng>[];
            final puntos = detailedPoints.length >= 10 ? detailedPoints : overviewPoints;

            // Extraer información
            final distanciaTexto = leg['distance']['text'];
            final duracionTexto = leg['duration']['text'];
            final distanciaMetros = leg['distance']['value'];
            final duracionSegundos = leg['duration']['value'];
            final dTraffic = leg['duration_in_traffic']?['value'];
            final duracionConTraficoSeg = (dTraffic is int) ? dTraffic : duracionSegundos;
            final duracionConTraficoTexto = leg['duration_in_traffic']?['text'];

            rutasProcesadas.add({
              'id': 'ruta_$i',
              'puntos': puntos,
              'distancia_texto': distanciaTexto,
              'duracion_texto': duracionTexto,
              'duracion_trafico_texto': duracionConTraficoTexto,
              'distancia_metros': distanciaMetros,
              'duracion_segundos': duracionSegundos,
              'duracion_trafico_segundos': duracionConTraficoSeg,
              'es_principal': false, // se establecerá luego
              'resumen': duracionConTraficoTexto != null
                  ? '$distanciaTexto • $duracionConTraficoTexto'
                  : '$distanciaTexto • $duracionTexto',
            });
          }

          // ✅ ORDENAR POR TIEMPO EN TRÁFICO PARA IDENTIFICAR LA MÁS RÁPIDA
          rutasProcesadas.sort((a, b) => a['duracion_trafico_segundos']
              .compareTo(b['duracion_trafico_segundos']));

          // ✅ MARCAR PRINCIPAL Y MÁS RÁPIDA
          if (rutasProcesadas.isNotEmpty) {
            rutasProcesadas[0]['es_mas_rapida'] = true;
            rutasProcesadas[0]['es_principal'] = true;
          }

          print('✅ ${rutasProcesadas.length} rutas calculadas (detalladas)');

          return {
            'status': 'success',
            'rutas': rutasProcesadas,
            'ruta_principal': rutasProcesadas.isNotEmpty ? rutasProcesadas[0] : null,
          };
        }
      }

      return null;
    } catch (e) {
      print('❌ Error en calcularRutasMultiples: $e');
      return null;
    }
  }

  // ✅ DECODIFICAR POLYLINE (mismo método que antes)
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

  // ✅ GENERAR COLORES PARA DIFERENTES RUTAS
  static Color getColorForRoute(int index, bool esPrincipal, bool esMasRapida) {
    if (esPrincipal) {
      return const Color(0xFF1565C0); // Azul intenso para principal
    } else {
      // ✅ CAMBIO: Rutas alternativas azul transparente
      return const Color(0xFF1565C0).withOpacity(0.4); // Azul transparente
    }
  }

  // ✅ NUEVO: Obtener punto medio de una ruta para posicionar globo
  static LatLng getPuntoMedioRuta(List<LatLng> puntos) {
    if (puntos.isEmpty) return const LatLng(0, 0);
    if (puntos.length == 1) return puntos.first;

    // Calcular punto medio aproximado
    final indicemedio = (puntos.length / 2).floor();
    return puntos[indicemedio];
  }

  // ✅ NUEVO: Obtener punto estratégico para globo (no muy cerca del inicio)
  static LatLng getPuntoParaGlobo(List<LatLng> puntos) {
    if (puntos.isEmpty) return const LatLng(0, 0);
    if (puntos.length <= 3) return puntos.last;

    // ✅ CAMBIO: Usar un punto que esté al 25% de la ruta (más cerca del inicio)
    // para que el globo no esté muy lejos y sea más fácil de conectar visualmente
    final indice = (puntos.length * 0.25).floor();
    return puntos[indice];
  }
}