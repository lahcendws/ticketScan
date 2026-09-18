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
import 'profil_premium_page.dart';
import 'version_page.dart';

class ProfilePage extends StatefulWidget {
  final void Function(int)? onNavigateTab;

  const ProfilePage({super.key, this.onNavigateTab});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _user = SupabaseService.currentUser;
  }

  Future<void> _signOut() async {
    await SupabaseService.signOut();
    if (mounted)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthPage()),
        (r) => false,
      );
  }

  Future<void> _contactSupport() async {
    final String subject = Uri.encodeComponent(
      "[TicketScan] Feedback / Support",
    );
    final String body = Uri.encodeComponent(
      "Bonjour, j'utilise le compte ${_user?.email}. Voici mon message : ",
    );
    // NOUVELLE ADRESSE MAIL APPLIQUÉE
    final Uri emailLaunchUri = Uri.parse(
      "mailto:ticketscan1.help@outlook.fr?subject=$subject&body=$body",
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Impossible d\'ouvrir l\'application email';
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez envoyer un mail à ticketscan1.help@outlook.fr',
            ),
          ),
        );
    }
  }

  Future<void> _deleteAccount() async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc?.get('delete_account') ?? 'Supprimer'),
        content: Text(
          loc?.get('delete_account_warning') ?? 'Action irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc?.get('cancel') ?? 'Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              loc?.get('delete') ?? 'Supprimer',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        await Supabase.instance.client.functions.invoke('delete-user');
        await SupabaseService.signOut();
        if (mounted)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthPage()),
            (r) => false,
          );
      } catch (e) {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  void _openProfilPremium() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilPremiumPage()),
    );
  }

  void _openTickets() {
    // Si Mon compte est poussé (ex. via le drawer), on revient d'abord à la
    // page sous-jacente ; sinon on bascule simplement d'onglet : la barre de
    // navigation en bas reste ainsi toujours visible.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    widget.onNavigateTab?.call(1);
  }

  void _openAlerts() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    widget.onNavigateTab?.call(2);
  }

  void _openVersion() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VersionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final sub = Provider.of<SubscriptionService>(context);
    final lang = Provider.of<LanguageService>(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color heading = isDark
        ? const Color(0xFFECF0F1)
        : const Color(0xFF102A56);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: heading,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          loc?.get('my_account') ?? 'Mon compte',
          style: TextStyle(fontWeight: FontWeight.w800, color: heading),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: loc?.get('premium_title') ?? 'Profil Premium',
            onPressed: _openProfilPremium,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildUserInfo(sub, loc),
                if (!sub.isPremium) ...[
                  const SizedBox(height: 24),
                  _buildPremiumBanner(loc),
                ],
                const SizedBox(height: 24),
                _buildMenu(loc),
                const SizedBox(height: 32),
                _buildSettings(lang, loc),
                const SizedBox(height: 24),
                if (!sub.isPremium) ...[
                  _buildDeleteLink(loc),
                  const SizedBox(height: 8),
                ],
                _buildSignOutButton(loc, isDark),
              ],
            ),
          ),
          if (_isDeleting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(SubscriptionService sub, AppLocalizations? loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user?.email ?? 'Utilisateur',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A35F2).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sub.isPremium
                        ? (loc?.get('premium_badge') ?? 'PREMIUM')
                        : (loc?.get('free') ?? 'GRATUIT'),
                    style: const TextStyle(
                      color: Color(0xFF6A35F2),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner(AppLocalizations? loc) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PremiumPage()),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6A35F2),
              const Color(0xFF6A35F2).withOpacity(0.75),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.stars, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loc?.get('premium_banner_msg') ?? 'Passez à la version Premium',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(AppLocalizations? loc) {
    final Color iconColor = Theme.of(context).primaryColor;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.confirmation_number, color: iconColor),
            title: Text(loc?.get('tickets_short') ?? 'Mes tickets'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: _openTickets,
          ),
          Divider(height: 1, indent: 16, color: Colors.grey.withOpacity(0.2)),
          ListTile(
            leading: Icon(Icons.card_membership, color: iconColor),
            title: Text(loc?.get('subscription') ?? 'Abonnement'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: _openProfilPremium,
          ),
          Divider(height: 1, indent: 16, color: Colors.grey.withOpacity(0.2)),
          ListTile(
            leading: Icon(Icons.notifications_outlined, color: iconColor),
            title: Text(loc?.get('alerts_title') ?? 'Alertes'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: _openAlerts,
          ),
          Divider(height: 1, indent: 16, color: Colors.grey.withOpacity(0.2)),
          ListTile(
            leading: Icon(Icons.help_outline, color: iconColor),
            title: Text(loc?.get('help') ?? 'Aide'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: _contactSupport,
          ),
          Divider(height: 1, indent: 16, color: Colors.grey.withOpacity(0.2)),
          ListTile(
            leading: Icon(Icons.info_outline, color: iconColor),
            title: Text(loc?.get('about') ?? 'À propos'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: _openVersion,
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(LanguageService lang, AppLocalizations? loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc?.get('settings') ?? 'Paramètres',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(loc?.get('language') ?? 'Langue'),
                trailing: PopupMenuButton<Locale>(
                  onSelected: (l) => lang.setLanguage(l),
                  itemBuilder: (c) => [
                    const PopupMenuItem(
                      value: Locale('fr', 'FR'),
                      child: Text('Français'),
                    ),
                    const PopupMenuItem(
                      value: Locale('en', 'US'),
                      child: Text('English'),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                indent: 16,
                color: Colors.grey.withOpacity(0.2),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: Text(loc?.get('dark_mode') ?? 'Thème'),
                trailing: PopupMenuButton<ThemeMode>(
                  onSelected: (m) => ThemeService.setThemeMode(m),
                  itemBuilder: (c) => [
                    PopupMenuItem(
                      value: ThemeMode.light,
                      child: Text(loc?.get('theme_light') ?? 'Clair'),
                    ),
                    PopupMenuItem(
                      value: ThemeMode.dark,
                      child: Text(loc?.get('theme_dark') ?? 'Sombre'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteLink(AppLocalizations? loc) {
    return TextButton.icon(
      onPressed: _deleteAccount,
      style: TextButton.styleFrom(foregroundColor: Colors.red),
      icon: const Icon(Icons.delete_outline, size: 18),
      label: Text(loc?.get('delete_account') ?? 'Supprimer le compte'),
    );
  }

  Widget _buildSignOutButton(AppLocalizations? loc, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _signOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white12 : const Color(0xFF102A56),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.logout),
        label: Text(loc?.get('sign_out') ?? 'Déconnexion'),
      ),
    );
  }
}
