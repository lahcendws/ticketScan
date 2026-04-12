import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/language_service.dart';
import 'core/services/subscription_service.dart';
import 'data/models/ticket_provider.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/themes/app_theme.dart';
import 'core/services/app_localizations.dart';
import 'supabase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");

  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('fr_FR', null);
  
  await Supabase.initialize(
    url: SupabaseOptions.currentUrl,
    anonKey: SupabaseOptions.currentAnonKey,
  );
  
  await SupabaseService.initialize();
  await NotificationService.initialize();
  await ThemeService.init();
  
  final languageService = LanguageService();
  await languageService.init();

  final subscriptionService = SubscriptionService();
  await subscriptionService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => languageService),
        ChangeNotifierProvider(create: (_) => subscriptionService),
      ],
      child: const TicketScanApp(),
    ),
  );
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
    
    ThemeService.init().then((_) {
      if (mounted) {
        setState(() {
          _themeMode = ThemeService.themeMode;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    
    return MaterialApp(
      title: 'TicketScan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: const SplashPage(),
      locale: languageService.currentLocale,
      supportedLocales: languageService.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
