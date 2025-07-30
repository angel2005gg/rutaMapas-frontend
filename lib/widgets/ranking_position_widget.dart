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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0),
            const Color(0xFF1976D2),
          ],
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
            child: Center(
              child: _buildPositionIcon(),
            ),
          ),
          const SizedBox(width: 12),
          
          // ✅ INFORMACIÓN DE RANKING ARREGLADA
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // ✅ IMPORTANTE: Tamaño mínimo
              children: [
                // ✅ TÍTULO DE POSICIÓN CON ALTURA FIJA
                SizedBox(
                  height: 20, // ✅ ALTURA FIJA PARA EVITAR OVERFLOW
                  child: Text(
                    _buildPositionText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15, // ✅ REDUCIR TAMAÑO
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1, // ✅ SOLO UNA LÍNEA
                    overflow: TextOverflow.ellipsis, // ✅ PUNTOS SUSPENSIVOS
                  ),
                ),
                const SizedBox(height: 2), // ✅ REDUCIR ESPACIO
                
                // ✅ INFORMACIÓN DE PUNTOS CON ALTURA FIJA
                SizedBox(
                  height: 16, // ✅ ALTURA FIJA PARA EVITAR OVERFLOW
                  child: Text(
                    '${misPuntos ?? 0} pts • ${_getTruncatedCommunityName()}', // ✅ TEXTO MÁS CORTO
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11, // ✅ REDUCIR TAMAÑO
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1, // ✅ SOLO UNA LÍNEA
                    overflow: TextOverflow.ellipsis, // ✅ PUNTOS SUSPENSIVOS
                  ),
                ),
              ],
            ),
          ),
          
          // Badge de total de miembros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$totalMiembros',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO: Método para truncar el nombre de la comunidad
  String _getTruncatedCommunityName() {
    final nombre = comunidadActual!['nombre'] ?? 'Comunidad';
    if (nombre.length <= 15) return nombre;
    return '${nombre.substring(0, 15)}...';
  }

  Widget _buildPositionIcon() {
    if (miPosicion == null) {
      return const Icon(
        Icons.help_outline,
        color: Colors.white,
        size: 18, // ✅ REDUCIR TAMAÑO
      );
    }

    // Top 3 con medallas
    if (miPosicion! <= 3) {
      return Icon(
        miPosicion == 1 ? Icons.emoji_events : Icons.military_tech,
        color: _getTopThreeColor(miPosicion!),
        size: 20, // ✅ REDUCIR TAMAÑO
      );
    }

    // Posición normal con número
    return Text(
      '$miPosicion',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14, // ✅ REDUCIR TAMAÑO
      ),
    );
  }

  String _buildPositionText() {
    if (miPosicion == null) {
      return 'Sin clasificar';
    }

    switch (miPosicion!) {
      case 1:
        return '🥇 1er lugar';
      case 2:
        return '🥈 2do lugar';
      case 3:
        return '🥉 3er lugar';
      default:
        return 'Posición #$miPosicion';
    }
  }

  Color _getTopThreeColor(int posicion) {
    switch (posicion) {
      case 1: return Colors.amber;
      case 2: return Colors.grey[300]!;
      case 3: return Colors.orange[300]!;
      default: return Colors.white;
    }
  }
}