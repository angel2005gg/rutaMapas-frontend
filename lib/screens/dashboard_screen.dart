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

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // ✅ Si cambió a la pestaña de comunidad, forzar recarga
    if (index == 1) {
      // Forzar rebuild de CommunityScreen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {}); // Esto hará que se reconstruya CommunityScreen
        }
      });
    }
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