import 'package:flutter/material.dart';
import 'dart:async';

class SafetyWarningWidget extends StatefulWidget {
  final VoidCallback? onWarningRead;
  
  const SafetyWarningWidget({
    Key? key,
    this.onWarningRead,
  }) : super(key: key);

  @override
  State<SafetyWarningWidget> createState() => _SafetyWarningWidgetState();
}

class _SafetyWarningWidgetState extends State<SafetyWarningWidget>
    with SingleTickerProviderStateMixin {
  
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation; // ✅ SOLO UNA ANIMACIÓN
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    
    // ✅ SOLO UNA ANIMACIÓN SIMPLE para mejor rendimiento
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250), // ✅ MÁS RÁPIDO
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut, // ✅ CURVA MÁS SIMPLE
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _toggleWarning() {
    if (_isExpanded) {
      _closeWarning();
    } else {
      _openWarning();
    }
  }

  void _openWarning() {
    setState(() {
      _isExpanded = true;
    });
    
    _animationController.forward();
    
    // ✅ AUTO CERRAR DESPUÉS DE 8 SEGUNDOS (menos tiempo)
    _autoCloseTimer = Timer(const Duration(seconds: 8), () {
      if (_isExpanded) {
        _closeWarning();
      }
    });
    
    widget.onWarningRead?.call();
    print('⚠️ Advertencia de seguridad mostrada');
  }

  void _closeWarning() {
    _autoCloseTimer?.cancel();
    _animationController.reverse();
    
    // ✅ DELAY MÁS CORTO
    Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _isExpanded = false;
        });
      }
    });
    
    print('✅ Advertencia de seguridad cerrada');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ✅ BOTÓN PRINCIPAL OPTIMIZADO
        GestureDetector(
          onTap: _toggleWarning,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.orange[600],
              shape: BoxShape.circle,
              // ✅ SHADOW MÁS SIMPLE
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.warning,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),

        // ✅ PANEL OPTIMIZADO (sin animaciones complejas)
        if (_isExpanded)
          Positioned(
            left: 60,
            top: -20,
            child: FadeTransition( // ✅ SOLO FADE, SIN SLIDE NI SCALE
              opacity: _fadeAnimation,
              child: _buildWarningPanel(),
            ),
          ),
      ],
    );
  }

  // ✅ PANEL OPTIMIZADO CON MENOS ELEMENTOS
  Widget _buildWarningPanel() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // ✅ MENOS REDONDEADO
        // ✅ SHADOW MÁS SIMPLE
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.orange[300]!,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ HEADER SIMPLIFICADO
          Row(
            children: [
              Icon(
                Icons.security,
                color: Colors.orange[600],
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '⚠️ SEGURIDAD VIAL',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              // ✅ BOTÓN CERRAR SIMPLE
              GestureDetector(
                onTap: _closeWarning,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // ✅ MENSAJE DIRECTO Y SIMPLE
          const Text(
            'Durante la navegación:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // ✅ REGLAS SIMPLIFICADAS (sin iconos complejos)
          _buildSimpleRule('• NO salgas de la aplicación'),
          _buildSimpleRule('• NO contestes llamadas'),
          _buildSimpleRule('• NO uses otras aplicaciones'),
          
          const SizedBox(height: 10),
          
          // ✅ MENSAJE FINAL SIMPLE
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.remove_circle,
                  color: Colors.red[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Salir restará puntos',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 6),
          
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle,
                  color: Colors.green[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Completar dará puntos bonus',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // ✅ CONTADOR SIMPLE
          Center(
            child: Text(
              'Se cerrará automáticamente',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ WIDGET SIMPLE PARA REGLAS (sin iconos complejos)
  Widget _buildSimpleRule(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}