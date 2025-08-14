import 'package:flutter/material.dart';
import 'route_points_history_widget.dart';

class RoutePointsSummarySheet extends StatelessWidget {
  final List<RoutePointEvent> events;
  final bool esFinal;

  const RoutePointsSummarySheet({
    Key? key,
    required this.events,
    this.esFinal = false,
  }) : super(key: key);

  int get _totalNet => events.fold(0, (a, e) => a + e.puntos);

  @override
  Widget build(BuildContext context) {
    final total = _totalNet;
    final positivo = total >= 0;
    final color = positivo ? Colors.green : Colors.red;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(esFinal ? Icons.emoji_events : Icons.history, color: const Color(0xFF1565C0)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    esFinal ? '¡Felicidades! Puntuación final' : 'Historial de puntos',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Total del trayecto: ',
                  style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${positivo ? '+' : '-'}${total.abs()} pts',
                  style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: events.isEmpty
                  ? _EmptyFinal(esFinal: esFinal)
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final e = events[index];
                        final p = e.puntos;
                        final pos = p >= 0;
                        final c = pos ? Colors.green : Colors.red;
                        final s = pos ? '+' : '-';
                        final h = _fmtHora(e.timestamp);
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: c.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: c.withOpacity(0.3)),
                              ),
                              child: Icon(pos ? Icons.add : Icons.remove, size: 18, color: c),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$s${p.abs()} pts',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    e.motivo,
                                    style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.7)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(h, style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.5))),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            if (esFinal)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Entendido'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtHora(DateTime ts) {
    final hh = ts.hour.toString().padLeft(2, '0');
    final mm = ts.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _EmptyFinal extends StatelessWidget {
  final bool esFinal;
  const _EmptyFinal({required this.esFinal});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      alignment: Alignment.center,
      child: Text(
        esFinal ? 'No hubo eventos de puntos' : 'Sin eventos aún',
        style: TextStyle(color: Colors.black.withOpacity(0.5), fontStyle: FontStyle.italic),
      ),
    );
  }
}
