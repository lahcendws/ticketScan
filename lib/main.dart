import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

// import 'core/services/firebase_service.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/language_service.dart';
import 'data/models/ticket_provider.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/themes/app_theme.dart';
import 'core/services/app_localizations.dart';
import 'supabase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");

  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser les données de date pour le français
  await initializeDateFormatting('fr_FR', null);
  
  // await Firebase.initializeApp();
  
  await Supabase.initialize(
    url: SupabaseOptions.currentUrl,
    anonKey: SupabaseOptions.currentAnonKey,
  );
  
  // Initialiser les services
  // await FirebaseService.initialize();
  await SupabaseService.initialize();
  await NotificationService.initialize();
  await ThemeService.init();
  await LanguageService.init();
  
  runApp(const TicketScanApp());
}

class TicketScanApp extends StatefulWidget {
  const TicketScanApp({super.key});

  @override
  State<TicketScanApp> createState() => _TicketScanAppState();
}

class _TicketScanAppState extends State<TicketScanApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _themeMode = ThemeService.themeMode;
    
    // Écouter les changements de thème
    ThemeService.init().then((_) {
      if (mounted) {
        setState(() {
          _themeMode = ThemeService.themeMode;
        });
      }
    });
  }

  void _updateTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TicketProvider(),
      child: MaterialApp(
        title: 'TicketScan',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        home: const SplashPage(),
        locale: LanguageService.currentLocale,
        supportedLocales: LanguageService.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
