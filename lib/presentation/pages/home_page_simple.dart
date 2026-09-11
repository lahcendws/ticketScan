import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import 'tickets_page_simple.dart';
import 'ticket_list_page.dart';
import 'profile_page.dart';
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
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF147DFF);
    const navy = Color(0xFF102A56);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: const Text(
          'Scanner un ticket',
          style: TextStyle(fontWeight: FontWeight.w700, color: navy),
        ),
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F1FF),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(Icons.camera_alt, size: 60, color: primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Scan de tickets',
              style: const TextStyle(
                color: navy,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fonctionnalité bientôt disponible',
              style: const TextStyle(color: Color(0xFF5A7194), fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité en développement'),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scanner un ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
