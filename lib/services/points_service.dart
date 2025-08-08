import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class PointsService {
  static const _storage = FlutterSecureStorage();

  // ✅ SUMAR PUNTOS al iniciar ruta
  static Future<Map<String, dynamic>> darPuntosInicioRuta() async {
    return await _actualizarPuntos(5, 'Ruta iniciada');
  }

  // ✅ SUMAR PUNTOS al completar ruta
  static Future<Map<String, dynamic>> darPuntosRutaCompletada() async {
    return await _actualizarPuntos(15, 'Ruta completada');
  }

  // ✅ RESTAR PUNTOS por salir de la app (para futuro)
  static Future<Map<String, dynamic>> restarPuntosSalidaApp() async {
    return await _actualizarPuntos(-10, 'Salió de la aplicación durante navegación');
  }

  // ✅ MÉTODO PRIVADO para comunicarse con el backend
  static Future<Map<String, dynamic>> _actualizarPuntos(int puntos, String motivo) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        return {'status': 'error', 'message': 'No hay sesión activa'};
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/puntaje/actualizar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'puntos': puntos,
          'motivo': motivo,
        }),
      );

      print('🎯 Points response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'status': 'success',
          'puntos_cambio': puntos,
          'puntaje_actual': data['data']['puntaje_actual'],
          'clasificacion': data['data']['clasificacion'],
        };
      } else {
        return {'status': 'error', 'message': 'Error del servidor'};
      }
    } catch (e) {
      print('❌ Error en points service: $e');
      return {'status': 'error', 'message': 'Error de conexión'};
    }
  }

  // ✅ ACTIVAR RACHA DIARIA (solo 1 vez por día)
  static Future<Map<String, dynamic>> activarRachaDiaria() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        return {'status': 'error', 'message': 'No hay sesión activa'};
      }

      // ✅ VERIFICAR SI YA SE ACTIVÓ HOY
      final ultimaRacha = await _storage.read(key: 'ultima_racha_activada');
      final ahora = DateTime.now();
      final hoyString = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';
      
      if (ultimaRacha == hoyString) {
        print('⏰ Racha ya activada hoy: $hoyString');
        return {
          'status': 'info', 
          'message': 'Racha ya activada hoy',
          'ya_activada': true
        };
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/puntaje/racha'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'racha': 1,
          'accion': 'incrementar',
        }),
      );

      print('🎯 Racha response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        // ✅ GUARDAR QUE SE ACTIVÓ HOY
        await _storage.write(key: 'ultima_racha_activada', value: hoyString);
        
        final data = json.decode(response.body);
        return {
          'status': 'success',
          'racha_actual': data['data']['racha_actual'],
          'primera_vez_hoy': true
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'status': 'error', 
          'message': errorData['message'] ?? 'Error del servidor'
        };
      }
    } catch (e) {
      print('❌ Error en activarRachaDiaria: $e');
      return {'status': 'error', 'message': 'Error de conexión'};
    }
  }
}