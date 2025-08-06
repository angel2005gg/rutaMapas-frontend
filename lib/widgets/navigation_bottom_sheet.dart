import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../screens/navigation_screen.dart'; // NUEVO IMPORT PARA LA NAVEGACIÓN

class NavigationBottomSheet extends StatefulWidget {
  final String? rutaInfo;
  final String? nombreDestino;
  final LatLng? coordenadasDestino;
  final bool mostrandoRuta;
  final VoidCallback? onCerrarRuta;
  final VoidCallback? onComenzarNavegacion;

  const NavigationBottomSheet({
    Key? key,
    this.rutaInfo,
    this.nombreDestino,
    this.coordenadasDestino,
    required this.mostrandoRuta,
    this.onCerrarRuta,
    this.onComenzarNavegacion,
  }) : super(key: key);

  @override
  State<NavigationBottomSheet> createState() => _NavigationBottomSheetState();
}

class _NavigationBottomSheetState extends State<NavigationBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  
  static const double _minHeight = 50.0;
  static const double _maxHeight = 110.0;
  
  bool _isExpanded = false;
  double _currentHeight = 50.0;
  bool _isDragging = false;
  double _startDragHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _heightAnimation = Tween<double>(
      begin: _minHeight,
      end: _maxHeight,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _heightAnimation.addListener(() {
      if (!_isDragging) {
        setState(() {
          _currentHeight = _heightAnimation.value;
        });
      }
    });
  }

  @override
  void didUpdateWidget(NavigationBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.mostrandoRuta && !oldWidget.mostrandoRuta) {
      _expandir();
    }
    
    if (!widget.mostrandoRuta && oldWidget.mostrandoRuta) {
      _colapsar();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _expandir() {
    setState(() => _isExpanded = true);
    _animationController.forward();
  }

  void _colapsar() {
    setState(() => _isExpanded = false);
    _animationController.reverse();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.mostrandoRuta) return;
    
    _isDragging = true;
    _startDragHeight = _currentHeight;
    _animationController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.mostrandoRuta || !_isDragging) return;

    double deltaFromStart = -details.localPosition.dy + (_startDragHeight * 2);
    double newHeight = (_startDragHeight + deltaFromStart * 0.5).clamp(_minHeight, _maxHeight);
    
    setState(() {
      _currentHeight = newHeight;
      
      double progress = (newHeight - _minHeight) / (_maxHeight - _minHeight);
      _isExpanded = progress > 0.3;
      
      _animationController.value = progress;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.mostrandoRuta) return;
    
    _isDragging = false;
    
    double velocity = details.velocity.pixelsPerSecond.dy;
    double progress = (_currentHeight - _minHeight) / (_maxHeight - _minHeight);
    
    bool shouldExpand;
    
    if (velocity.abs() > 500) {
      shouldExpand = velocity < 0;
    } else {
      shouldExpand = progress > 0.5;
    }
    
    if (shouldExpand) {
      _expandir();
    } else {
      _colapsar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Bottom sheet con deslizamiento manual
        AnimatedBuilder(
          animation: _heightAnimation,
          builder: (context, child) {
            return Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Container(
                  height: _heightAnimation.value,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle más visible para deslizar
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        
                        // Contenido con overflow controlado
                        Flexible(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: widget.mostrandoRuta 
                                  ? _buildRutaContentMinimal()
                                  : _buildDefaultContentMinimal(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        
        // Botón flotante
        if (widget.mostrandoRuta)
          AnimatedBuilder(
            animation: _heightAnimation,
            builder: (context, child) {
              return Positioned(
                left: 0,
                right: 0,
                bottom: _heightAnimation.value + 8,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: widget.onComenzarNavegacion,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.navigation,
                                color: Colors.grey,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'INICIAR RUTA',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ✅ CONTENIDO POR DEFECTO SIMPLE
  Widget _buildDefaultContentMinimal() {
    return const Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.navigation_outlined,
            size: 16,
            color: Colors.grey,
          ),
          SizedBox(width: 6),
          Text(
            'Busca un lugar',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Contenido de ruta minimalista
  Widget _buildRutaContentMinimal() {
    final rutaParts = widget.rutaInfo?.split(' • ') ?? [];
    final distancia = rutaParts.isNotEmpty ? rutaParts[0] : 'N/A';
    final tiempo = rutaParts.length > 1 ? rutaParts[1] : 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Información básica
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.navigation,
                color: Colors.white,
                size: 12,
              ),
            ),
            const SizedBox(width: 8),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.nombreDestino ?? 'Destino',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$tiempo • $distancia',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            IconButton(
              onPressed: widget.onCerrarRuta,
              icon: const Icon(Icons.close),
              iconSize: 14,
              color: Colors.grey[600],
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
              padding: const EdgeInsets.all(2),
            ),
          ],
        ),
        
        // Contenido expandido
        if (_isExpanded) ...[
          const SizedBox(height: 6),
          Divider(height: 1, color: Colors.grey[300]),
          const SizedBox(height: 4),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniStat(Icons.directions_car, 'Auto', const Color(0xFF1565C0)),
              _buildMiniStat(Icons.schedule, tiempo, Colors.orange),
              _buildMiniStat(Icons.straighten, distancia, Colors.green),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  // Mini estadísticas
  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  // ✅ CAMBIAR ESTE MÉTODO en navigation_bottom_sheet.dart:
  void _onComenzarNavegacion() {
    if (widget.coordenadasDestino != null && widget.nombreDestino != null) {
      // Obtener puntos de ruta del widget padre
      // Por ahora usaremos una ruta simple
      final puntosRuta = [
        // Aquí deberías pasar los puntos de ruta reales desde GoogleMapWidget
        widget.coordenadasDestino!,
      ];
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NavigationScreen(
            destino: widget.coordenadasDestino!,
            nombreDestino: widget.nombreDestino!,
            puntosRuta: puntosRuta,
            rutaInfo: widget.rutaInfo ?? '',
          ),
        ),
      );
    }
  }
}