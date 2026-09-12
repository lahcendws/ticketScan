import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_navigation.dart';
import 'tickets_page.dart';
import 'ticket_list_page.dart';
import 'profile_page.dart';
import 'auth_page.dart';
import 'alerts_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const TicketsPage(),
    const TicketListPage(),
    const AlertsPage(),
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
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final isDark = baseTheme.brightness == Brightness.dark;
    final visualTheme = baseTheme.copyWith(
      primaryColor: const Color(0xFF147DFF),
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF1A1A2E)
          : const Color(0xFFF8FBFF),
      cardColor: isDark ? const Color(0xFF0F3460) : Colors.white,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: const Color(0xFF147DFF),
        secondary: const Color(0xFF6A35F2),
        surface: isDark ? const Color(0xFF16213E) : Colors.white,
        onSurface: isDark ? const Color(0xFFECF0F1) : const Color(0xFF102A56),
      ),
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: isDark ? const Color(0xFF16213E) : Colors.white,
        foregroundColor: isDark
            ? const Color(0xFFECF0F1)
            : const Color(0xFF102A56),
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: isDark ? const Color(0xFFECF0F1) : const Color(0xFF102A56),
        displayColor: isDark
            ? const Color(0xFFECF0F1)
            : const Color(0xFF102A56),
      ),
    );

    return Theme(
      data: visualTheme,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF1A1A2E)
            : const Color(0xFFF8FBFF),
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: CustomBottomNavigation(
          // On recalcule l'index pour la barre de navigation
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}
