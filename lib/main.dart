import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'presentation/pages/reset_password_page.dart';

import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/language_service.dart';
import 'core/services/camera_service.dart';
import 'core/services/subscription_service.dart';
import 'data/models/ticket_provider.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/themes/app_theme.dart';
import 'core/services/app_localizations.dart';
import 'supabase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
  await CameraService.initialize();
  
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
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _themeMode = ThemeService.themeMode;
    
    ThemeService.themeModeNotifier.addListener(_onThemeChanged);

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery && mounted) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
        );
      }
    });
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        _themeMode = ThemeService.themeMode;
      });
    }
  }

  @override
  void dispose() {
    ThemeService.themeModeNotifier.removeListener(_onThemeChanged);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    
    return MaterialApp(
      title: 'TicketScan',
      navigatorKey: navigatorKey,
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
