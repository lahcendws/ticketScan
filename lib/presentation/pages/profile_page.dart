import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/language_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/services/app_localizations.dart';
import 'auth_page.dart';
import 'premium_page.dart';
import 'privacy_policy_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  ThemeMode _currentThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _user = SupabaseService.currentUser;
    _currentThemeMode = ThemeService.themeMode;
    
    SupabaseService.authStateChanges.listen((_) {
      if (mounted) {
        setState(() {
          _user = SupabaseService.currentUser;
        });
      }
    });
  }

  Future<void> _signOut() async {
    try {
      await SupabaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthPage()),
          (route) => false,
        );
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la déconnexion');
    }
  }

  Future<void> _deleteAccount() async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.get('delete_account') ?? 'Supprimer le compte'),
        content: const Text('Cette action est définitive. Tous vos tickets et photos seront supprimés de nos serveurs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer tout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await SupabaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const AuthPage()), (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Votre demande de suppression a été prise en compte.')));
      }
    }
  }

  IconData _getThemeIcon() {
    switch (_currentThemeMode) {
      case ThemeMode.light: return Icons.light_mode;
      case ThemeMode.dark: return Icons.dark_mode;
      default: return Icons.settings_brightness;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error));
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final subscriptionService = Provider.of<SubscriptionService>(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations?.get('profile') ?? 'Profil'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserInfoSection(subscriptionService),
            const SizedBox(height: 24),
            if (!subscriptionService.isPremium) _buildPremiumBanner(localizations),
            const SizedBox(height: 32),
            _buildSettingsSection(languageService, localizations),
            const SizedBox(height: 32),
            _buildAboutSection(localizations),
            const SizedBox(height: 32),
            _buildDangerZone(localizations),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(SubscriptionService subscriptionService) {
    final String displayName = _user?.userMetadata?['display_name'] ?? 'Utilisateur';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(radius: 35, backgroundColor: Theme.of(context).primaryColor, child: const Icon(Icons.person, size: 35, color: Colors.white)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text(_user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: subscriptionService.isPremium ? Colors.amber[100] : Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                  child: Text(subscriptionService.isPremium ? 'PREMIUM' : 'GRATUIT', style: TextStyle(color: subscriptionService.isPremium ? Colors.amber[800] : Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner(AppLocalizations? localizations) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)]), borderRadius: BorderRadius.circular(16)),
        child: const Row(
          children: [
            Icon(Icons.stars, color: Colors.white, size: 30),
            SizedBox(width: 16),
            Expanded(child: Text('Passez au Premium pour scans illimités', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(LanguageService languageService, AppLocalizations? localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations?.get('settings') ?? 'Paramètres', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        
        // SÉLECTEUR DE LANGUE RESTAURÉ
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(localizations?.get('language') ?? 'Langue'),
          subtitle: Text(languageService.getLanguageDisplayText()),
          trailing: PopupMenuButton<Locale>(
            icon: const Icon(Icons.chevron_right),
            onSelected: (Locale locale) async => await languageService.setLanguage(locale),
            itemBuilder: (context) => [
              const PopupMenuItem(value: Locale('fr', 'FR'), child: Text('🇫🇷 Français')),
              const PopupMenuItem(value: Locale('en', 'US'), child: Text('🇺🇸 English')),
            ],
          ),
        ),

        // SÉLECTEUR DE THÈME RESTAURÉ
        ListTile(
          leading: Icon(_getThemeIcon()),
          title: Text(localizations?.get('dark_mode') ?? 'Thème'),
          subtitle: Text(ThemeService.getThemeModeString()),
          trailing: PopupMenuButton<ThemeMode>(
            icon: const Icon(Icons.chevron_right),
            onSelected: (ThemeMode theme) async {
              await ThemeService.setThemeMode(theme);
              setState(() => _currentThemeMode = theme);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: ThemeMode.system, child: Text('Système')),
              const PopupMenuItem(value: ThemeMode.light, child: Text('Clair')),
              const PopupMenuItem(value: ThemeMode.dark, child: Text('Sombre')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(AppLocalizations? localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations?.get('about') ?? 'À propos', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(localizations?.get('privacy_policy') ?? 'Politique de confidentialité'),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyPage())),
        ),
        const ListTile(leading: Icon(Icons.info_outline), title: Text('Version 1.0.0')),
      ],
    );
  }

  Widget _buildDangerZone(AppLocalizations? localizations) {
    return Column(
      children: [
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.grey),
          title: Text(localizations?.get('sign_out') ?? 'Se déconnecter'),
          onTap: _signOut,
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Supprimer mon compte', style: TextStyle(color: Colors.red)),
          onTap: _deleteAccount,
        ),
      ],
    );
  }
}
