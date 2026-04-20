import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const Map<String, String> _fr = {
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
    'login': 'Connexion',
    'register': 'Inscription',
    'email': 'Email',
    'password': 'Mot de passe',
    'forgot_password': 'Mot de passe oublié?',
    'reset_password': 'Réinitialiser le mot de passe',
    'sign_in': 'Se connecter',
    'sign_up': 'S\'inscrire',
    'sign_out': 'Se déconnecter',
    'invalid_email': 'Email invalide',
    'weak_password': 'Minimum 6 caractères',
    'user_not_found': 'Utilisateur inconnu',
    'wrong_password': 'Mot de passe incorrect',
    'email_already_used': 'Email déjà utilisé',
    'no_account': 'Pas encore de compte ? ',
    'already_account': 'Déjà un compte ? ',
    'tickets': 'Tickets',
    'search_tickets': 'Rechercher',
    'scan': 'Scanner',
    'profile': 'Profil',
    'home': 'Accueil',
    'my_tickets': 'Mes Tickets',
    'no_tickets': 'Aucun ticket',
    'ticket_details': 'Détails du ticket',
    'store_name': 'Magasin',
    'date': 'Date',
    'total_amount': 'Montant total',
    'products': 'Articles',
    'warranty': 'Garantie',
    'warranty_end_date': 'Fin de garantie',
    'warranty_expiring': 'Expire bientôt',
    'warranty_expired': 'Expiré',
    'scan_ticket': 'Scanner un ticket',
    'camera_permission': 'Permission caméra requise',
    'take_photo': 'Prendre une photo',
    'processing': 'Traitement...',
    'settings': 'Paramètres',
    'dark_mode': 'Mode sombre',
    'light_mode': 'Mode clair',
    'system_mode': 'Système',
    'language': 'Langue',
    'privacy_policy': 'Politique de confidentialité',
    'about': 'À propos',
    'version': 'Version',
    'upgrade_premium': 'Passer au Premium',
    'premium_banner_msg': 'Passez au Premium pour scans illimités',
    'limit_reached': 'Limite atteinte',
    'limit_reached_msg': 'Vous avez atteint votre limite de scans. Passez au Premium pour continuer sans limites.',
    'delete_account': 'Supprimer le compte',
    'delete_account_warning': 'Cette action est irréversible. Toutes vos données seront supprimées.',
    'generic_error': 'Une erreur est survenue.',
    'email_sent': 'Email envoyé',
    'no_warranty_detected': 'Aucune garantie détectée',
    'no_warranty_msg': 'Ce ticket ne contient aucun produit sous garantie. Il ne sera pas enregistré.',
    'scan_guide_long': 'Ticket long ? Prenez des photos de près (Haut, Milieu, Bas)',
    'scans_count': 'scans ce mois',
  };

  static const Map<String, String> _en = {
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
    'login': 'Login',
    'register': 'Register',
    'email': 'Email',
    'password': 'Password',
    'forgot_password': 'Forgot password?',
    'reset_password': 'Reset password',
    'sign_in': 'Sign in',
    'sign_up': 'Sign up',
    'sign_out': 'Sign out',
    'invalid_email': 'Invalid email',
    'weak_password': 'Min. 6 characters',
    'user_not_found': 'User not found',
    'wrong_password': 'Wrong password',
    'email_already_used': 'Email already in use',
    'no_account': 'No account? ',
    'already_account': 'Already have an account? ',
    'tickets': 'Tickets',
    'search_tickets': 'Search',
    'scan': 'Scan',
    'profile': 'Profile',
    'home': 'Home',
    'my_tickets': 'My Tickets',
    'no_tickets': 'No tickets',
    'ticket_details': 'Ticket details',
    'store_name': 'Store',
    'date': 'Date',
    'total_amount': 'Total amount',
    'products': 'Articles',
    'warranty': 'Warranty',
    'warranty_end_date': 'Warranty end date',
    'warranty_expiring': 'Expiring soon',
    'warranty_expired': 'Expired',
    'scan_ticket': 'Scan a ticket',
    'camera_permission': 'Camera permission required',
    'take_photo': 'Take photo',
    'processing': 'Processing...',
    'settings': 'Settings',
    'dark_mode': 'Dark mode',
    'light_mode': 'Light mode',
    'system_mode': 'System',
    'language': 'Language',
    'privacy_policy': 'Privacy policy',
    'about': 'About',
    'version': 'Version',
    'upgrade_premium': 'Upgrade to Premium',
    'premium_banner_msg': 'Go Premium for unlimited scans',
    'limit_reached': 'Limit reached',
    'limit_reached_msg': 'You have reached your scan limit. Upgrade to Premium for unlimited access.',
    'delete_account': 'Delete account',
    'delete_account_warning': 'This action is irreversible. All your data will be deleted.',
    'generic_error': 'An error occurred.',
    'email_sent': 'Email sent',
    'no_warranty_detected': 'No warranty detected',
    'no_warranty_msg': 'This ticket contains no warranty products. It will not be saved.',
    'scan_guide_long': 'Long ticket? Take close-up photos (Top, Middle, Bottom)',
    'scans_count': 'scans this month',
  };

  String get(String key) {
    Map<String, String> translations = (locale.languageCode == 'en') ? _en : _fr;
    return translations[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'fr'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
