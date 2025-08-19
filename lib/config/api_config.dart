class ApiConfig {
  // ✅ CONFIGURACIÓN CENTRAL - Solo cambiar aquí para toda la app
  // Producción
  static const String baseUrl = 'http://api.kamati.co/api';
  
  // Desarrollo (dejar como referencia)
  // static const String baseUrl = 'http://192.168.0.134:8000/api';
  
  // ✅ URLs específicas (opcional - para mejor organización)
  static const String authUrl = '$baseUrl/auth';
  static const String comunidadesUrl = '$baseUrl/comunidades';
  static const String userUrl = '$baseUrl/user';
  
  // ✅ Para producción, solo cambiar esta línea:
  // static const String baseUrl = 'https://tu-dominio.com/api';
  
  // ✅ Método helper para debugging
  static void printCurrentConfig() {
    print('🔗 API Base URL: $baseUrl');
    print('🔐 Auth URL: $authUrl');
    print('🏘️ Comunidades URL: $comunidadesUrl');
  }
}