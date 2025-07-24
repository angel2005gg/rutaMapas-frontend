import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Para iOS usa el iOS Client ID, para Android usa el Web Client ID
    clientId: Platform.isIOS 
        ? '842914281578-tnbt382ocsb7vnknb8k2hdmpkd2rigj7.apps.googleusercontent.com' // iOS Client ID
        : '842914281578-iatsucr3qaq5sd06r242e7v8sadq222q.apps.googleusercontent.com', // Android Web Client ID
    scopes: ['email', 'profile'],
  );
  final storage = const FlutterSecureStorage();
  // Cambia por tu IP real
  final String _baseUrl = 'http://192.168.0.128:8000/api';

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return {'status': 'error', 'message': 'Sign in cancelled'};

      print('Platform: ${Platform.isIOS ? "iOS" : "Android"}');
      print('Google User ID: ${googleUser.id}');
      print('Google User Name: ${googleUser.displayName}');
      print('Google User Email: ${googleUser.email}');

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/google'),
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

  // Nuevo método para obtener datos del usuario actual
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get user response status: ${response.statusCode}');
      print('Get user response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print('Error en getCurrentUser: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await storage.delete(key: 'token');
  }
}