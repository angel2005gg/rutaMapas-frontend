class UserModel {
  final int id;
  final String nombre;
  final String correo;
  final String? fotoPerfil; // ✅ Ya es nullable
  final String? googleUid; // ➕ NUEVO: Agregar google_uid nullable
  final int rachaActual;
  final int clasificacionId;

  UserModel({
    required this.id,
    required this.nombre,
    required this.correo,
    this.fotoPerfil, // ✅ Puede ser null
    this.googleUid,  // ➕ NUEVO: Puede ser null
    required this.rachaActual,
    required this.clasificacionId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // El JSON viene con estructura {"status": "success", "user": {...}}
    final userData = json['user'] ?? json;
    
    return UserModel(
      id: userData['id'],
      nombre: userData['nombre'] ?? 'Usuario', // Por si viene null
      correo: userData['correo'],
      fotoPerfil: userData['foto_perfil'], // Puede ser null
      googleUid: userData['google_uid'],   // ➕ NUEVO: Puede ser null
      rachaActual: userData['racha_actual'] ?? 0,
      clasificacionId: userData['clasificacion_id'] ?? 0,
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