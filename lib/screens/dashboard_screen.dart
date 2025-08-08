import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../screens/maps_screen.dart';
import '../screens/community_screen.dart';
import '../screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  
  // ✅ Claves para forzar rebuild de las pantallas
  final GlobalKey<State> _communityKey = GlobalKey<State>();

  // Lista de pantallas para cada pestaña
  List<Widget> get _screens => [
    const MapsScreen(),
    CommunityScreen(key: _communityKey), // ✅ Con clave para forzar rebuild
    const ProfileScreen(),
  ];

  // ✅ CAMBIAR TODO EL MÉTODO _onTabTapped:
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    print('📱 Cambiando a pestaña $index');
    
    // ✅ QUITAR TODA LA LÓGICA COMPLEJA DE RECARGA
    // Solo cambiar pestaña, nada más
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}