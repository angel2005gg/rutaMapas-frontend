import 'package:flutter/material.dart';

class RoutePointEvent {
  final int puntos;
  final String motivo;
  final DateTime timestamp;

  RoutePointEvent({
    required this.puntos,
    required this.motivo,
    required this.timestamp,
  });
}

class RoutePointsHistoryWidget extends StatelessWidget {
  final List<RoutePointEvent> events;
  final int maxItems;

  const RoutePointsHistoryWidget({
    Key? key,
    required this.events,
    this.maxItems = 6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final visible = events.isEmpty
        ? <RoutePointEvent>[]
        : (events.length > maxItems
            ? events.sublist(events.length - maxItems)
            : List<RoutePointEvent>.from(events));

    return Container(
      constraints: const BoxConstraints(maxWidth: 320, maxHeight: 220),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.history, size: 18, color: Color(0xFF1565C0)),
              SizedBox(width: 6),
              Text(
                'Historial de puntos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: visible.isEmpty
                ? const _EmptyHistory()
                : ListView.separated(
                    shrinkWrap: true,
                    reverse: true, // mostrar lo último arriba
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final i = visible.length - 1 - index; // por reverse manual
                      final e = visible[i];
                      final positivo = e.puntos >= 0;
                      final color = positivo ? Colors.green : Colors.red;
                      final signo = positivo ? '+' : '-';
                      final abs = e.puntos.abs();
                      final hora = _fmtHora(e.timestamp);
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Icon(
                              positivo ? Icons.add : Icons.remove,
                              size: 16,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$signo$abs pts',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  e.motivo,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hora,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _fmtHora(DateTime ts) {
    final hh = ts.hour.toString().padLeft(2, '0');
    final mm = ts.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        'Sin eventos aún',
        style: TextStyle(
          fontSize: 11,
          color: Colors.black.withOpacity(0.5),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
