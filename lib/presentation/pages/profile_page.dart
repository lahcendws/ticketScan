import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/supabase_service.dart';
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
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _user = SupabaseService.currentUser;
    _currentThemeMode = ThemeService.themeMode;
  }

  Future<void> _signOut() async {
    await SupabaseService.signOut();
    if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const AuthPage()), (r) => false);
  }

  Future<void> _contactSupport() async {
    final String subject = Uri.encodeComponent("[TicketScan] Feedback / Support");
    final String body = Uri.encodeComponent("Bonjour, j'utilise le compte ${_user?.email}. Voici mon message : ");
    final Uri emailLaunchUri = Uri.parse("mailto:support@ticketscan.app?subject=$subject&body=$body");

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Impossible d\'ouvrir l\'application email';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez envoyer un mail à support@ticketscan.app')));
    }
  }

  Future<void> _deleteAccount() async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc?.get('delete_account') ?? 'Supprimer'),
        content: Text(loc?.get('delete_account_warning') ?? 'Action irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(loc?.get('cancel') ?? 'Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(loc?.get('delete') ?? 'Supprimer', style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        await Supabase.instance.client.functions.invoke('delete-user');
        await SupabaseService.signOut();
        if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const AuthPage()), (r) => false);
      } catch (e) {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final sub = Provider.of<SubscriptionService>(context);
    final lang = Provider.of<LanguageService>(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc?.get('profile') ?? 'Profil'), elevation: 0),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildUserInfo(sub),
                const SizedBox(height: 24),
                if (!sub.isPremium) _buildPremiumBanner(loc),
                const SizedBox(height: 32),
                _buildSettings(lang, loc),
                const SizedBox(height: 32),
                _buildAbout(loc),
                const SizedBox(height: 32),
                _buildSignOut(loc),
              ],
            ),
          ),
          if (_isDeleting) Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildUserInfo(SubscriptionService sub) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundColor: Theme.of(context).primaryColor, child: const Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_user?.email ?? 'Utilisateur', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(sub.isPremium ? 'PREMIUM' : 'FREE', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ])),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner(AppLocalizations? loc) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)]), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Icon(Icons.stars, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(loc?.get('premium_banner_msg') ?? 'Passer au Premium', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          const Icon(Icons.chevron_right, color: Colors.white),
        ]),
      ),
    );
  }

  Widget _buildSettings(LanguageService lang, AppLocalizations? loc) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(loc?.get('settings') ?? 'Paramètres', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 12),
      ListTile(
        leading: const Icon(Icons.language),
        title: Text(loc?.get('language') ?? 'Langue'),
        trailing: PopupMenuButton<Locale>(
          onSelected: (l) => lang.setLanguage(l),
          itemBuilder: (c) => [
            const PopupMenuItem(value: Locale('fr', 'FR'), child: Text('Français')),
            const PopupMenuItem(value: Locale('en', 'US'), child: Text('English')),
          ],
        ),
      ),
      ListTile(
        leading: const Icon(Icons.dark_mode),
        title: Text(loc?.get('dark_mode') ?? 'Thème'),
        trailing: PopupMenuButton<ThemeMode>(
          onSelected: (m) => ThemeService.setThemeMode(m),
          itemBuilder: (c) => [
            const PopupMenuItem(value: ThemeMode.light, child: Text('Clair')),
            const PopupMenuItem(value: ThemeMode.dark, child: Text('Sombre')),
          ],
        ),
      ),
    ]);
  }

  Widget _buildAbout(AppLocalizations? loc) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(loc?.get('about') ?? 'À propos', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ListTile(
        leading: const Icon(Icons.privacy_tip),
        title: Text(loc?.get('privacy_policy') ?? 'Confidentialité'),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyPage())),
      ),
      ListTile(
        leading: const Icon(Icons.support_agent),
        title: Text(loc?.get('contact_support') ?? 'Support'),
        onTap: _contactSupport,
      ),
    ]);
  }

  Widget _buildSignOut(AppLocalizations? loc) {
    return Column(children: [
      ListTile(leading: const Icon(Icons.logout), title: Text(loc?.get('sign_out') ?? 'Déconnexion'), onTap: _signOut),
      ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: Text(loc?.get('delete_account') ?? 'Supprimer le compte', style: const TextStyle(color: Colors.red)), onTap: _deleteAccount),
    ]);
  }
}
