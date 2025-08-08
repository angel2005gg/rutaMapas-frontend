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
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    
    // ✅ CONFIGURAR ANIMACIONES
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  // ✅ ABRIR/CERRAR ADVERTENCIA
  void _toggleWarning() {
    if (_isExpanded) {
      _closeWarning();
    } else {
      _openWarning();
    }
  }

  // ✅ ABRIR ADVERTENCIA
  void _openWarning() {
    setState(() {
      _isExpanded = true;
    });
    
    _animationController.forward();
    
    // ✅ AUTO CERRAR DESPUÉS DE 10 SEGUNDOS
    _autoCloseTimer = Timer(const Duration(seconds: 10), () {
      if (_isExpanded) {
        _closeWarning();
      }
    });
    
    // ✅ CALLBACK: Marcar que se leyó la advertencia
    widget.onWarningRead?.call();
    
    print('⚠️ Advertencia de seguridad mostrada');
  }

  // ✅ CERRAR ADVERTENCIA
  void _closeWarning() {
    _autoCloseTimer?.cancel();
    _animationController.reverse();
    
    Timer(const Duration(milliseconds: 400), () {
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
        // ✅ BOTÓN PRINCIPAL (siempre visible)
        GestureDetector(
          onTap: _toggleWarning,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.orange[600],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.warning,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),

        // ✅ PANEL DESLIZANTE (solo cuando está expandido)
        if (_isExpanded)
          Positioned(
            left: 60, // ✅ Sale desde el lado derecho del botón
            top: -20,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    -50 * (1 - _slideAnimation.value), // ✅ Deslizar desde la derecha
                    0,
                  ),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _slideAnimation.value,
                      alignment: Alignment.centerLeft,
                      child: _buildWarningPanel(),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ✅ PANEL DE ADVERTENCIA
  Widget _buildWarningPanel() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.orange[300]!,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ HEADER
          Row(
            children: [
              Icon(
                Icons.security,
                color: Colors.orange[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ SEGURIDAD VIAL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ),
              // ✅ BOTÓN CERRAR
              GestureDetector(
                onTap: _closeWarning,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // ✅ MENSAJE PRINCIPAL
          Text(
            'Durante la navegación:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // ✅ REGLAS
          _buildRule(
            icon: Icons.phone_android,
            text: 'NO salgas de la aplicación',
            color: Colors.red[600]!,
          ),
          
          _buildRule(
            icon: Icons.phone_callback,
            text: 'NO contestes llamadas',
            color: Colors.red[600]!,
          ),
          
          _buildRule(
            icon: Icons.apps,
            text: 'NO uses otras aplicaciones',
            color: Colors.red[600]!,
          ),
          
          const SizedBox(height: 12),
          
          // ✅ CONSECUENCIAS
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.remove_circle,
                  color: Colors.red[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Salir de la app restará puntos a tu comunidad',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // ✅ BENEFICIOS
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle,
                  color: Colors.green[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Completar la ruta te dará puntos bonus',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // ✅ CONTADOR DE AUTO-CIERRE
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Center(
                child: Text(
                  'Se cerrará automáticamente en 10s',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ✅ WIDGET PARA CADA REGLA
  Widget _buildRule({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}