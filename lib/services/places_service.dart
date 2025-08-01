import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlacesService {
  // ✅ VERIFICAR QUE SEA LA MISMA API KEY
  static const String _apiKey = 'AIzaSyCP1xS8HLdxQe-a1KeuXGQzaVIqoQvKmYo';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // ✅ AGREGAR ESTE MÉTODO QUE FALTA
  static Future<void> testPlacesAPI() async {
    const testUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
        'location=3.4516,-76.5320&'  // Cali, Colombia
        'radius=1000&'
        'type=restaurant&'
        'key=$_apiKey';
    
    print('🧪 Testing Places API...');
    print('🔗 URL: $testUrl');
    
    try {
      final response = await http.get(Uri.parse(testUrl));
      print('📱 Status Code: ${response.statusCode}');
      print('📄 Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Status: ${data['status']}');
        print('📍 Results: ${data['results']?.length ?? 0}');
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  // ✅ MEJORAR el método para debug
  static Future<List<Map<String, dynamic>>> buscarLugaresCercanos({
    required LatLng ubicacion,
    required String tipo,
    int radio = 1500, // ✅ REDUCIR radio para resultados más cercanos
  }) async {
    try {
      final url = '$_baseUrl/nearbysearch/json?'
          'location=${ubicacion.latitude},${ubicacion.longitude}&'
          'radius=$radio&'
          'type=$tipo&'
          'key=$_apiKey';

      print('🔗 Buscando $tipo en: $url'); // ✅ DEBUG

      final response = await http.get(Uri.parse(url));
      
      print('📱 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('📊 Response status: ${data['status']}');
        print('📍 Resultados encontrados: ${data['results']?.length ?? 0}');
        
        if (data['status'] == 'OK') {
          final results = List<Map<String, dynamic>>.from(data['results']);
          print('✅ $tipo: ${results.length} lugares encontrados');
          return results;
        } else {
          print('❌ API Error: ${data['status']} - ${data['error_message'] ?? 'Sin mensaje'}');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Response: ${response.body}');
      }
      
      return [];
    } catch (e) {
      print('❌ Exception en buscarLugaresCercanos: $e');
      return [];
    }
  }

  // ✅ SIMPLIFICAR tipos para test inicial
  static Future<Map<String, List<Map<String, dynamic>>>> buscarLugaresComerciales({
    required LatLng ubicacion,
    int radio = 1500, // ✅ Radio más pequeño
  }) async {
    // ✅ EMPEZAR SOLO CON ALGUNOS TIPOS PARA TESTING
    final tiposLugares = {
      'restaurantes': 'restaurant',
      'gasolineras': 'gas_station',
      'bancos': 'bank',
      // ✅ Comentar los demás hasta que funcionen estos
      // 'hoteles': 'lodging',
      // 'farmacias': 'pharmacy', 
      // 'supermercados': 'supermarket',
      // 'hospitales': 'hospital',
      // 'centros_comerciales': 'shopping_mall',
      // 'tiendas': 'store',
    };

    Map<String, List<Map<String, dynamic>>> resultados = {};

    print('🌍 Buscando lugares cerca de: ${ubicacion.latitude}, ${ubicacion.longitude}');

    // ✅ BUSCAR cada tipo con delay más corto
    for (var entry in tiposLugares.entries) {
      print('🔍 Buscando: ${entry.key}...');
      
      final lugares = await buscarLugaresCercanos(
        ubicacion: ubicacion,
        tipo: entry.value,
        radio: radio,
      );
      
      if (lugares.isNotEmpty) {
        resultados[entry.key] = lugares;
        print('✅ ${entry.key}: ${lugares.length} lugares agregados');
      } else {
        print('⚠️ ${entry.key}: No se encontraron lugares');
      }
      
      // ✅ Delay más corto para no saturar
      await Future.delayed(const Duration(milliseconds: 50));
    }

    print('🎯 Total de categorías con resultados: ${resultados.length}');
    return resultados;
  }

  // ✅ Convertir resultado de Places API a marcador
  static Marker crearMarcadorDeLugar({
    required Map<String, dynamic> lugar,
    required String categoria,
  }) {
    final geometry = lugar['geometry'];
    final location = geometry['location'];
    final lat = location['lat'];
    final lng = location['lng'];
    
    return Marker(
      markerId: MarkerId('${categoria}_${lugar['place_id']}'),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(
        title: lugar['name'] ?? 'Sin nombre',
        snippet: _obtenerSnippet(lugar, categoria),
      ),
      icon: _obtenerIconoPorCategoria(categoria),
    );
  }

  // ✅ Obtener snippet (descripción corta) del lugar
  static String _obtenerSnippet(Map<String, dynamic> lugar, String categoria) {
    String snippet = _obtenerNombreCategoria(categoria);
    
    // Agregar rating si existe
    if (lugar['rating'] != null) {
      snippet += ' • ⭐ ${lugar['rating']}';
    }
    
    // Agregar estado si está abierto
    if (lugar['opening_hours'] != null && lugar['opening_hours']['open_now'] != null) {
      snippet += lugar['opening_hours']['open_now'] ? ' • Abierto' : ' • Cerrado';
    }
    
    return snippet;
  }

  // ✅ Obtener ícono según la categoría
  static BitmapDescriptor _obtenerIconoPorCategoria(String categoria) {
    switch (categoria) {
      case 'restaurantes':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'gasolineras':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'hoteles':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      case 'farmacias':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'bancos':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case 'supermercados':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
      case 'hospitales':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'centros_comerciales':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case 'tiendas':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  // ✅ Nombres amigables para las categorías
  static String _obtenerNombreCategoria(String categoria) {
    switch (categoria) {
      case 'restaurantes': return 'Restaurante';
      case 'gasolineras': return 'Gasolinera';
      case 'hoteles': return 'Hotel';
      case 'farmacias': return 'Farmacia';
      case 'bancos': return 'Banco';
      case 'supermercados': return 'Supermercado';
      case 'hospitales': return 'Hospital';
      case 'centros_comerciales': return 'Centro Comercial';
      case 'tiendas': return 'Tienda';
      default: return 'Lugar';
    }
  }
}