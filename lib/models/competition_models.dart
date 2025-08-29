class Competition {
  final int id;
  final int comunidadId;
  final int duracionDias;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String estado; // activo / cerrado
  final int? creadaPor;
  final int? ganadorUsuarioId;
  final String? ganadorNombre;
  final int? puntajeGanador;

  Competition({
    required this.id,
    required this.comunidadId,
    required this.duracionDias,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    this.creadaPor,
    this.ganadorUsuarioId,
    this.ganadorNombre,
    this.puntajeGanador,
  });

  factory Competition.fromJson(Map<String, dynamic> json) {
    return Competition(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      comunidadId: json['comunidad_id'] is int
          ? json['comunidad_id']
          : int.tryParse('${json['comunidad_id']}') ?? 0,
      duracionDias: json['duracion_dias'] is int
          ? json['duracion_dias']
          : int.tryParse('${json['duracion_dias']}') ?? 7,
      fechaInicio: json['fecha_inicio'] != null && json['fecha_inicio'].toString().isNotEmpty
          ? DateTime.tryParse(json['fecha_inicio'].toString())
          : null,
      fechaFin: json['fecha_fin'] != null && json['fecha_fin'].toString().isNotEmpty
          ? DateTime.tryParse(json['fecha_fin'].toString())
          : null,
      estado: (json['estado'] ?? 'activo').toString(),
      creadaPor: json['creada_por'] == null
          ? null
          : (json['creada_por'] is int
              ? json['creada_por']
              : int.tryParse('${json['creada_por']}')),
      ganadorUsuarioId: json['ganador_usuario_id'] == null
          ? null
          : (json['ganador_usuario_id'] is int
              ? json['ganador_usuario_id']
              : int.tryParse('${json['ganador_usuario_id']}')),
      ganadorNombre: json['ganador_nombre']?.toString(),
      puntajeGanador: json['puntaje_ganador'] is int
          ? json['puntaje_ganador']
          : int.tryParse('${json['puntaje_ganador']}'),
    );
  }
}

class RankingItem {
  final int usuarioId;
  final String nombre;
  final int puntos;
  final int? posicion; // opcional si backend la envía
  final int? rachaActual; // si backend la envía

  RankingItem({
    required this.usuarioId,
    required this.nombre,
    required this.puntos,
    this.posicion,
    this.rachaActual,
  });

  factory RankingItem.fromJson(Map<String, dynamic> json) {
    return RankingItem(
      usuarioId: json['usuario_id'] is int
          ? json['usuario_id']
          : int.tryParse('${json['usuario_id']}') ?? 0,
      nombre: (json['nombre'] ?? 'Usuario').toString(),
      puntos: json['puntos'] is int
          ? json['puntos']
          : int.tryParse('${json['puntos']}') ?? 0,
      posicion: json['posicion'] is int ? json['posicion'] : int.tryParse('${json['posicion']}'),
      rachaActual: json['racha_actual'] is int ? json['racha_actual'] : int.tryParse('${json['racha_actual']}'),
    );
  }
}

class CompetitionHistoryPage {
  final int currentPage;
  final int perPage;
  final int total;
  final List<Competition> data;

  CompetitionHistoryPage({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.data,
  });

  factory CompetitionHistoryPage.fromJson(Map<String, dynamic> json) {
    final d = json['data'];
    final list = (d is Map<String, dynamic> ? (d['data'] as List?) : (json['data'] as List?)) ?? [];
    return CompetitionHistoryPage(
      currentPage: d is Map<String, dynamic>
          ? (d['current_page'] is int ? d['current_page'] : int.tryParse('${d['current_page']}') ?? 1)
          : 1,
      perPage: d is Map<String, dynamic>
          ? (d['per_page'] is int ? d['per_page'] : int.tryParse('${d['per_page']}') ?? 10)
          : 10,
      total: d is Map<String, dynamic>
          ? (d['total'] is int ? d['total'] : int.tryParse('${d['total']}') ?? list.length)
          : list.length,
      data: list.map((e) => Competition.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
