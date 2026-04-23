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
    'sign_in': 'Se connecter',
    'sign_up': 'S\'inscrire',
    'sign_out': 'Se déconnecter',
    'email': 'Email',
    'password': 'Mot de passe',
    'tickets': 'Tickets',
    'search_tickets': 'Rechercher un ticket',
    'scan': 'Scanner',
    'profile': 'Profil',
    'home': 'Accueil',
    'quick_search': 'Recherche rapide',
    'search_hint': 'Tapez un nom de magasin...',
    'recent_searches': 'Recherches récentes',
    'no_recent_searches': 'Aucune recherche récente',
    'my_tickets': 'Mes Tickets',
    'no_tickets': 'Aucun ticket enregistré',
    'ticket_details': 'Détails du ticket',
    'store_name': 'Magasin',
    'date': 'Date d\'achat',
    'total_amount': 'Montant total',
    'products': 'Articles',
    'warranty': 'Garantie',
    'warranty_end_date': 'Fin de garantie',
    'warranty_expiring': 'Expire bientôt',
    'warranty_expired': 'Expiré',
    'settings': 'Paramètres',
    'dark_mode': 'Thème',
    'language': 'Langue',
    'privacy_policy': 'Confidentialité',
    'about': 'À propos',
    'contact_support': 'Contacter le support',
    'delete_account': 'Supprimer le compte',
    'delete_account_warning': 'Action irréversible. Vos données seront supprimées.',
    'upgrade_premium': 'Passer au Premium',
    'premium_banner_msg': 'Débloquez les scans illimités et l\'export PDF !',
    'premium_plan': 'Version Premium',
    'cloud_sync': 'Synchronisation Cloud',
    'auto_categorization': 'Catégorisation IA',
    'premium_support': 'Support Prioritaire',
    'best_value': 'Meilleure Offre',
    'unlimited_scans': 'Scans illimités',
    'monthly_limit': 'Limite de 10 scans/mois',
    'scans_count': 'Scans ce mois',
    'monthly': 'Mensuel',
    'yearly': 'Annuel',
    'premium_unlock_msg': 'Débloquez toute la puissance de TicketScan',
    'later': 'Plus tard',
    'per_month': '/ mois',
    'per_year': '/ an',
    'unlimited': 'ILLIMITÉ',
  };

  static const Map<String, String> _en = {
    'app_name': 'TicketScan',
    'ok': 'OK',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'search': 'Search',
    'sign_in': 'Sign in',
    'sign_up': 'Sign up',
    'sign_out': 'Sign out',
    'email': 'Email',
    'password': 'Password',
    'tickets': 'Tickets',
    'search_tickets': 'Search a ticket',
    'scan': 'Scan',
    'profile': 'Profile',
    'home': 'Home',
    'quick_search': 'Quick search',
    'search_hint': 'Type a store name...',
    'recent_searches': 'Recent searches',
    'no_recent_searches': 'No recent searches',
    'my_tickets': 'My Tickets',
    'no_tickets': 'No tickets saved',
    'ticket_details': 'Ticket details',
    'store_name': 'Store',
    'date': 'Purchase date',
    'total_amount': 'Total amount',
    'products': 'Products',
    'warranty': 'Warranty',
    'warranty_end_date': 'Warranty end date',
    'warranty_expiring': 'Expiring soon',
    'warranty_expired': 'Expired',
    'settings': 'Settings',
    'dark_mode': 'Theme',
    'language': 'Language',
    'privacy_policy': 'Privacy Policy',
    'about': 'About',
    'contact_support': 'Contact support',
    'delete_account': 'Delete account',
    'delete_account_warning': 'Irreversible action. Your data will be deleted.',
    'upgrade_premium': 'Upgrade to Premium',
    'premium_banner_msg': 'Unlock unlimited scans and PDF export!',
    'premium_plan': 'Premium Version',
    'cloud_sync': 'Cloud Synchronization',
    'auto_categorization': 'AI Categorization',
    'premium_support': 'Priority Support',
    'best_value': 'Best Value',
    'unlimited_scans': 'Unlimited scans',
    'monthly_limit': '10 scans/month limit',
    'scans_count': 'Scans this month',
    'monthly': 'Monthly',
    'yearly': 'Yearly',
    'premium_unlock_msg': 'Unlock the full power of TicketScan',
    'later': 'Later',
    'per_month': '/ month',
    'per_year': '/ year',
    'unlimited': 'UNLIMITED',
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
