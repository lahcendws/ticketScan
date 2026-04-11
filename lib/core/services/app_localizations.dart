import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Français
  static const Map<String, String> _fr = {
    // Général
    'app_name': 'TicketScan',
    'ok': 'OK',
    'cancel': 'Annuler',
    'save': 'Enregistrer',
    'delete': 'Supprimer',
    'edit': 'Modifier',
    'search': 'Rechercher',
    'loading': 'Chargement...',
    'error': 'Erreur',
    'success': 'Succès',
    'retry': 'Réessayer',
    'close': 'Fermer',

    // Authentification
    'login': 'Connexion',
    'register': 'Inscription',
    'email': 'Email',
    'password': 'Mot de passe',
    'forgot_password': 'Mot de passe oublié?',
    'reset_password': 'Réinitialiser le mot de passe',
    'create_account': 'Créer un compte',
    'already_have_account': 'Vous avez déjà un compte?',
    'dont_have_account': 'Vous n\'avez pas de compte?',
    'sign_in': 'Se connecter',
    'sign_up': 'S\'inscrire',
    'sign_out': 'Se déconnecter',
    'invalid_email': 'Email invalide',
    'weak_password': 'Le mot de passe doit contenir au moins 6 caractères',
    'user_not_found': 'Aucun utilisateur trouvé',
    'wrong_password': 'Mot de passe incorrect',
    'email_already_used': 'Cet email est déjà utilisé',
    'no_account': 'Vous n\'avez pas de compte?',

    // Navigation
    'tickets': 'Tickets',
    'search_tickets': 'Rechercher',
    'scan': 'Scanner',
    'profile': 'Profil',
    'home': 'Accueil',

    // Tickets
    'my_tickets': 'Mes Tickets',
    'no_tickets': 'Aucun ticket',
    'add_ticket': 'Ajouter un ticket',
    'ticket_details': 'Détails du ticket',
    'store_name': 'Magasin',
    'date': 'Date',
    'total_amount': 'Montant total',
    'products': 'Produits',
    'warranty': 'Garantie',
    'warranty_end_date': 'Fin de garantie',
    'warranty_expiring': 'Garantie expire bientôt',
    'warranty_expired': 'Garantie expirée',
    'days_remaining': 'jours restants',
    'day_remaining': 'jour restant',
    'expired': 'Expiré',
    'scan_first_ticket': 'Scannez votre premier ticket pour commencer',

    // Scan
    'scan_ticket': 'Scanner un ticket',
    'camera_permission': 'Permission caméra requise',
    'grant_permission': 'Accorder la permission',
    'take_photo': 'Prendre une photo',
    'gallery': 'Galerie',
    'processing': 'Traitement en cours...',

    // Profil
    'settings': 'Paramètres',
    'dark_mode': 'Mode sombre',
    'light_mode': 'Mode clair',
    'system_mode': 'Système',
    'language': 'Langue',
    'notifications': 'Notifications',
    'push_notifications': 'Notifications push',
    'warranty_notifications': 'Rappels de garantie',
    'test_notifications': 'Tester les notifications',
    'privacy_policy': 'Politique de confidentialité',
    'terms_of_service': 'Conditions d\'utilisation',
    'support': 'Support',
    'storage': 'Stockage',
    'about': 'À propos',
    'version': 'Version',

    // Messages
    'ticket_saved': 'Ticket enregistré avec succès!',
    'ticket_deleted': 'Ticket supprimé avec succès!',
    'image_uploaded': 'Image téléchargée avec succès!',
    'logout_success': 'Déconnexion réussie',
    'email_sent': 'Email envoyé',
    'network_error': 'Erreur de connexion. Vérifiez votre internet.',
    'camera_error': 'Erreur d\'accès à la caméra.',
    'storage_error': 'Erreur de stockage.',
    'generic_error': 'Une erreur est survenue. Veuillez réessayer.',
    'total': 'Total',
    'export_csv': 'Exporter en CSV',
    'filters_soon': 'Filtres bientôt disponibles',
    'scan_soon': 'Scan bientôt disponible',
    'quick_search': 'Recherche rapide',
    'recent_searches': 'Recherches récentes',
    'no_recent_searches': 'Aucune recherche récente',
    'no_results': 'Aucun résultat trouvé',
    'try_other_keywords': 'Essayez avec d\'autres mots-clés',
    'search_hint': 'Rechercher un ticket...',
    'stores': 'Magasins',
    'share': 'Partager',
  };

  // Anglais
  static const Map<String, String> _en = {
    // Général
    'app_name': 'TicketScan',
    'ok': 'OK',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'search': 'Search',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'retry': 'Retry',
    'close': 'Close',

    // Authentification
    'login': 'Login',
    'register': 'Register',
    'email': 'Email',
    'password': 'Password',
    'forgot_password': 'Forgot password?',
    'reset_password': 'Reset password',
    'create_account': 'Create account',
    'already_have_account': 'Already have an account?',
    'dont_have_account': 'Don\'t have an account?',
    'sign_in': 'Sign in',
    'sign_up': 'Sign up',
    'sign_out': 'Sign out',
    'invalid_email': 'Invalid email',
    'weak_password': 'Password must be at least 6 characters',
    'user_not_found': 'No user found',
    'wrong_password': 'Wrong password',
    'email_already_used': 'Email already in use',
    'no_account': 'Don\'t have an account?',

    // Navigation
    'tickets': 'Tickets',
    'search_tickets': 'Search',
    'scan': 'Scan',
    'profile': 'Profile',
    'home': 'Home',

    // Tickets
    'my_tickets': 'My Tickets',
    'no_tickets': 'No tickets',
    'add_ticket': 'Add ticket',
    'ticket_details': 'Ticket details',
    'store_name': 'Store',
    'date': 'Date',
    'total_amount': 'Total amount',
    'products': 'Products',
    'warranty': 'Warranty',
    'warranty_end_date': 'Warranty end date',
    'warranty_expiring': 'Warranty expiring soon',
    'warranty_expired': 'Warranty expired',
    'days_remaining': 'days remaining',
    'day_remaining': 'day remaining',
    'expired': 'Expired',
    'scan_first_ticket': 'Scan your first ticket to get started',

    // Scan
    'scan_ticket': 'Scan ticket',
    'camera_permission': 'Camera permission required',
    'grant_permission': 'Grant permission',
    'take_photo': 'Take photo',
    'gallery': 'Gallery',
    'processing': 'Processing...',

    // Profil
    'settings': 'Settings',
    'dark_mode': 'Dark mode',
    'light_mode': 'Light mode',
    'system_mode': 'System',
    'language': 'Language',
    'notifications': 'Notifications',
    'push_notifications': 'Push notifications',
    'warranty_notifications': 'Warranty reminders',
    'test_notifications': 'Test notifications',
    'privacy_policy': 'Privacy policy',
    'terms_of_service': 'Terms of service',
    'support': 'Support',
    'storage': 'Storage',
    'about': 'About',
    'version': 'Version',

    // Messages
    'ticket_saved': 'Ticket saved successfully!',
    'ticket_deleted': 'Ticket deleted successfully!',
    'image_uploaded': 'Image uploaded successfully!',
    'logout_success': 'Logout successful',
    'email_sent': 'Email sent',
    'network_error': 'Network error. Check your internet connection.',
    'camera_error': 'Camera access error.',
    'storage_error': 'Storage error.',
    'generic_error': 'An error occurred. Please try again.',
    'total': 'Total',
    'export_csv': 'Export to CSV',
    'filters_soon': 'Filters coming soon',
    'scan_soon': 'Scan coming soon',
    'quick_search': 'Quick search',
    'recent_searches': 'Recent searches',
    'no_recent_searches': 'No recent searches',
    'no_results': 'No results found',
    'try_other_keywords': 'Try other keywords',
    'search_hint': 'Search a ticket...',
    'stores': 'Stores',
    'share': 'Share',
  };

  String get(String key) {
    Map<String, String> translations;
    
    switch (locale.languageCode) {
      case 'en':
        translations = _en;
        break;
      case 'fr':
      default:
        translations = _fr;
        break;
    }
    
    return translations[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
