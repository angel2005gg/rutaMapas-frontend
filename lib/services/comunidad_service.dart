import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart'; // ✅ IMPORTAR CONFIGURACIÓN

class ComunidadService {
  final storage = const FlutterSecureStorage();

  // ✅ CREAR COMUNIDAD - Conectar con backend real
  Future<Map<String, dynamic>> crearComunidad({
    required String nombre,
    String? descripcion,
  }) async {
    try {
      // Obtener token del usuario
      final token = await storage.read(key: 'token');
      if (token == null) {
        return {'status': 'error', 'message': 'No hay sesión activa'};
      }

      // Llamada real al backend
      final response = await http.post(
        Uri.parse('${ApiConfig.comunidadesUrl}/crear'), // ✅ USAR CONFIGURACIÓN
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'nombre': nombre,
          'descripcion': descripcion,
        }),
      );

      print('Crear comunidad - Status: ${response.statusCode}');
      print('Crear comunidad - Response: ${response.body}');

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData; // Devuelve respuesta exitosa con código real
      } else {
        return responseData; // Devuelve errores de validación
      }
    } catch (e) {
      print('Error en crearComunidad: $e');
      return {'status': 'error', 'message': 'Error de conexión: ${e.toString()}'};
    }
  }

  // ✅ UNIRSE A COMUNIDAD - Conectar con backend real
  Future<Map<String, dynamic>> unirseAComunidad({
    required String codigoUnico,
  }) async {
    try {
      // Obtener token del usuario
      final token = await storage.read(key: 'token');
      if (token == null) {
        return {'status': 'error', 'message': 'No hay sesión activa'};
      }

      // Llamada real al backend
      final response = await http.post(
        Uri.parse('${ApiConfig.comunidadesUrl}/unirse'), // ✅ USAR CONFIGURACIÓN
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'codigo_unico': codigoUnico.toUpperCase(),
        }),
      );

      print('Unirse comunidad - Status: ${response.statusCode}');
      print('Unirse comunidad - Response: ${response.body}');

      final responseData = json.decode(response.body);
      return responseData; // Devuelve respuesta (éxito o error)
    } catch (e) {
      print('Error en unirseAComunidad: $e');
      return {'status': 'error', 'message': 'Error de conexión: ${e.toString()}'};
    }
  }

  // ✅ OBTENER MIS COMUNIDADES - Para uso futuro
  Future<Map<String, dynamic>> obtenerMisComunidades() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        return {'status': 'error', 'message': 'No hay sesión activa'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.comunidadesUrl}/mis-comunidades'), // ✅ USAR CONFIGURACIÓN
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Mis comunidades - Status: ${response.statusCode}');
      print('Mis comunidades - Response: ${response.body}');

      return json.decode(response.body);
    } catch (e) {
      print('Error en obtenerMisComunidades: $e');
      return {'status': 'error', 'message': 'Error de conexión: ${e.toString()}'};
    }
  }

  // ✅ OBTENER DETALLES DE COMUNIDAD - Para uso futuro
  Future<Map<String, dynamic>> obtenerDetallesComunidad({
    required int comunidadId,
  }) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        return {'status': 'error', 'message': 'No hay sesión activa'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/comunidades/$comunidadId'), // ✅ USAR CONFIGURACIÓN
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Detalles comunidad - Status: ${response.statusCode}');
      print('Detalles comunidad - Response: ${response.body}');

      return json.decode(response.body);
    } catch (e) {
      print('Error en obtenerDetallesComunidad: $e');
      return {'status': 'error', 'message': 'Error de conexión: ${e.toString()}'};
    }
  }
}