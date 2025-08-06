import 'package:flutter/material.dart';

class RouteTimeBubble extends StatelessWidget {
  final String tiempo;
  final String distancia;
  final bool esRutaPrincipal;
  final bool esMasRapida;
  final VoidCallback? onTap;
  final bool showPointer;
  final Alignment pointerAlignment;

  const RouteTimeBubble({
    Key? key,
    required this.tiempo,
    required this.distancia,
    this.esRutaPrincipal = true,
    this.esMasRapida = false,
    this.onTap,
    this.showPointer = true,
    this.pointerAlignment = Alignment.bottomCenter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: BubblePainter(
          color: esRutaPrincipal ? const Color(0xFF1565C0) : Colors.white,
          borderColor: esRutaPrincipal ? Colors.transparent : Colors.grey[300]!,
          showPointer: showPointer,
          pointerAlignment: pointerAlignment,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            12, 
            8, 
            12, 
            showPointer ? 16 : 8, // ✅ Más padding abajo si hay pointer
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ RAYITO para la ruta más rápida
              if (esMasRapida && !esRutaPrincipal) ...[
                Icon(
                  Icons.flash_on,
                  size: 14,
                  color: Colors.orange[600],
                ),
                const SizedBox(width: 4),
              ],
              
              // ✅ TIEMPO PRINCIPAL
              Text(
                tiempo,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: esRutaPrincipal ? Colors.white : const Color(0xFF1565C0),
                ),
              ),
              
              // ✅ SEPARADOR Y DISTANCIA
              if (esRutaPrincipal) ...[
                const SizedBox(width: 6),
                Container(
                  width: 1,
                  height: 10,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  distancia,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ NUEVO: Painter personalizado para crear globos con pointer
class BubblePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool showPointer;
  final Alignment pointerAlignment;

  BubblePainter({
    required this.color,
    required this.borderColor,
    this.showPointer = true,
    this.pointerAlignment = Alignment.bottomCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const radius = 8.0;
    const pointerHeight = 8.0; // ✅ Hacer pointer más visible
    const pointerWidth = 12.0;  // ✅ Hacer pointer más ancho

    final bubbleHeight = showPointer ? size.height - pointerHeight : size.height;
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, bubbleHeight),
      const Radius.circular(radius),
    );

    // ✅ DIBUJAR BURBUJA PRINCIPAL
    canvas.drawRRect(bubbleRect, paint);
    if (borderColor != Colors.transparent) {
      canvas.drawRRect(bubbleRect, borderPaint);
    }

    // ✅ DIBUJAR POINTER EN ESQUINA (no en el centro)
    if (showPointer) {
      final path = Path();
      
      // ✅ CAMBIO PRINCIPAL: Mover pointer a esquina izquierda
      double pointerX;
      if (pointerAlignment == Alignment.bottomLeft) {
        pointerX = size.width * 0.15; // ✅ Esquina izquierda (15% del ancho)
      } else if (pointerAlignment == Alignment.bottomRight) {
        pointerX = size.width * 0.85; // ✅ Esquina derecha (85% del ancho)
      } else {
        pointerX = size.width * 0.25; // ✅ Por defecto, más hacia la izquierda
      }

      // ✅ Crear triángulo pointer más definido
      path.moveTo(pointerX - pointerWidth / 2, bubbleHeight);
      path.lineTo(pointerX, size.height);
      path.lineTo(pointerX + pointerWidth / 2, bubbleHeight);
      path.close();

      canvas.drawPath(path, paint);
      if (borderColor != Colors.transparent) {
        canvas.drawPath(path, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}