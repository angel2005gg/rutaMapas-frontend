class UserModel {
  final int id;
  final String nombre;
  final String correo;
  final String? fotoPerfil; // ✅ Ya es nullable
  final String? googleUid; // ➕ NUEVO: Agregar google_uid nullable
  final int rachaActual;
  final int clasificacionId;
  final int puntosTotales; // ➕ NUEVO: puntos totales del usuario

  UserModel({
    required this.id,
    required this.nombre,
    required this.correo,
    this.fotoPerfil, // ✅ Puede ser null
    this.googleUid,  // ➕ NUEVO: Puede ser null
    required this.rachaActual,
    required this.clasificacionId,
    this.puntosTotales = 0, // ➕ por defecto 0
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // El JSON viene con estructura {"status": "success", "user": {...}}
    final userData = json['user'] ?? json;
    
    // ✅ AGREGAR DEBUG ESPECÍFICO PARA RACHA
    print('🔍 UserModel.fromJson - datos recibidos:');
    print('   - userData completo: $userData');
    print('   - racha_actual raw: ${userData['racha_actual']}');
    print('   - racha_actual tipo: ${userData['racha_actual'].runtimeType}');
    
    final rachaActual = userData['racha_actual'] ?? 0;
    print('   - racha_actual procesada: $rachaActual');

    // ➕ Intentar leer puntos totales de varias posibles llaves
    final dynamic puntosRaw = userData['puntaje_actual'] ?? userData['puntos_totales'] ?? userData['puntaje'] ?? userData['puntos'];
    final int puntosTotales = puntosRaw is int ? puntosRaw : int.tryParse('${puntosRaw ?? 0}') ?? 0;
    
    return UserModel(
      id: userData['id'],
      nombre: userData['nombre'] ?? 'Usuario',
      correo: userData['correo'],
      fotoPerfil: userData['foto_perfil'],
      googleUid: userData['google_uid'],
      rachaActual: rachaActual, // ✅ Usar variable procesada
      clasificacionId: userData['clasificacion_id'] ?? 0,
      puntosTotales: puntosTotales, // ➕ NUEVO
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'foto_perfil': fotoPerfil,
      'google_uid': googleUid, // ➕ NUEVO
      'racha_actual': rachaActual,
      'clasificacion_id': clasificacionId,
      'puntaje_actual': puntosTotales, // ➕ mantener compatibilidad
    };
  }

  // ➕ NUEVO: Método para obtener iniciales del nombre
  String get iniciales {
    if (nombre.isEmpty) return 'U';
    
    final palabras = nombre.trim().split(' ');
    if (palabras.length >= 2) {
      return '${palabras[0][0]}${palabras[1][0]}'.toUpperCase();
    } else {
      return palabras[0][0].toUpperCase();
    }
  }

  // ➕ NUEVO: Verificar si tiene cuenta de Google
  bool get tieneGoogle => googleUid != null && googleUid!.isNotEmpty;
}