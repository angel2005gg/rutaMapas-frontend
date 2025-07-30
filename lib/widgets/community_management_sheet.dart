import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/comunidad_service.dart';

class CommunityManagementSheet extends StatelessWidget {
  final List<Map<String, dynamic>> misComunidades;
  final Map<String, dynamic> comunidadActual;
  final VoidCallback onComunidadUpdated; // Para recargar después de cambios

  const CommunityManagementSheet({
    Key? key,
    required this.misComunidades,
    required this.comunidadActual,
    required this.onComunidadUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador visual
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          const Text(
            'Gestionar Comunidades',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 24),
          
          // ✅ CREAR NUEVA COMUNIDAD
          _buildMenuItem(
            context,
            icon: Icons.add_circle_outline,
            iconColor: const Color(0xFF1565C0),
            backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
            title: 'Crear Nueva Comunidad',
            subtitle: 'Inicia tu propia comunidad',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/crear-comunidad').then((_) {
                onComunidadUpdated();
              });
            },
          ),
          
          // ✅ UNIRSE A COMUNIDAD
          _buildMenuItem(
            context,
            icon: Icons.group_add,
            iconColor: Colors.green,
            backgroundColor: Colors.green.withOpacity(0.1),
            title: 'Unirse a Comunidad',
            subtitle: 'Únete con un código de invitación',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/unirse-comunidad').then((_) {
                onComunidadUpdated();
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // ✅ ELIMINAR/SALIR según sea admin o miembro (SIN CAMBIOS)
          if (comunidadActual['es_creador'] == true)
            _buildMenuItem(
              context,
              icon: Icons.delete_forever,
              iconColor: Colors.red,
              backgroundColor: Colors.red.withOpacity(0.1),
              title: 'Eliminar Comunidad',
              subtitle: 'Eliminar permanentemente',
              onTap: () {
                Navigator.pop(context);
                _eliminarComunidad(context);
              },
            )
          else
            _buildMenuItem(
              context,
              icon: Icons.exit_to_app,
              iconColor: Colors.orange,
              backgroundColor: Colors.orange.withOpacity(0.1),
              title: 'Salir de Comunidad',
              subtitle: 'Abandonar esta comunidad',
              onTap: () {
                Navigator.pop(context);
                _salirDeComunidad(context);
              },
            ),
        
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ✅ Widget helper para crear cada ítem del menú
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  // ✅ NUEVO: Eliminar comunidad (solo admin)
  Future<void> _eliminarComunidad(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Eliminar'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro que deseas eliminar "${comunidadActual['nombre']}"?',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ ESTA ACCIÓN NO SE PUEDE DESHACER:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  SizedBox(height: 8),
                  Text('• Se eliminará permanentemente la comunidad'),
                  Text('• Todos los miembros serán expulsados'),
                  Text('• Se perderán todos los datos y rankings'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmarEliminacion(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminacion(BuildContext context) async {
    try {
      // ✅ LLAMADA REAL AL BACKEND
      final result = await ComunidadService().eliminarComunidad(comunidadActual['id']);
      
      if (context.mounted) {
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Comunidad eliminada exitosamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2), // ✅ Reducir tiempo
            ),
          );
          
          // ✅ FORZAR REFRESH INMEDIATO Y COMPLETO
          onComunidadUpdated(); // Recargar lista de comunidades
          
          // ✅ ESPERAR UN MOMENTO Y FORZAR REBUILD COMPLETO
          await Future.delayed(const Duration(milliseconds: 300));
          
          // ✅ FORZAR REFRESH DE TODA LA PANTALLA
          if (context.mounted) {
            // Esto forzará que CommunityScreen se reconstruya completamente
            final navigator = Navigator.of(context);
            
            // Cerrar cualquier dialog/modal abierto
            navigator.popUntil((route) => route.isFirst);
            
            // Forzar refresh navegando y volviendo (truco para forzar rebuild)
            await navigator.pushReplacementNamed('/dashboard');
          }
          
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al eliminar la comunidad'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ✅ NUEVO: Salir de comunidad (solo miembros)
  Future<void> _salirDeComunidad(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.orange, size: 25),
            SizedBox(width: 8),
            // ✅ ARREGLO: Usar Expanded para evitar overflow
            Expanded(
              child: Text(
                'Salir de Comunidad',
                style: TextStyle(
                  fontSize: 18, // ✅ Reducir tamaño
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis, // ✅ Por si acaso
                maxLines: 1, // ✅ Solo 1 línea
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro que deseas salir de "${comunidadActual['nombre']}"?\n\nPodrás volver a unirte más tarde con el código de invitación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmarSalida(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('SALIR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ CAMBIAR SOLO el método _confirmarSalida() por esta versión que FUERZA REFRESH:
  Future<void> _confirmarSalida(BuildContext context) async {
    try {
      final result = await ComunidadService().salirDeComunidad(comunidadActual['id']);
      
      if (context.mounted) {
        if (result['status'] == 'success') {
          // ✅ MOSTRAR SUCCESS INMEDIATAMENTE
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Has salido de la comunidad'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
          
          // ✅ ESPERAR UN MOMENTO Y FORZAR NAVEGACIÓN COMPLETA
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (context.mounted) {
            // ✅ FUERZA REFRESH COMPLETO navegando al dashboard nuevamente
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/dashboard',
              (route) => false, // ✅ Eliminar TODAS las rutas anteriores
            );
          }
          
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al salir de la comunidad'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}