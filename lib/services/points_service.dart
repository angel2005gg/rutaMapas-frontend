import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'comunidad_service.dart'; // ✅ para actualizar puntos en comunidad (fallback)

class PointsService {
  static const _storage = FlutterSecureStorage();

  // ✅ SUMAR PUNTOS al iniciar ruta
  static Future<Map<String, dynamic>> darPuntosInicioRuta() async {
    final res = await _actualizarPuntos(1, 'Ruta iniciada');
    // Enviar a TODAS las comunidades con competencia activa (sin duplicar)
    await _aplicarPuntosTodasComunidades(1, 'Ruta iniciada');
    return res;
  }

  // ✅ SUMAR PUNTOS al completar ruta
  static Future<Map<String, dynamic>> darPuntosRutaCompletada() async {
    final res = await _actualizarPuntos(15, 'Ruta completada');
    await _aplicarPuntosTodasComunidades(15, 'Ruta completada');
    return res;
  }

  // ✅ RESTAR PUNTOS por salir de la app (para futuro)
  static Future<Map<String, dynamic>> restarPuntosSalidaApp() async {
    final res = await _actualizarPuntos(-10, 'Salió de la aplicación durante navegación');
    await _aplicarPuntosTodasComunidades(-10, 'Distracción: salió de la app');
    return res;
  }

  // ✅ NUEVO: Ajuste de puntos por distracciones (apps/llamadas)
  static Future<Map<String, dynamic>> ajustarPuntosPorDistracciones(
    int puntos,
    String motivo,
  ) async {
    final res = await _actualizarPuntos(puntos, motivo);
    await _aplicarPuntosTodasComunidades(puntos, motivo);
    return res;
  }

  // ✅ Enviar puntos a TODAS las comunidades del usuario con competencia activa
  // Usa POST /puntaje/aplicar-todas. Si falla o no existe, hace fallback a la lógica previa
  // de una sola comunidad seleccionada para no romper el flujo.
  static Future<void> _aplicarPuntosTodasComunidades(
    int puntos,
    String motivo, {
    bool soloSiActiva = true,
    int? duracionDias,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return; // sin sesión, omitir

      final uri = Uri.parse('${ApiConfig.baseUrl}/puntaje/aplicar-todas');
      final body = <String, dynamic>{
        'puntos': puntos,
        if (motivo.isNotEmpty) 'motivo': motivo,
        'solo_si_activa': soloSiActiva,
        if (duracionDias != null) 'duracion_dias': duracionDias,
      };

      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      // 200 => aplicado; cualquier otro => fallback opcional
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final applied = data['data']?['comunidades_aplicadas'];
        final omitted = data['data']?['comunidades_omitidas'];
        print('🏆 aplicar-todas OK: aplicadas=${applied ?? []}, omitidas=${omitted ?? []}');
        return;
      } else {
        print('⚠️ aplicar-todas falló: ${resp.statusCode} - ${resp.body}');
        // Fallback: mantener comportamiento previo para NO dejar de acreditar al menos
        await _actualizarPuntosCompetencia(puntos, motivo);
      }
    } catch (e) {
      print('⚠️ aplicar-todas exception: $e');
      // Fallback: mantener comportamiento previo si hay error de red o parsing
      await _actualizarPuntosCompetencia(puntos, motivo);
    }
  }

  // ✅ Enviar puntos a la competencia de la comunidad actual (si existe)
  static Future<void> _actualizarPuntosCompetencia(int puntos, String motivo) async {
    try {
      final comunidadIdStr = await _storage.read(key: 'comunidad_actual_id');
      if (comunidadIdStr == null) {
        // No hay comunidad seleccionada, no aplicar en competencia
        return;
      }
      final comunidadId = int.tryParse(comunidadIdStr);
      if (comunidadId == null) return;

      final svc = ComunidadService();
      final resp = await svc.actualizarPuntosComunidad(
        comunidadId: comunidadId,
        puntos: puntos,
        motivo: motivo,
      );
      print('🏆 Competencia puntos resp: ${resp['status']} - ${resp['message'] ?? ''}');
    } catch (e) {
      print('⚠️ No se pudo actualizar puntos de competencia: $e');
    }
  }

  // ✅ MÉTODO PRIVADO para comunicarse con el backend (puntaje global)
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
          'puntaje_actual': data['data']?['puntaje_actual'],
          'clasificacion': data['data']?['clasificacion'],
        };
      } else {
        return {'status': 'error', 'message': 'Error del servidor'};
      }
    } catch (e) {
      print('❌ Error en points service: $e');
      return {'status': 'error', 'message': 'Error de conexión'};
    }
  }

  // ✅ ACTIVAR RACHA DIARIA (reinicia si se perdió y empieza desde 1)
  static Future<Map<String, dynamic>> activarRachaDiaria() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        return {'status': 'error', 'message': 'No hay sesión activa'};
      }

      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      final hoyString = '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';

      final ultimaRacha = await _storage.read(key: 'ultima_racha_activada');
      if (ultimaRacha == hoyString) {
        // Ya activada hoy, no sumar doble
        return {
          'status': 'info',
          'message': 'Racha ya activada hoy',
          'ya_activada': true
        };
      }

      // Calcular diferencia de días
      int diffDias = 999;
      if (ultimaRacha != null) {
        try {
          final last = DateTime.parse(ultimaRacha);
          final lastDay = DateTime(last.year, last.month, last.day);
          diffDias = hoy.difference(lastDay).inDays;
        } catch (_) {
          diffDias = 999;
        }
      }

      // Si se saltó al menos un día completo, reiniciar en backend a 0
      if (diffDias >= 2) {
        try {
          await http.post(
            Uri.parse('${ApiConfig.baseUrl}/puntaje/racha'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'racha': 0,
              'accion': 'reiniciar',
            }),
          );
        } catch (_) {
          // Ignorar error de reset y continuar
        }
      }

      // Incrementar (si venía de reset => arranca en 1)
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

      if (response.statusCode == 200) {
        await _storage.write(key: 'ultima_racha_activada', value: hoyString);
        final data = json.decode(response.body);
        return {
          'status': 'success',
          'racha_actual': data['data']['racha_actual'],
          'primera_vez_hoy': true,
          'reiniciada': diffDias >= 2, // ✅ indica que empezó desde 0
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

  // ✅ NUEVO: Verificar si se saltó un día y resetear racha en backend
  static Future<Map<String, dynamic>> verificarRachaYResetSiCorresponde() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return {'status': 'error', 'message': 'No hay sesión activa'};

      final ultimaRacha = await _storage.read(key: 'ultima_racha_activada');
      if (ultimaRacha == null) return {'status': 'ok', 'sin_racha_local': true};

      final last = DateTime.parse(ultimaRacha); // formato YYYY-MM-DD
      final now = DateTime.now();
      final hoy = DateTime(now.year, now.month, now.day);
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = hoy.difference(lastDay).inDays;

      // Si no se activó ni hoy ni ayer => racha rota
      if (diff >= 2) {
        final resp = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/puntaje/racha'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'racha': 0,
            'accion': 'reiniciar', // el backend debe soportar esta acción
          }),
        );

        if (resp.statusCode == 200) {
          await _storage.delete(key: 'ultima_racha_activada');
          return {'status': 'success', 'reset': true};
        } else {
          // Aún así limpiar local para no mostrar racha fantasma
          await _storage.delete(key: 'ultima_racha_activada');
          return {'status': 'error', 'message': 'No se pudo resetear en servidor, limpiado local'};
        }
      }

      return {'status': 'ok', 'reset': false};
    } catch (e) {
      return {'status': 'error', 'message': 'Error verificando racha: $e'};
    }
  }
}