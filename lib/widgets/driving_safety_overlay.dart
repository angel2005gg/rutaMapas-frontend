import 'package:flutter/material.dart';

class DrivingSafetyOverlay extends StatelessWidget {
  final VoidCallback onAccept;

  const DrivingSafetyOverlay({Key? key, required this.onAccept}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black54,
        child: MediaQuery.removeViewInsets( // ✅ ignora el empuje del teclado
          removeBottom: true,
          context: context,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView( // ✅ evita overflow si no entra todo
                physics: const ClampingScrollPhysics(),
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_car, size: 48, color: Color(0xFF1565C0)),
                      const SizedBox(height: 12),
                      const Text(
                        'No uses tu teléfono mientras conduces',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Para tu seguridad durante la navegación:',
                        style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• Mantente concentrado en la vía', style: TextStyle(fontSize: 13, color: Colors.black87)),
                            SizedBox(height: 6),
                            Text('• Evita usar otras aplicaciones', style: TextStyle(fontSize: 13, color: Colors.black87)),
                            SizedBox(height: 6),
                            Text('• No contestes llamadas mientras conduces', style: TextStyle(fontSize: 13, color: Colors.black87)),
                            SizedBox(height: 6),
                            Text('• Mantén esta app en primer plano', style: TextStyle(fontSize: 13, color: Colors.black87)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.red[600], size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Usar otras apps o atender llamadas restará puntos.',
                                style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onAccept,
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('ACEPTAR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}