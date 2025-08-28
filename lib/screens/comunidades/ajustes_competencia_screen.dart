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

  @override
  void initState() {
    super.initState();
    _diasController.text = widget.duracionInicial.toString();
  }

  @override
  void dispose() {
    _diasController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes de competencia'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
