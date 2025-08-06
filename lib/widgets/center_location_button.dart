import 'package:flutter/material.dart';

class CenterLocationButton extends StatefulWidget {
  final VoidCallback onCenter;
  final bool isFollowing;

  const CenterLocationButton({
    Key? key,
    required this.onCenter,
    required this.isFollowing,
  }) : super(key: key);

  @override
  State<CenterLocationButton> createState() => _CenterLocationButtonState();
}

class _CenterLocationButtonState extends State<CenterLocationButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    if (widget.isFollowing) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(CenterLocationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isFollowing && !oldWidget.isFollowing) {
      _animationController.repeat();
    } else if (!widget.isFollowing && oldWidget.isFollowing) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ElevatedButton.icon(
        onPressed: widget.onCenter,
        icon: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: widget.isFollowing ? _animationController.value * 2 * 3.14159 : 0,
              child: Icon(
                widget.isFollowing ? Icons.gps_fixed : Icons.gps_not_fixed,
                size: 20,
                color: widget.isFollowing ? Colors.green : const Color(0xFF1565C0),
              ),
            );
          },
        ),
        label: Text(
          widget.isFollowing ? 'SIGUIENDO' : 'CENTRAR',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: widget.isFollowing ? Colors.green : const Color(0xFF1565C0),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: widget.isFollowing ? Colors.green : const Color(0xFF1565C0),
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: widget.isFollowing ? Colors.green : const Color(0xFF1565C0),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}