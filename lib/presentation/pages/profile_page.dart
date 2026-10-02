import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
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
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthPage()),
        (r) => false,
      );
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez envoyer un mail à ticketscan1.help@outlook.fr',
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    // Get all required data while context is definitely valid
    final loc = AppLocalizations.of(context);
    final sub = Provider.of<SubscriptionService>(context, listen: false);
    final isPremium = sub.isPremium;
    final isMounted = mounted;

    debugPrint(
      '_deleteAccount: Starting delete process, isPremium=$isPremium, mounted=$isMounted',
    );

    // Determine which warning to show based on subscription status
    final String warningKey = isPremium
        ? (Platform.isIOS
              ? 'delete_account_premium_warning_ios'
              : 'delete_account_premium_warning_android')
        : 'delete_account_warning';

    Widget dialogContent;
    if (isPremium) {
      final String warningTemplate =
          loc?.get(warningKey) ?? 'Action irréversible.';
      final String url = Platform.isIOS
          ? 'https://apps.apple.com/account/subscriptions'
          : 'https://play.google.com/store/account/subscriptions?sku=premium_monthly&package=com.devevolu.ticketscan';
      // Determine placeholder based on language
      final String placeholder = (loc?.locale.languageCode == 'fr')
          ? '[lien gestion abonnement]'
          : '[subscription management link]';
      final List<TextSpan> spans = [];
      final List<String> parts = warningTemplate.split(placeholder);
      if (parts.length == 2) {
        spans.add(TextSpan(text: parts[0]));
        spans.add(
          TextSpan(
            text: Platform.isIOS
                ? loc?.get('manage_subscription') ?? 'Gérer mon abonnement'
                : loc?.get('manage_subscription') ?? 'Manage subscription',
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                // Don't use context here - just launch the URL
                try {
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  }
                } catch (e) {
                  debugPrint('Error launching URL: $e');
                }
              },
          ),
        );
        spans.add(TextSpan(text: parts[1]));
      } else {
        // fallback: just show the template with URL as plain text
        spans.add(TextSpan(text: warningTemplate));
      }
      dialogContent = RichText(
        text: TextSpan(
          children: spans,
          style: const TextStyle(
            color: Colors.black87, // Explicit style to avoid context issues
          ),
        ),
      );
    } else {
      dialogContent = Text(
        loc?.get(warningKey) ?? 'Action irréversible.',
        style: const TextStyle(
          color: Colors.black87, // Explicit style to avoid context issues
        ),
      );
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(loc?.get('delete_account') ?? 'Supprimer'),
        content: dialogContent,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc?.get('cancel') ?? 'Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              loc?.get('delete') ?? 'Supprimer',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    debugPrint('_deleteAccount: Dialog result: $confirmed, mounted: $mounted');

    if (confirmed == true && mounted) {
      debugPrint('_deleteAccount: User confirmed deletion, proceeding...');
      setState(() => _isDeleting = true);
      try {
        debugPrint('_deleteAccount: Invoking delete-user function');
        await Supabase.instance.client.functions.invoke('delete-user');
        debugPrint('_deleteAccount: delete-user function invoked successfully');
        await SupabaseService.signOut();
        debugPrint('_deleteAccount: Signed out successfully');
        if (mounted) {
          debugPrint('_deleteAccount: Navigating to auth page');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthPage()),
            (r) => false,
          );
        } else {
          debugPrint(
            '_deleteAccount: Not mounted after signout, skipping navigation',
          );
        }
      } catch (e) {
        debugPrint('_deleteAccount: Error during deletion: $e');
        if (mounted) {
          setState(() => _isDeleting = false);
        }
        // Re-throw to see if it's being swallowed somewhere
        rethrow;
      }
    } else {
      debugPrint('_deleteAccount: Deletion not confirmed or not mounted');
      if (mounted) {
        setState(() => _isDeleting = false);
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

  Widget _buildSettingsSelector<T>(
    BuildContext context, {
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 150,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          dropdownColor: Theme.of(context).cardColor,
          menuMaxHeight: 220,
          menuWidth: 160,
          borderRadius: BorderRadius.circular(12),
          elevation: 8,
          icon: const Icon(Icons.chevron_right, size: 20),
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
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
                _buildDeleteLink(loc),
                const SizedBox(height: 8),
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
                    color: const Color(0xFF6A35F2).withValues(alpha: 0.12),
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
              const Color(0xFF6A35F2).withValues(alpha: 0.75),
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
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.confirmation_number, color: iconColor),
            title: Text(loc?.get('tickets_short') ?? 'Mes tickets'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: _openTickets,
          ),
          Divider(
            height: 1,
            indent: 16,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          ListTile(
            leading: Icon(Icons.card_membership, color: iconColor),
            title: Text(loc?.get('subscription') ?? 'Abonnement'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: _openProfilPremium,
          ),
          Divider(
            height: 1,
            indent: 16,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          ListTile(
            leading: Icon(Icons.notifications_outlined, color: iconColor),
            title: Text(loc?.get('alerts_title') ?? 'Alertes'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: _openAlerts,
          ),
          Divider(
            height: 1,
            indent: 16,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          ListTile(
            leading: Icon(Icons.help_outline, color: iconColor),
            title: Text(loc?.get('help') ?? 'Aide'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: _contactSupport,
          ),
          Divider(
            height: 1,
            indent: 16,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
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
        Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.language,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(loc?.get('language') ?? 'Langue'),
                trailing: _buildSettingsSelector<Locale>(
                  context,
                  value: lang.currentLocale,
                  items: [
                    DropdownMenuItem(
                      value: const Locale('fr', 'FR'),
                      child: Text(loc?.get('language_french') ?? 'Français'),
                    ),
                    DropdownMenuItem(
                      value: const Locale('en', 'US'),
                      child: Text(loc?.get('language_english') ?? 'English'),
                    ),
                  ],
                  onChanged: (locale) {
                    if (locale != null) {
                      lang.setLanguage(locale);
                    }
                  },
                ),
              ),
              Divider(
                height: 1,
                indent: 16,
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              ListTile(
                leading: Icon(
                  Icons.dark_mode,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(loc?.get('dark_mode') ?? 'Thème'),
                trailing: _buildSettingsSelector<ThemeMode>(
                  context,
                  value: ThemeService.themeMode,
                  items: [
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text(loc?.get('theme_light') ?? 'Clair'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text(loc?.get('theme_dark') ?? 'Sombre'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text(loc?.get('theme_system') ?? 'Système'),
                    ),
                  ],
                  onChanged: (mode) {
                    if (mode != null) {
                      ThemeService.setThemeMode(mode);
                    }
                  },
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
