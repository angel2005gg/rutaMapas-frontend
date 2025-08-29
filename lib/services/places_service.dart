// ignore_for_file: unused_element
import 'dart:convert';
import 'dart:ui' as ui; // AGREGAR
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart'; // AGREGAR

// ✅ AGREGAR CACHE AL INICIO DE LA CLASE PlacesService:
class PlacesService {
  static const String _apiKey = 'AIzaSyCP1xS8HLdxQe-a1KeuXGQzaVIqoQvKmYo';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  
  // ✅ NUEVO: Cache simple para evitar requests repetidos
  static final Map<String, List<Map<String, dynamic>>> _cache = {};
  static DateTime? _lastCacheTime;
  
  // ✅ MÉTODO PARA VERIFICAR CACHE
  static bool _isCacheValid() {
    if (_lastCacheTime == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_lastCacheTime!).inMinutes;
    return difference < 5; // Cache válido por 5 minutos
  }

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
    // ✅ VERIFICAR CACHE ANTES DE HACER LA PETICIÓN
    final cacheKey = '${ubicacion.latitude},${ubicacion.longitude}-$tipo-$radio';
    if (_isCacheValid() && _cache.containsKey(cacheKey)) {
      print('📦 Usando datos de cache para $cacheKey');
      return _cache[cacheKey]!;
    }

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
          
          // ✅ ALMACENAR EN CACHE
          _cache[cacheKey] = results;
          _lastCacheTime = DateTime.now();
          
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
    int radio = 3000, // ✅ AUMENTAR de 1000 a 3000 metros
  }) async {
    // ✅ AGREGAR MÁS CATEGORÍAS como Google Maps
    final tiposLugares = {
      'gasolineras': 'gas_station',
      'restaurantes': 'restaurant',
      'bancos': 'bank',
      'supermercados': 'supermarket',
      'farmacias': 'pharmacy',
      'hospitales': 'hospital',
      // 'hoteles': 'lodging', // Opcional
    };

    Map<String, List<Map<String, dynamic>>> resultados = {};

    print('🌍 Buscando lugares cerca de: ${ubicacion.latitude}, ${ubicacion.longitude}');
    print('💰 Costo estimado: ${tiposLugares.length * 0.032} USD por búsqueda');

    for (var entry in tiposLugares.entries) {
      print('🔍 Buscando: ${entry.key}...');
      
      final lugares = await buscarLugaresCercanos(
        ubicacion: ubicacion,
        tipo: entry.value,
        radio: radio,
      );
      
      if (lugares.isNotEmpty) {
        // ✅ AUMENTAR de 2 a 5 lugares por categoría
        resultados[entry.key] = lugares.take(5).toList();
        print('✅ ${entry.key}: ${lugares.take(5).length} lugares agregados');
      } else {
        print('⚠️ ${entry.key}: No se encontraron lugares');
      }
      
      // ✅ Delay más corto para cargar más rápido
      await Future.delayed(const Duration(milliseconds: 50));
    }

    print('🎯 Total de categorías con resultados: ${resultados.length}');
    print('📊 Total de lugares: ${resultados.values.fold(0, (sum, list) => sum + list.length)}');
    
    return resultados;
  }

  // ✅ REEMPLAZAR el método crearMarcadorDeLugar por esta versión con burbuja personalizada:
  static Future<Marker> crearMarcadorDeLugarConBurbuja({
    required Map<String, dynamic> lugar,
    required String categoria,
  }) async {
    final geometry = lugar['geometry'];
    final location = geometry['location'];
    final lat = location['lat'];
    final lng = location['lng'];
    final nombre = lugar['name'] ?? 'Sin nombre';
    
    // ✅ CREAR ICONO PERSONALIZADO CON BURBUJA + TEXTO + ICONO
    final BitmapDescriptor iconoPersonalizado = await _crearIconoConBurbuja(
      nombre: nombre,
      categoria: categoria,
      rating: lugar['rating'],
    );
    
    return Marker(
      markerId: MarkerId('${categoria}_${lugar['place_id']}'),
      position: LatLng(lat, lng),
      icon: iconoPersonalizado,
      onTap: () {
        debugPrint('📍 Tapped: $nombre');
      },
    );
  }

  // ✅ NUEVO: Método para crear icono personalizado con burbuja (icono + texto)
  static Future<BitmapDescriptor> _crearIconoConBurbuja({
    required String nombre,
    required String categoria,
    double? rating, // ✅ AGREGADO: parámetro opcional para evitar el error
    double devicePixelRatio = 3.0, // escala para nitidez
  }) async {
    // Configuración visual
    final Color baseColor = _obtenerColorPlanoCategoria(categoria);
    final IconData iconData = _obtenerIconoCategoria(categoria);
    final String texto = _truncarNombre(nombre, maxChars: 16);

    // Tamaños “densos” para un bitmap nítido
    final double iconSize = 28.0 * devicePixelRatio;
    final double textSize = 24.0 * devicePixelRatio;
    final double paddingH = 16.0 * devicePixelRatio;
    final double paddingV = 10.0 * devicePixelRatio;
    final double spacing = 10.0 * devicePixelRatio;
    final double borderRadius = 20.0 * devicePixelRatio;
    final double borderWidth = 2.0 * devicePixelRatio;

    // Mide texto
    final textPainter = TextPainter(
      text: TextSpan(
        text: texto,
        style: TextStyle(
          color: const Color(0xFF1F2937), // gris oscuro
          fontSize: textSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout();

    final double contentWidth = iconSize + spacing + textPainter.width;
    final double width = contentWidth + paddingH * 2;
    final double height = iconSize + paddingV * 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      Radius.circular(borderRadius),
    );

    // Fondo
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRRect(rrect, bgPaint);

    // Borde
    final borderPaint = Paint()
      ..color = const Color(0xFFE5E7EB) // gris claro
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(rrect, borderPaint);

    // Dibuja icono (como glyph de MaterialIcons)
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: baseColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double iconX = paddingH;
    final double iconY = (height - iconPainter.height) / 2;
    iconPainter.paint(canvas, Offset(iconX, iconY));

    // Dibuja texto
    final double textX = iconX + iconPainter.width + spacing;
    final double textY = (height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(textX, textY));

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
  }

  // ✅ Helpers de estilo e iconos planos
  static Color _obtenerColorPlanoCategoria(String categoria) {
    switch (categoria) {
      case 'restaurantes': return const Color(0xFFEF6C00); // naranja
      case 'gasolineras': return const Color(0xFF1565C0); // azul
      case 'bancos': return const Color(0xFFF59E0B); // ámbar
      case 'supermercados': return const Color(0xFF2E7D32); // verde
      case 'farmacias': return const Color(0xFF2E7D32); // verde
      case 'hospitales': return const Color(0xFFD32F2F); // rojo
      case 'centros_comerciales': return const Color(0xFF7B1FA2); // morado
      default: return const Color(0xFF6B7280); // gris
    }
  }

  static IconData _obtenerIconoCategoria(String categoria) {
    switch (categoria) {
      case 'restaurantes': return Icons.restaurant;
      case 'gasolineras': return Icons.local_gas_station;
      case 'bancos': return Icons.account_balance;
      case 'supermercados': return Icons.shopping_cart;
      case 'farmacias': return Icons.local_pharmacy;
      case 'hospitales': return Icons.local_hospital;
      case 'centros_comerciales': return Icons.local_mall;
      case 'hoteles': return Icons.bed;
      default: return Icons.place;
    }
  }

  static String _truncarNombre(String nombre, {int maxChars = 16}) {
    if (nombre.length <= maxChars) return nombre;
    return '${nombre.substring(0, maxChars)}…';
  }

  // ✅ NUEVO: Obtener color para cada categoría
  static double _obtenerColorCategoria(String categoria) {
    switch (categoria) {
      case 'restaurantes': return BitmapDescriptor.hueOrange;  // Naranja
      case 'gasolineras': return BitmapDescriptor.hueBlue;     // Azul
      case 'bancos': return BitmapDescriptor.hueYellow;        // Amarillo
      case 'supermercados': return BitmapDescriptor.hueGreen;  // Verde
      case 'farmacias': return BitmapDescriptor.hueGreen;      // Verde
      case 'hospitales': return BitmapDescriptor.hueRed;       // Rojo
      default: return BitmapDescriptor.hueViolet;              // Morado
    }
  }

  // ✅ MODIFICAR el método original para que use la nueva versión:
  static Future<Marker> crearMarcadorDeLugar({
    required Map<String, dynamic> lugar,
    required String categoria,
  }) async {
    return await crearMarcadorDeLugarConBurbuja(
      lugar: lugar,
      categoria: categoria,
    );
  }

  // ✅ NUEVO: Snippet simple como Google Maps
  static String _obtenerSnippetSimple(Map<String, dynamic> lugar, String categoria) {
    List<String> info = [];
    
    // Solo emoji + rating si existe
    final emoji = _obtenerEmojiCategoria(categoria);
    info.add(emoji);
    
    // Rating simple
    if (lugar['rating'] != null) {
      final rating = lugar['rating'].toString();
      info.add('⭐ $rating');
    }
    
    // Estado simple
    if (lugar['opening_hours'] != null && lugar['opening_hours']['open_now'] != null) {
      final abierto = lugar['opening_hours']['open_now'];
      info.add(abierto ? 'Abierto' : 'Cerrado');
    }
    
    return info.join(' • ');
  }

  // ✅ NUEVO: Iconos más parecidos a Google Maps
  static BitmapDescriptor _obtenerIconoEstiloGoogle(String categoria) {
    switch (categoria) {
      case 'restaurantes':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange); // Naranja
      case 'gasolineras':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);   // Azul
      case 'bancos':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow); // Amarillo
      case 'supermercados':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);  // Verde
      case 'farmacias':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);  // Verde
      case 'hospitales':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);    // Rojo
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet); // Morado por defecto
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

  // ✅ NUEVO: Búsqueda por texto usando Google Places Text Search
  static Future<List<Map<String, dynamic>>> buscarLugaresPorTexto({
    required String consulta,
    LatLng? ubicacionActual,
    int radio = 5000,
  }) async {
    try {
      // Preparar URL para Text Search
      String url = '$_baseUrl/textsearch/json?'
          'query=${Uri.encodeComponent(consulta)}&'
          'key=$_apiKey';
      
      // Si hay ubicación actual, agregar bias de ubicación
      if (ubicacionActual != null) {
        url += '&location=${ubicacionActual.latitude},${ubicacionActual.longitude}'
            '&radius=$radio';
      }

      print('🔍 Búsqueda de texto: $consulta');
      print('🔗 URL: $url');

      final response = await http.get(Uri.parse(url));
      
      print('📱 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('📊 Response status: ${data['status']}');
        print('📍 Resultados encontrados: ${data['results']?.length ?? 0}');
        
        if (data['status'] == 'OK') {
          final results = List<Map<String, dynamic>>.from(data['results']);
          
          // Convertir resultados al formato esperado
          List<Map<String, dynamic>> lugaresFormateados = [];
          
          for (var lugar in results.take(5)) { // Máximo 5 resultados
            final geometry = lugar['geometry'];
            final location = geometry['location'];
            final coordenadas = LatLng(location['lat'], location['lng']);
            
            lugaresFormateados.add({
              'nombre': lugar['name'] ?? 'Sin nombre',
              'direccion': lugar['formatted_address'] ?? 'Dirección no disponible',
              'coordenadas': coordenadas,
              'rating': lugar['rating'],
              'tipo': (lugar['types'] as List?)?.join(',') ?? 'lugar',
            });
          }
          
          print('✅ Búsqueda texto: ${lugaresFormateados.length} lugares formateados');
          return lugaresFormateados;
        } else {
          print('❌ API Error: ${data['status']} - ${data['error_message'] ?? 'Sin mensaje'}');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Response: ${response.body}');
      }
      
      return [];
    } catch (e) {
      print('❌ Exception en buscarLugaresPorTexto: $e');
      return [];
    }
  }

  // ✅ AGREGAR ESTOS MÉTODOS al final de la clase PlacesService:

  // ✅ NUEVO: Emojis para categorías
  static String _obtenerEmojiCategoria(String categoria) {
    switch (categoria) {
      case 'restaurantes': return '🍽️';
      case 'gasolineras': return '⛽';
      case 'bancos': return '🏦';
      case 'hoteles': return '🏨';
      case 'farmacias': return '💊';
      case 'supermercados': return '🛒';
      case 'hospitales': return '🏥';
      case 'talleres': return '🔧';
      default: return '📍';
    }
  }
}