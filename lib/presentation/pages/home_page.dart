import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_navigation.dart';
import 'tickets_page.dart';
import 'search_page.dart';
import 'profile_page.dart';
import 'auth_page.dart';
import 'scan_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const TicketsPage(),
    const SearchPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.session == null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthPage()),
          (route) => false,
        );
      }
    });
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // Ouvre le scan en plein écran au lieu de changer d'onglet
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ScanPage()),
      );
    } else {
      setState(() {
        // Ajustement de l'index car on a retiré la page de scan de la liste _pages
        _currentIndex = index > 2 ? index - 1 : index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavigation(
        // On recalcule l'index pour la barre de navigation
        currentIndex: _currentIndex >= 2 ? _currentIndex + 1 : _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
