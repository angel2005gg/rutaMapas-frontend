import 'package:flutter/material.dart';

class RankingPositionWidget extends StatelessWidget {
  final Map<String, dynamic>? comunidadActual;
  final int? miPosicion;
  final int? misPuntos;
  final int totalMiembros;

  const RankingPositionWidget({
    Key? key,
    required this.comunidadActual,
    required this.miPosicion,
    required this.misPuntos,
    required this.totalMiembros,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Si no hay comunidad, no mostrar nada
    if (comunidadActual == null) return const SizedBox.shrink();

    final calc = _calcularDesdeComunidadSiHaceFalta(
      comunidadActual: comunidadActual!,
      posicionProp: miPosicion,
      puntosProp: misPuntos,
    );
    final (posicionEfectiva, puntosEfectivos) = calc;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono de posición
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(child: _buildPositionIcon(posicionEfectiva)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 20,
                  child: Text(
                    _buildPositionText(posicionEfectiva),
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 16,
                  child: Text(
                    '${puntosEfectivos} pts • ${_getTruncatedCommunityName()}',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Text('$totalMiembros', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Devuelve (posicion, puntos) calculados desde la lista de usuarios
  (int?, int) _calcularDesdeComunidadSiHaceFalta({
    required Map<String, dynamic> comunidadActual,
    int? posicionProp,
    int? puntosProp,
  }) {
    int? pos = posicionProp;
    int pts = puntosProp ?? _toInt(comunidadActual['mis_puntos'] ?? comunidadActual['mi_puntaje'] ?? comunidadActual['puntaje_usuario_actual']);

    final usuariosRaw = comunidadActual['usuarios'];
    if (usuariosRaw is! List) return (pos, pts);

    final usuarios = List<Map<String, dynamic>>.from(usuariosRaw);

    // 1) Intentar identificar al usuario actual por flag
    Map<String, dynamic> yo = usuarios.firstWhere(
      (u) => u['es_usuario_actual'] == true || u['es_actual'] == true,
      orElse: () => <String, dynamic>{},
    );

    // 2) Si no hay flag, intentar por coincidencia con mis_puntos
    if (yo.isEmpty && pts > 0) {
      yo = usuarios.firstWhere(
        (u) => _toInt(u['puntaje'] ?? u['puntos'] ?? u['puntaje_actual']) == pts,
        orElse: () => <String, dynamic>{},
      );
    }

    // 3) Si aún no hay, calcular posición/puntos desde el TOP (orden por puntaje desc)
    final ordenados = [...usuarios]..sort(
      (a, b) => _toInt(b['puntaje'] ?? b['puntos'] ?? b['puntaje_actual']).compareTo(
        _toInt(a['puntaje'] ?? a['puntos'] ?? a['puntaje_actual']),
      ),
    );

    if (yo.isEmpty) {
      // Si no podemos identificar al usuario, usar como fallback el top y mantener pts si ya lo teníamos
      final top = ordenados.isNotEmpty ? ordenados.first : null;
      final topPts = top != null ? _toInt(top['puntaje'] ?? top['puntos'] ?? top['puntaje_actual']) : 0;
      final puntosFinales = pts > 0 ? pts : topPts;
      // La posición efectiva es 1 si usamos el top
      return (1, puntosFinales);
    }

    final yoPts = _toInt(yo['puntaje'] ?? yo['puntos'] ?? yo['puntaje_actual']);
    final yoPosBackend = _toInt(yo['posicion']);

    if (yoPosBackend > 0) {
      pos ??= yoPosBackend;
      pts = (puntosProp ?? 0) == 0 ? yoPts : pts;
      return (pos, pts);
    }

    final idx = ordenados.indexWhere((u) => identical(u, yo));
    final posCalc = idx >= 0 ? idx + 1 : null;

    pos ??= posCalc;
    pts = (puntosProp ?? 0) == 0 ? yoPts : pts;

    return (pos, pts);
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) {
      final i = int.tryParse(v);
      if (i != null) return i;
      final d = double.tryParse(v);
      if (d != null) return d.round();
      return 0;
    }
    return 0;
  }

  // ✅ Actualizar para aceptar posición efectiva
  Widget _buildPositionIcon(int? posicionEfectiva) {
    if (posicionEfectiva == null) {
      return const Icon(Icons.help_outline, color: Colors.white, size: 18);
    }

    // Top 3 con medallas
    if (posicionEfectiva <= 3) {
      return Icon(
        posicionEfectiva == 1 ? Icons.emoji_events : Icons.military_tech,
        color: _getTopThreeColor(posicionEfectiva),
        size: 20, // ✅ REDUCIR TAMAÑO
      );
    }

    // Posición normal con número
    return Text(
      '$posicionEfectiva',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14, // ✅ REDUCIR TAMAÑO
      ),
    );
  }

  // ✅ Actualizar para aceptar posición efectiva
  String _buildPositionText(int? posicionEfectiva) {
    if (posicionEfectiva == null) {
      return 'Sin clasificar';
    }

    switch (posicionEfectiva) {
      case 1:
        return '🥇 1er lugar';
      case 2:
        return '🥈 2do lugar';
      case 3:
        return '🥉 3er lugar';
      default:
        return 'Posición #$posicionEfectiva';
    }
  }

  Color _getTopThreeColor(int posicion) {
    switch (posicion) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[300]!;
      case 3:
        return Colors.orange[300]!;
      default:
        return Colors.white;
    }
  }

  // ✅ ARREGLO 2: Método faltante para el nombre de comunidad
  String _getTruncatedCommunityName() {
    final nombre = (comunidadActual?['nombre'] ?? 'Comunidad').toString();
    if (nombre.length <= 15) return nombre;
    return '${nombre.substring(0, 15)}...';
  }
}