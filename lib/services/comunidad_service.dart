import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  // ✅ AGREGAR estos dos métodos nuevos al final del archivo:

  // ✅ NUEVO: Salir de una comunidad (para miembros)
  Future<Map<String, dynamic>> salirDeComunidad(int comunidadId) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        return {
          'status': 'error',
          'message': 'No estás autenticado'
        };
      }

      // ✅ USAR TU RUTA EXACTA: DELETE /api/comunidades/{id}/salir
      final response = await http.delete(
        Uri.parse('${ApiConfig.comunidadesUrl}/$comunidadId/salir'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Salir de comunidad response status: ${response.statusCode}');
      print('Salir de comunidad response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': responseData['message'] ?? 'Has salido de la comunidad exitosamente',
          'data': responseData,
        };
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Error al salir de la comunidad',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      print('Error en salirDeComunidad: $e');
      return {
        'status': 'error',
        'message': 'Error de conexión: ${e.toString()}'
      };
    }
  }

  // ✅ NUEVO: Eliminar una comunidad (solo para creadores/admins)
  Future<Map<String, dynamic>> eliminarComunidad(int comunidadId) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        return {
          'status': 'error',
          'message': 'No estás autenticado'
        };
      }

      // ✅ USAR TU RUTA EXACTA: DELETE /api/comunidades/{id}/eliminar
      final response = await http.delete(
        Uri.parse('${ApiConfig.comunidadesUrl}/$comunidadId/eliminar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Eliminar comunidad response status: ${response.statusCode}');
      print('Eliminar comunidad response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': responseData['message'] ?? 'Comunidad eliminada exitosamente',
          'data': responseData,
        };
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Error al eliminar la comunidad',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      print('Error en eliminarComunidad: $e');
      return {
        'status': 'error',
        'message': 'Error de conexión: ${e.toString()}'
      };
    }
  }

  // ✅ NUEVO: Configurar periodo de competencia (solo creador)
  Future<Map<String, dynamic>> configurarPeriodo({
    required int comunidadId,
    required int duracionDias,
  }) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        return {'status': 'error', 'message': 'No hay sesión activa'};
      }

      final uri = Uri.parse('${ApiConfig.comunidadesUrl}/$comunidadId/configurar-periodo');
      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'duracion_dias': duracionDias}),
      );

      final data = json.decode(resp.body);
      return {
        'status': resp.statusCode == 200 ? 'success' : 'error',
        ...data,
      };
    } catch (e) {
      return {'status': 'error', 'message': 'Error de conexión: ${e.toString()}'};
    }
  }

  // ✅ NUEVO: Sumar/restar puntos en contexto de comunidad
  Future<Map<String, dynamic>> actualizarPuntosComunidad({
    required int comunidadId,
    required int puntos,
    int? duracionDias,
    String? motivo,
  }) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        return {'status': 'error', 'message': 'No hay sesión activa'};
      }

      final uri = Uri.parse('${ApiConfig.comunidadesUrl}/$comunidadId/puntos');
      final body = <String, dynamic>{
        'puntos': puntos,
        if (duracionDias != null) 'duracion_dias': duracionDias,
        if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
      };

      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      final data = json.decode(resp.body);
      return {
        'status': resp.statusCode == 200 ? 'success' : 'error',
        ...data,
      };
    } catch (e) {
      return {'status': 'error', 'message': 'Error de conexión: ${e.toString()}'};
    }
  }

  // ✅ NUEVO: Ranking actual de la comunidad
  Future<Map<String, dynamic>> getRankingActual({
    required int comunidadId,
    int duracionDias = 7,
  }) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        return {'status': 'error', 'message': 'No hay sesión activa'};
      }

      final uri = Uri.parse(
        '${ApiConfig.comunidadesUrl}/$comunidadId/ranking-actual?duracion_dias=$duracionDias',
      );

      final resp = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(resp.body);
      return {
        'status': resp.statusCode == 200 ? 'success' : 'error',
        ...data,
      };
    } catch (e) {
      return {'status': 'error', 'message': 'Error de conexión: ${e.toString()}'};
    }
  }

  // ✅ NUEVO: Historial de competencias (cerradas)
  Future<Map<String, dynamic>> getHistorialCompetencias({
    required int comunidadId,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        return {'status': 'error', 'message': 'No hay sesión activa'};
      }

      final uri = Uri.parse(
        '${ApiConfig.comunidadesUrl}/$comunidadId/historial?page=$page&per_page=$perPage',
      );

      final resp = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(resp.body);
      return {
        'status': resp.statusCode == 200 ? 'success' : 'error',
        ...data,
      };
    } catch (e) {
      return {'status': 'error', 'message': 'Error de conexión: ${e.toString()}'};
    }
  }

  // ✅ NUEVO: Editar competencia activa (cambiar duración y recalcular fecha fin)
  Future<Map<String, dynamic>> editarCompetenciaActiva({
    required int comunidadId,
    required int duracionDias,
  }) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        return {'status': 'error', 'message': 'No hay sesión activa'};
      }

      final uri = Uri.parse('${ApiConfig.comunidadesUrl}/$comunidadId/competencia/editar');
      final resp = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'duracion_dias': duracionDias}),
      );

      final data = json.decode(resp.body);
      return {
        'status': resp.statusCode == 200 ? 'success' : 'error',
        ...data,
      };
    } catch (e) {
      return {'status': 'error', 'message': 'Error de conexión: ${e.toString()}'};
    }
  }

  // ✅ NUEVO: Cerrar competencia actual (solo creador)
  Future<Map<String, dynamic>> cerrarCompetencia({
    required int comunidadId,
    int? forzarGanadorId,
  }) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        return {'status': 'error', 'message': 'No hay sesión activa'};
      }

      final uri = Uri.parse('${ApiConfig.comunidadesUrl}/$comunidadId/competencia/cerrar');
      final body = <String, dynamic>{
        if (forzarGanadorId != null) 'forzar_ganador_id': forzarGanadorId,
      };

      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      final data = json.decode(resp.body);
      return {
        'status': resp.statusCode == 200 ? 'success' : 'error',
        ...data,
      };
    } catch (e) {
      return {'status': 'error', 'message': 'Error de conexión: ${e.toString()}'};
    }
  }

  Future<void> registrarTokenPush() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      // Llama a tu backend para asociar el token al usuario actual
      // await http.post(Uri.parse('$baseUrl/api/notificaciones/token'), body: {'token': token});
    } catch (_) {}
  }
}