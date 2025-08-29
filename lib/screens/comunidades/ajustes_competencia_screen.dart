import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/comunidad_service.dart';

class AjustesCompetenciaScreen extends StatefulWidget {
  final int comunidadId;
  final int duracionInicial; // sugerida para el form
  const AjustesCompetenciaScreen({
    Key? key,
    required this.comunidadId,
    this.duracionInicial = 7,
  }) : super(key: key);

  @override
  State<AjustesCompetenciaScreen> createState() => _AjustesCompetenciaScreenState();
}

class _AjustesCompetenciaScreenState extends State<AjustesCompetenciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diasController = TextEditingController();
  final ComunidadService _service = ComunidadService();
  bool _isSaving = false;

  // Estado para mostrar info de competencia actual
  bool _cargandoInfo = false;
  int _rankingDuracionDias = 7;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  DateTime? _serverTimeRef;
  Duration _serverDelta = Duration.zero;
  String _countdownText = '';
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _diasController.text = widget.duracionInicial.toString();
    _rankingDuracionDias = widget.duracionInicial;
    _cargarInfoCompetencia();
  }

  @override
  void dispose() {
    _diasController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // Utilidad simple para formatear fecha
  String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  Future<void> _cargarInfoCompetencia() async {
    setState(() => _cargandoInfo = true);
    try {
      final res = await _service.getRankingActual(
        comunidadId: widget.comunidadId,
        duracionDias: _rankingDuracionDias,
      );
      if (!mounted) return;
      if (res['status'] == 'success') {
        final comp = res['competencia'] as Map<String, dynamic>?;
        final serverTimeStr = res['server_time']?.toString();
        DateTime? serverTime;
        if (serverTimeStr != null) serverTime = DateTime.tryParse(serverTimeStr);

        DateTime? inicio;
        DateTime? fin;
        if (comp != null) {
          if (comp['fecha_inicio'] != null) {
            inicio = DateTime.tryParse('${comp['fecha_inicio']}');
          }
          if (comp['fecha_fin'] != null) {
            fin = DateTime.tryParse('${comp['fecha_fin']}');
          }
        }
        setState(() {
          _fechaInicio = inicio;
          _fechaFin = fin;
          _serverTimeRef = serverTime;
          _recalcularDeltaServidor();
        });
        _iniciarCountdown();
      }
    } catch (_) {
      // Silencioso: no bloquear ajustes
    } finally {
      if (mounted) setState(() => _cargandoInfo = false);
    }
  }

  void _recalcularDeltaServidor() {
    if (_serverTimeRef == null) {
      _serverDelta = Duration.zero;
      return;
    }
    final now = DateTime.now();
    _serverDelta = _serverTimeRef!.difference(now);
  }

  void _iniciarCountdown() {
    _countdownTimer?.cancel();
    if (_fechaFin == null) {
      setState(() => _countdownText = '');
      return;
    }
    _actualizarCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _actualizarCountdown());
  }

  void _actualizarCountdown() {
    if (_fechaFin == null) return;
    final now = DateTime.now().add(_serverDelta);
    final remaining = _fechaFin!.difference(now);
    if (remaining.inSeconds <= 0) {
      _countdownTimer?.cancel();
      setState(() => _countdownText = 'Finalizada');
      return;
    }
    final d = remaining.inDays;
    final h = remaining.inHours % 24;
    final m = remaining.inMinutes % 60;
    String txt;
    if (d > 0) {
      txt = 'Quedan ${d}d ${h}h';
    } else if (h > 0) {
      txt = 'Quedan ${h}h ${m}m';
    } else {
      txt = 'Quedan ${m}m';
    }
    setState(() => _countdownText = txt);
  }

  bool _shouldFallbackToConfigurar(Map<String, dynamic> res) {
    final code = (res['code'] ?? '').toString().toUpperCase();
    final msg = (res['message'] ?? '').toString().toLowerCase();
    return code == 'NO_ACTIVE_COMPETITION' ||
        msg.contains('no hay competencia') ||
        msg.contains('no existe competencia') ||
        msg.contains('sin competencia');
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    // Confirmación antes de aplicar
    final int dias = int.parse(_diasController.text.trim());
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar cambios'),
        content: Text('¿Aplicar duración de competencia a $dias día(s) para esta comunidad?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    setState(() => _isSaving = true);
    try {
      // Intentar primero EDITAR (PATCH).
      final patchRes = await _service.editarCompetenciaActiva(
        comunidadId: widget.comunidadId,
        duracionDias: dias,
      );

      Map<String, dynamic> finalRes = patchRes;
      bool ok = patchRes['status'] == 'success';

      // Fallback seguro SOLO si el backend indica que no hay competencia activa
      if (!ok && _shouldFallbackToConfigurar(patchRes)) {
        final postRes = await _service.configurarPeriodo(
          comunidadId: widget.comunidadId,
          duracionDias: dias,
        );
        finalRes = postRes;
        ok = postRes['status'] == 'success';
      }

      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (finalRes['message'] ?? 'Periodo de competencia actualizado').toString(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // avisar para refrescar
      } else {
        final msg = (finalRes['message'] ?? 'No se pudo guardar los cambios').toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _acabarCompetenciaAhora() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Acabar competencia'),
        content: const Text('Se acabará la competencia y el primer puesto quedará como ganador actual. ¿Confirmas?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Acabar ahora')),
        ],
      ),
    );
    if (confirmado != true) return;

    setState(() => _isSaving = true);
    try {
      final res = await _service.cerrarCompetencia(comunidadId: widget.comunidadId);
      if (!mounted) return;
      if (res['status'] == 'success') {
        // Extraer ganador
        final comp = res['competencia'] as Map<String, dynamic>?;
        final Map<String, dynamic>? ganador = (comp != null ? comp['ganador'] : null) as Map<String, dynamic>?;
        final dynamic nombreRaw = ganador != null ? ganador['nombre'] : null;
        final String nombre = (nombreRaw == null || nombreRaw.toString().trim().isEmpty)
            ? 'Usuario ganador'
            : nombreRaw.toString();
        final dynamic puntajeRaw = ganador != null ? ganador['puntaje'] : null;
        final int puntos = (puntajeRaw is int)
            ? puntajeRaw
            : int.tryParse(puntajeRaw?.toString() ?? '') ?? 0;

        // Mostrar overlay local
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Card principal estilizada
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFFFFF), Color(0xFFF6F9FF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE6ECF5)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '¡Tenemos ganador!',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          nombre,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '$puntos pts',
                                style: const TextStyle(
                                  color: Color(0xFF1565C0),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Medalla/copa flotante con brillo
                  Positioned(
                    top: -34,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.55),
                              blurRadius: 22,
                              spreadRadius: 2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFFFE082), width: 2),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );

        // Avisar éxito y cerrar pantalla retornando true
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Competencia cerrada con éxito'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        final msg = (res['message'] ?? 'No se pudo cerrar la competencia').toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes de competencia'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarjeta de información de competencia actual
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _cargandoInfo
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Encabezado: icono + título
                              Row(
                                children: [
                                  const Icon(Icons.flag_circle, color: Color(0xFF1565C0)),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Competencia actual',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Burbuja del contador: ícono + texto juntos en un solo contenedor
                              if (_countdownText.isNotEmpty)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1565C0).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.timer, size: 14, color: Color(0xFF1565C0)),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _countdownText,
                                            style: const TextStyle(
                                              color: Color(0xFF1565C0),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            softWrap: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              if (_fechaInicio != null)
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                                    const SizedBox(width: 8),
                                    Text('Inicio: ${_fmt(_fechaInicio!.toLocal())}'),
                                  ],
                                )
                              else
                                const Text('No hay competencia activa ahora mismo'),
                              const SizedBox(height: 6),
                              if (_fechaFin != null)
                                Row(
                                  children: [
                                    const Icon(Icons.event, size: 16, color: Colors.black54),
                                    const SizedBox(width: 8),
                                    Text('Finaliza: ${_fmt(_fechaFin!.toLocal())}'),
                                  ],
                                ),
                              if (_fechaFin != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'La competencia acaba el ${_fmt(_fechaFin!.toLocal())}. Revisa al ganador en el historial.',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              // ✅ Botón para cerrar competencia ahora
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: OutlinedButton.icon(
                                  onPressed: _isSaving ? null : _acabarCompetenciaAhora,
                                  icon: const Icon(Icons.stop_circle, color: Colors.red),
                                  label: const Text('Acabar competencia ahora'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Duración (días)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _diasController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Entre 1 y 365',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    final n = int.tryParse(v.trim());
                    if (n == null) return 'Debe ser un número';
                    if (n < 1 || n > 365) return 'Debe estar entre 1 y 365';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _guardar,
                    icon: const Icon(Icons.save),
                    label: Text(_isSaving ? 'Guardando...' : 'Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nota: Solo el creador puede cambiar el periodo. Si no hay una competencia activa, se iniciará con la duración indicada.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
