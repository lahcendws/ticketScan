import 'package:flutter/material.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const TicketScanApp());
}

class TicketScanApp extends StatelessWidget {
  const TicketScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TicketScan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashPage(),
    );
  }
}
