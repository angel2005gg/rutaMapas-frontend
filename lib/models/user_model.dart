class UserModel {
  final int id;
  final String nombre;
  final String correo;
  final String? fotoPerfil;
  final int rachaActual;
  final int clasificacionId; // Cambiado: ahora siempre es int (no nullable)

  UserModel({
    required this.id,
    required this.nombre,
    required this.correo,
    this.fotoPerfil,
    required this.rachaActual,
    required this.clasificacionId, // Cambiado: ahora es required
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // El JSON viene con estructura {"status": "success", "user": {...}}
    final userData = json['user'] ?? json; // Maneja ambos casos
    
    return UserModel(
      id: userData['id'],
      nombre: userData['nombre'],
      correo: userData['correo'],
      fotoPerfil: userData['foto_perfil'],
      rachaActual: userData['racha_actual'] ?? 0,
      clasificacionId: userData['clasificacion_id'] ?? 0, // Ahora siempre será int
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'foto_perfil': fotoPerfil,
      'racha_actual': rachaActual,
      'clasificacion_id': clasificacionId,
    };
  }
}