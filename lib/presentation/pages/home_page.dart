import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_navigation.dart';
import 'tickets_page.dart';
import 'search_page.dart';
import 'profile_page.dart';
import 'auth_page.dart';

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
    Container(), // Page de scan temporairement vide
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    
    // Écouter les changements d'authentification
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.session == null && mounted) {
        // Rediriger vers la page d'authentification si déconnecté
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthPage()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}