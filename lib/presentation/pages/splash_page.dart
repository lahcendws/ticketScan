import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/version_service.dart';
import 'home_page.dart';
import 'auth_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _textController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textController, curve: Curves.easeInOut));
    _logoController.forward().then((_) => _textController.forward());
  }

  Future<void> _initializeApp() async {
    // 1. Attendre un peu pour l'animation
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // 2. Vérifier si une mise à jour est requise
    final status = await VersionService.checkVersion();
    
    if (status != null) {
      if (status['maintenance'] == true) {
        _showMaintenanceDialog();
        return;
      }
      if (status['needsUpdate'] == true) {
        _showUpdateDialog(status['url']);
        return;
      }
    }

    // 3. Continuer vers l'Auth ou Home
    if (!mounted) return;
    final user = SupabaseService.currentUser;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => user != null ? const HomePage() : const AuthPage()),
    );
  }

  void _showUpdateDialog(String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Mise à jour requise'),
        content: const Text('Une nouvelle version de TicketScan est disponible. Veuillez mettre à jour l\'application pour continuer.'),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (url.isNotEmpty) {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Maintenance'),
        content: Text('L\'application est actuellement en maintenance pour amélioration. Merci de revenir plus tard !'),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _logoAnimation,
              builder: (context, child) => Transform.scale(
                scale: _logoAnimation.value,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.receipt_long, size: 60, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _textAnimation,
              builder: (context, child) => Opacity(
                opacity: _textAnimation.value,
                child: Text('TicketScan', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              ),
            ),
            const SizedBox(height: 64),
            const CircularProgressIndicator(strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}
