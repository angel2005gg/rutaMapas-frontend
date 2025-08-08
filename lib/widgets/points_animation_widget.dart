import 'package:flutter/material.dart';
import 'dart:async';

class PointsAnimationWidget extends StatefulWidget {
  final int puntos;
  final bool esPositivo;
  final String? motivo;
  final VoidCallback? onAnimationComplete;

  const PointsAnimationWidget({
    Key? key,
    required this.puntos,
    required this.esPositivo,
    this.motivo,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  State<PointsAnimationWidget> createState() => _PointsAnimationWidgetState();
}

class _PointsAnimationWidgetState extends State<PointsAnimationWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // ✅ ANIMACIÓN DE DESLIZAMIENTO
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // ✅ ANIMACIÓN DE FADE OUT
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Desde abajo
      end: const Offset(0, -0.5), // Hacia arriba
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _startAnimation();
  }

  void _startAnimation() async {
    // ✅ ANIMACIÓN DE ENTRADA
    await _slideController.forward();
    
    // ✅ ESPERAR UN MOMENTO
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // ✅ ANIMACIÓN DE SALIDA
    await _fadeController.forward();
    
    // ✅ CALLBACK DE COMPLETADO
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideController, _fadeController]),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.esPositivo 
                      ? Colors.green.withOpacity(0.9)
                      : Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.esPositivo ? Colors.green : Colors.red)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.esPositivo ? Icons.add_circle : Icons.remove_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.esPositivo ? '+' : ''}${widget.puntos} pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.motivo != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '• ${widget.motivo}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}