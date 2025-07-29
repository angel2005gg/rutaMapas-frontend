import 'package:flutter/material.dart';

class CommunityDrawer extends StatelessWidget {
  final List<Map<String, dynamic>> comunidades;
  final Map<String, dynamic>? comunidadActual;
  final Function(Map<String, dynamic>) onComunidadSelected;

  const CommunityDrawer({
    Key? key,
    required this.comunidades,
    required this.comunidadActual,
    required this.onComunidadSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // ✅ ARREGLO 1: Eliminar elevation que causa lag
      elevation: 0,
      // ✅ ARREGLO 2: Fondo sólido para mejor rendimiento
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ✅ ARREGLO 3: Header más liviano sin gradiente pesado
          Container(
            height: 100, // ✅ Reducir altura
            width: double.infinity,
            decoration: const BoxDecoration(
              // ✅ Color sólido en lugar de gradiente para mejor performance
              color: Color(0xFF1565C0),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row( // ✅ USAR ROW en lugar de Column
                  children: [
                    const Icon(Icons.groups, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded( // ✅ Texto expandido
                      child: Text(
                        'Mis Comunidades', // ✅ SIN LA P
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // ✅ ARREGLO 4: ListView optimizado con mejor rendimiento
          Expanded(
            child: comunidades.isEmpty 
                ? _buildEmptyState() 
                : _buildCommunityList(),
          ),
        ],
      ),
    );
  }

  // ✅ ARREGLO 5: Estado vacío optimizado
  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No tienes comunidades',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ARREGLO 6: Lista optimizada con mejor rendimiento
  Widget _buildCommunityList() {
    return ListView.builder(
      // ✅ OPTIMIZACIONES CLAVE para fluidez:
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      physics: const BouncingScrollPhysics(), // ✅ Scroll más suave
      itemCount: comunidades.length,
      // ✅ Añadir cache para mejor rendimiento
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      itemBuilder: (context, index) {
        final comunidad = comunidades[index];
        final isSelected = comunidad['id'] == comunidadActual?['id'];
        
        return _buildCommunityCard(comunidad, isSelected);
      },
    );
  }

  // ✅ ARREGLO 7: Card optimizada y más fluida
  Widget _buildCommunityCard(Map<String, dynamic> comunidad, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      // ✅ Eliminar AnimatedContainer que causa lag
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? const Color(0xFF1565C0) 
              : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        // ✅ Shadow más simple para mejor rendimiento
        boxShadow: isSelected ? [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onComunidadSelected(comunidad),
          // ✅ ARREGLO 8: Padding optimizado
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // ✅ ARREGLO 9: Avatar más simple
                _buildCommunityAvatar(comunidad),
                const SizedBox(width: 12),
                // ✅ ARREGLO 10: Información optimizada
                Expanded(
                  child: _buildCommunityInfo(comunidad, isSelected),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ ARREGLO 11: Avatar optimizado
  Widget _buildCommunityAvatar(Map<String, dynamic> comunidad) {
    final isAdmin = comunidad['es_creador'] == true;
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        // ✅ Color sólido en lugar de gradient
        color: isAdmin ? const Color(0xFF1565C0) : const Color(0xFF34A853),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isAdmin ? Icons.admin_panel_settings : Icons.groups,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  // ✅ ARREGLO 12: Info optimizada sin overflow
  Widget _buildCommunityInfo(Map<String, dynamic> comunidad, bool isSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // ✅ Evitar overflow
      children: [
        // Nombre
        Text(
          comunidad['nombre'] ?? 'Sin nombre',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isSelected ? const Color(0xFF1565C0) : Colors.black87,
          ),
          maxLines: 1, // ✅ Evitar overflow
          overflow: TextOverflow.ellipsis,
        ),
        
        // Descripción (si existe)
        if (comunidad['descripcion'] != null && 
            comunidad['descripcion'].toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            comunidad['descripcion'].toString(),
            maxLines: 1, // ✅ Solo 1 línea para evitar lag
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
        
        const SizedBox(height: 6),
        
        // Badge y miembros
        Row(
          children: [
            // Badge optimizado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: comunidad['es_creador'] == true 
                    ? const Color(0xFF1565C0).withOpacity(0.1)
                    : const Color(0xFF34A853).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                comunidad['es_creador'] == true ? 'ADMIN' : 'MIEMBRO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: comunidad['es_creador'] == true 
                      ? const Color(0xFF1565C0)
                      : const Color(0xFF34A853),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Contador de miembros
            Flexible(
              child: Text(
                '${comunidad['total_miembros'] ?? 0} miembros',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}