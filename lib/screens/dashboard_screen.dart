import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_widget.dart';
import '../screens/maps_screen.dart';
import '../screens/community_screen.dart';
import '../screens/profile_screen.dart';
import 'tutorial/app_tutorial_flow.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<State> _communityKey = GlobalKey<State>();

  bool _tutorialChecked = false; // ✅ evitar múltiples lanzamientos

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTutorial());
  }

  Future<void> _maybeShowTutorial() async {
    if (_tutorialChecked) return;
    _tutorialChecked = true;
    final seen = await AppTutorialFlow.hasSeen();
    if (!mounted || seen) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AppTutorialFlow(),
        fullscreenDialog: true,
      ),
    );
  }

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