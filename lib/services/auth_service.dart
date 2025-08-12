import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart'; // ✅ IMPORTAR CONFIGURACIÓN
import 'dart:async';
class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: Platform.isIOS 
        ? '842914281578-tnbt382ocsb7vnknb8k2hdmpkd2rigj7.apps.googleusercontent.com'
        : '842914281578-iatsucr3qaq5sd06r242e7v8sadq222q.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );
  final storage = const FlutterSecureStorage();
  
  // ✅ USAR CONFIGURACIÓN CENTRAL
  final String _baseUrl = ApiConfig.baseUrl;

  // MÉTODO EXISTENTE DE GOOGLE (NO CAMBIAR)
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return {'status': 'error', 'message': 'Sign in cancelled'};

      print('Platform: ${Platform.isIOS ? "iOS" : "Android"}');
      print('Google User ID: ${googleUser.id}');
      print('Google User Name: ${googleUser.displayName}');
      print('Google User Email: ${googleUser.email}');

      final response = await http.post(
        Uri.parse('${ApiConfig.authUrl}/google'), // ✅ USAR CONFIGURACIÓN
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'google_uid': googleUser.id,
          'nombre': googleUser.displayName ?? '',
          'correo': googleUser.email,
          'foto_perfil': googleUser.photoUrl,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        await storage.write(key: 'token', value: responseData['token']);
        return responseData;
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Error en la autenticación'
        };
      }
    } catch (e) {
      print('Error en signInWithGoogle: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ✅ ARREGLADO: Login inteligente con manejo correcto de errores
  Future<Map<String, dynamic>> smartLogin(String email, String password) async {
    try {
      // Primero intenta login directo
      final response = await http.post(
        Uri.parse('${ApiConfig.authUrl}/login'), // ✅ USAR CONFIGURACIÓN
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'correo': email,
          'password': password,
        }),
      );

      print('Smart login response status: ${response.statusCode}');
      print('Smart login response body: ${response.body}');

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        // Login exitoso, guardar token
        await storage.write(key: 'token', value: responseData['token']);
        return {
          'status': 'success',
          'type': 'direct_login',
          'message': 'Login exitoso',
          'user': responseData['user'],
          'token': responseData['token']
        };
      } else if (response.statusCode == 404) {
        // Usuario NO existe - enviar código para registro
        return await sendVerificationCode(email, password);
      } else if (response.statusCode == 401) {
        // ✅ ARREGLADO: Usuario existe pero contraseña incorrecta
        return {
          'status': 'error',
          'message': 'Contraseña incorrecta. Verifica tus datos.',
        };
      } else {
        // Otros errores del servidor
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Error en el servidor',
        };
      }
    } catch (e) {
      print('Error en smartLogin: $e');
      return {'status': 'error', 'message': 'Error de conexión: ${e.toString()}'};
    }
  }

  // MÉTODO EXISTENTE: Enviar código de verificación por email
  Future<Map<String, dynamic>> sendVerificationCode(String email, String password, [String? nombre]) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.authUrl}/send-code'), // ✅ USAR CONFIGURACIÓN
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'correo': email,
          'password': password,
          'nombre': nombre ?? 'Usuario',
        }),
      );

      print('Send code response status: ${response.statusCode}');
      print('Send code response body: ${response.body}');

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'type': 'verification_needed',
          'message': responseData['message'],
          'debug': responseData['debug'] ?? null,
        };
      }
      
      return responseData;
    } catch (e) {
      print('Error en sendVerificationCode: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // MÉTODO EXISTENTE: Verificar código
  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.authUrl}/verify-code'), // ✅ USAR CONFIGURACIÓN
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'correo': email,
          'codigo': code,
        }),
      );

      print('Verify code response status: ${response.statusCode}');
      print('Verify code response body: ${response.body}');

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        await storage.write(key: 'token', value: responseData['token']);
        return responseData;
      }
      
      return responseData;
    } catch (e) {
      print('Error en verifyCode: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // MÉTODO EXISTENTE (NO CAMBIAR)
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        print('🔍 No hay token guardado');
        return null;
      }

      print('🔍 Token encontrado, verificando validez...');
      
      // ✅ TIMEOUT MÁS CORTO PARA RESPUESTA RÁPIDA
      final response = await http.get(
        Uri.parse(ApiConfig.userUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 6), // ✅ TIMEOUT DE 6 SEGUNDOS
        onTimeout: () {
          throw TimeoutException('Server response timeout');
        },
      );

      print('🔍 AuthService.getCurrentUser response status: ${response.statusCode}');
      print('🔍 AuthService.getCurrentUser response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // ✅ DEBUG ESPECÍFICO PARA LA RACHA
        if (data['user'] != null) {
          print('🔍 Racha en AuthService: ${data['user']['racha_actual']}');
        }
        
        return data;
      } else {
        // ✅ SI EL TOKEN NO ES VÁLIDO, ELIMINARLO
        await storage.delete(key: 'token');
        return null;
      }
    } catch (e) {
      print('❌ Error en getCurrentUser: $e');
      
      // ✅ SI HAY ERROR, ELIMINAR TOKEN INVÁLIDO
      try {
        await storage.delete(key: 'token');
      } catch (_) {}
      
      // ✅ RE-LANZAR EL ERROR PARA QUE SPLASH LO MANEJE
      rethrow;
    }
  }

  // ✅ AGREGAR ESTE MÉTODO AL AuthService (después de getCurrentUser)
  Future<bool> hasValidSession() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        print('🔍 No hay token guardado');
        return false;
      }

      print('🔍 Token encontrado, verificando validez...');
      
      // Verificar que el token funcione haciendo una llamada al usuario
      final response = await http.get(
        Uri.parse(ApiConfig.userUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        if (userData['status'] == 'success') {
          print('✅ Sesión válida confirmada');
          return true;
        }
      }
      
      print('❌ Token inválido o expirado');
      // Si el token no es válido, eliminarlo
      await storage.delete(key: 'token');
      return false;
      
    } catch (e) {
      print('❌ Error verificando sesión: $e');
      return false;
    }
  }

  // // MÉTODO EXISTENTE (NO CAMBIAR)
  // Future<void> logout() async {
  //   await _googleSignIn.signOut();
  //   await storage.delete(key: 'token');
  // }

  // ✅ MANTENER SOLO ESTE (el completo):
Future<void> logout() async {
  try {
    // Cerrar sesión de Google si existe
    await _googleSignIn.signOut();
    
    // Eliminar token guardado
    await storage.delete(key: 'token');
    
    // Limpiar cualquier otro dato guardado (opcional)
    await storage.deleteAll();
    
    print('✅ Logout completo realizado');
  } catch (e) {
    print('❌ Error en logout: $e');
    // Aún así eliminar el token
    await storage.delete(key: 'token');
  }
}
}