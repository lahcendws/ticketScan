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

  IconData _getThemeIcon() {
    switch (_currentThemeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      default:
        return Icons.settings_brightness;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final subscriptionService = Provider.of<SubscriptionService>(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.get('profile') ?? 'Profil'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoSection(subscriptionService),
            const SizedBox(height: 24),
            if (!subscriptionService.isPremium) _buildPremiumBanner(localizations),
            const SizedBox(height: 32),
            _buildSettingsSection(languageService, localizations),
            const SizedBox(height: 32),
            _buildNotificationsSection(localizations),
            const SizedBox(height: 32),
            _buildAboutSection(localizations),
            const SizedBox(height: 32),
            _buildSignOutSection(localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(SubscriptionService subscriptionService) {
    final String displayName = _user?.userMetadata?['display_name'] ??
                               _user?.userMetadata?['full_name'] ??
                               'Utilisateur';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: subscriptionService.isPremium 
                        ? Colors.amber.withOpacity(0.1) 
                        : Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    subscriptionService.isPremium ? 'Premium' : 'Gratuit',
                    style: TextStyle(
                      color: subscriptionService.isPremium ? Colors.amber[700] : Theme.of(context).primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  Widget _buildPremiumBanner(AppLocalizations? localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations?.get('upgrade_premium') ?? 'Passez au Premium',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text(
                  'Scans illimités et plus encore',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage())),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Voir'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(LanguageService languageService, AppLocalizations? localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations?.get('settings') ?? 'Paramètres',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingTile(
                icon: Icons.dark_mode,
                title: localizations?.get('dark_mode') ?? 'Mode sombre',
                subtitle: ThemeService.getThemeModeString(),
                trailing: PopupMenuButton<ThemeMode>(
                  icon: Icon(_getThemeIcon()),
                  onSelected: (ThemeMode theme) async {
                    await ThemeService.setThemeMode(theme);
                    setState(() {
                      _currentThemeMode = theme;
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem(
                        value: ThemeMode.system,
                        child: Row(
                          children: [
                            const Icon(Icons.settings_brightness),
                            const SizedBox(width: 8),
                            Text(localizations?.get('system_mode') ?? 'Système'),
                            if (_currentThemeMode == ThemeMode.system)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(Icons.check, color: Theme.of(context).primaryColor),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ThemeMode.light,
                        child: Row(
                          children: [
                            const Icon(Icons.light_mode),
                            const SizedBox(width: 8),
                            Text(localizations?.get('light_mode') ?? 'Mode clair'),
                            if (_currentThemeMode == ThemeMode.light)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(Icons.check, color: Theme.of(context).primaryColor),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ThemeMode.dark,
                        child: Row(
                          children: [
                            const Icon(Icons.dark_mode),
                            const SizedBox(width: 8),
                            Text(localizations?.get('dark_mode') ?? 'Mode sombre'),
                            if (_currentThemeMode == ThemeMode.dark)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(Icons.check, color: Theme.of(context).primaryColor),
                              ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.language,
                title: localizations?.get('language') ?? 'Langue',
                subtitle: languageService.getLanguageDisplayText(),
                trailing: PopupMenuButton<Locale>(
                  icon: const Icon(Icons.chevron_right),
                  onSelected: (Locale locale) async {
                    await languageService.setLanguage(locale);
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem(
                        value: const Locale('fr', 'FR'),
                        child: Row(
                          children: [
                            const Text('🇫🇷'),
                            const SizedBox(width: 8),
                            const Text('Français'),
                            if (languageService.currentLocale.languageCode == 'fr')
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(Icons.check, color: Theme.of(context).primaryColor),
                              ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: const Locale('en', 'US'),
                        child: Row(
                          children: [
                            const Text('🇺🇸'),
                            const SizedBox(width: 8),
                            const Text('English'),
                            if (languageService.currentLocale.languageCode == 'en')
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(Icons.check, color: Theme.of(context).primaryColor),
                              ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.storage,
                title: localizations?.get('storage') ?? 'Stockage',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(AppLocalizations? localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations?.get('notifications') ?? 'Notifications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingTile(
                icon: Icons.notifications,
                title: localizations?.get('push_notifications') ?? 'Notifications push',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                ),
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.warning_amber,
                title: localizations?.get('warranty_notifications') ?? 'Rappels de garantie',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                ),
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.notifications_active,
                title: localizations?.get('test_notifications') ?? 'Tester les notifications',
                trailing: const Icon(Icons.play_arrow),
                onTap: () async {
                  await NotificationService.showTestNotification();
                },
              ),
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
        Text(
          localizations?.get('about') ?? 'À propos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingTile(
                icon: Icons.info,
                title: localizations?.get('version') ?? 'Version',
                subtitle: '1.0.0',
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.privacy_tip,
                title: localizations?.get('privacy_policy') ?? 'Politique de confidentialité',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.description,
                title: localizations?.get('terms_of_service') ?? 'Conditions d\'utilisation',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.support_agent,
                title: localizations?.get('support') ?? 'Support',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutSection(AppLocalizations? localizations) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(
          Icons.logout,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(
          localizations?.get('sign_out') ?? 'Se déconnecter',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: _signOut,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).dividerColor,
    );
  }
}
