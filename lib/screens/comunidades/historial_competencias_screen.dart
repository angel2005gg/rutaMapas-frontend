import 'package:flutter/material.dart';
import '../../services/comunidad_service.dart';
import '../../models/competition_models.dart';

class HistorialCompetenciasScreen extends StatefulWidget {
  final int comunidadId;
  const HistorialCompetenciasScreen({Key? key, required this.comunidadId}) : super(key: key);

  @override
  State<HistorialCompetenciasScreen> createState() => _HistorialCompetenciasScreenState();
}

class _HistorialCompetenciasScreenState extends State<HistorialCompetenciasScreen> {
  final ComunidadService _service = ComunidadService();
  bool _isLoading = true;
  int _page = 1;
  final int _perPage = 10;
  List<Competition> _items = [];
  int _total = 0;
  final ScrollController _scroll = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadPage();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _items.length < _total) {
        _loadMore();
      }
    }
  }

  Future<void> _loadPage({int page = 1}) async {
    setState(() => _isLoading = true);
    try {
      final res = await _service.getHistorialCompetencias(
        comunidadId: widget.comunidadId,
        page: page,
        perPage: _perPage,
      );

      if (res['status'] == 'success') {
        final pageData = CompetitionHistoryPage.fromJson(res);
        setState(() {
          _page = pageData.currentPage;
          _total = pageData.total;
          _items = pageData.data;
        });
      } else {
        final msg = (res['message'] ?? 'No se pudo cargar el historial').toString();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final next = _page + 1;
      final res = await _service.getHistorialCompetencias(
        comunidadId: widget.comunidadId,
        page: next,
        perPage: _perPage,
      );
      if (res['status'] == 'success') {
        final pageData = CompetitionHistoryPage.fromJson(res);
        setState(() {
          _page = pageData.currentPage;
          _total = pageData.total;
          _items.addAll(pageData.data);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de competencias'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : RefreshIndicator(
              color: const Color(0xFF1565C0),
              onRefresh: () => _loadPage(page: 1),
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _items.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final c = _items[index];
                  final tieneGanador = (c.ganadorUsuarioId != null) || (c.ganadorNombre != null && c.ganadorNombre!.isNotEmpty);
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(
                        Icons.emoji_events,
                        color: tieneGanador ? Colors.amber : Colors.grey,
                      ),
                      title: Text('Duración: ${c.duracionDias} días • ${c.estado.toUpperCase()}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${c.fechaInicio?.toLocal().toString().substring(0, 16) ?? '-'}  →  ${c.fechaFin?.toLocal().toString().substring(0, 16) ?? '-'}',
                          ),
                          const SizedBox(height: 4),
                          if (tieneGanador)
                            Text(
                              'Ganador: ${c.ganadorNombre ?? 'Usuario #${c.ganadorUsuarioId}'} • ${c.puntajeGanador ?? 0} pts',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            )
                          else
                            const Text('Sin ganador', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
