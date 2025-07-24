class UserModel {
  final int id;
  final String nombre;
  final String correo;
  final String? fotoPerfil;
  final int rachaActual;
  final int? clasificacionId;

  UserModel({
    required this.id,
    required this.nombre,
    required this.correo,
    this.fotoPerfil,
    required this.rachaActual,
    this.clasificacionId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nombre: json['nombre'],
      correo: json['correo'],
      fotoPerfil: json['foto_perfil'],
      rachaActual: json['racha_actual'],
      clasificacionId: json['clasificacion_id'],
    );
  }
}