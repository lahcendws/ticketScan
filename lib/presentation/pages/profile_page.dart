import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/language_service.dart';
import '../../core/services/app_localizations.dart';
import 'auth_page.dart';

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
    
    // Écouter les changements d'authentification
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.get('profile')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoSection(),
            const SizedBox(height: 32),
            _buildSettingsSection(),
            const SizedBox(height: 32),
            _buildNotificationsSection(),
            const SizedBox(height: 32),
            _buildAboutSection(),
            const SizedBox(height: 32),
            _buildSignOutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    // Dans Supabase, le nom est souvent dans user_metadata
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
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Premium',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
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

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paramètres',
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
                title: AppLocalizations.of(context)!.get('dark_mode'),
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
                            Icon(Icons.settings_brightness),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.get('system_mode')),
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
                            Icon(Icons.light_mode),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.get('light_mode')),
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
                            Icon(Icons.dark_mode),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.get('dark_mode')),
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
                title: AppLocalizations.of(context)!.get('language'),
                subtitle: LanguageService.getLanguageDisplayText(),
                trailing: PopupMenuButton<Locale>(
                  icon: const Icon(Icons.chevron_right),
                  onSelected: (Locale locale) async {
                    await LanguageService.setLanguage(locale);
                    // Redémarrer l'application pour appliquer la langue
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const AuthPage()),
                        (route) => false,
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem(
                        value: const Locale('fr', 'FR'),
                        child: Row(
                          children: [
                            const Text('🇫🇷'),
                            const SizedBox(width: 8),
                            Text('Français'),
                            if (LanguageService.currentLocale.languageCode == 'fr')
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
                            Text('English'),
                            if (LanguageService.currentLocale.languageCode == 'en')
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
                title: 'Stockage',
                subtitle: 'Gérer le stockage',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifications',
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
                title: 'Notifications push',
                subtitle: 'Recevoir des notifications',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                ),
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.warning_amber,
                title: 'Rappels de garantie',
                subtitle: '30 jours avant l\'expiration',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                ),
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.notifications_active,
                title: 'Tester les notifications',
                subtitle: 'Envoyer une notification de test',
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

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'À propos',
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
                title: 'Version',
                subtitle: '1.0.0',
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.privacy_tip,
                title: 'Politique de confidentialité',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.description,
                title: 'Conditions d\'utilisation',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.support_agent,
                title: 'Support',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutSection() {
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
          AppLocalizations.of(context)!.get('sign_out'),
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
