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
    'settings': 'Paramètres',
    'privacy_policy': 'Politique de confidentialité',
    'about': 'À propos',
    'upgrade_premium': 'Passer au Premium',
    'premium_plan': 'Version Premium',
    'best_value_badge': 'Meilleure valeur',
    'unlimited_scans': 'Scans illimités',
    'monthly_limit': 'Limite de 3 tickets atteinte.',
    'later': 'Plus tard',
    'per_month': '/ Mois',
    'per_year': '/ An',
    'limit_reached_msg': 'Vous avez utilisé vos 3 tickets gratuits.',
    'limit_reached_sub': 'Votre accès est limité. Abonnez-vous dès maintenant pour bénéficier d\'un accès complet.',
    'subscribe': 'Souscrire',
    'terms_of_service': 'Conditions d\'utilisation',
    'premium_yearly_detail': 'Abonnement annuel',
    'premium_monthly_detail': 'Abonnement mensuel',
    'manage_unlimited': 'Gérez tous vos tickets sans limite',
    'live_env': 'Environnement en direct',
    'premium_banner_msg': 'Passez à la version Premium',
    'contact_support': 'Contacter le support',
    'delete_account': 'Supprimer mon compte',
    'delete_account_warning': 'Attention : cette action est irréversible. Toutes vos données seront supprimées.',
    'dark_mode': 'Mode sombre',
    'language': 'Langue',
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
    'settings': 'Settings',
    'privacy_policy': 'Privacy Policy',
    'about': 'About',
    'upgrade_premium': 'Upgrade to Premium',
    'premium_plan': 'Premium Version',
    'best_value_badge': 'Best value',
    'unlimited_scans': 'Unlimited scans',
    'monthly_limit': '3 tickets limit reached.',
    'later': 'Later',
    'per_month': '/ Month',
    'per_year': '/ Year',
    'limit_reached_msg': 'You have used your 3 free tickets.',
    'limit_reached_sub': 'Your access is limited. Subscribe now to enjoy full access.',
    'subscribe': 'Subscribe',
    'terms_of_service': 'Terms of Service',
    'premium_yearly_detail': 'Yearly subscription',
    'premium_monthly_detail': 'Monthly subscription',
    'manage_unlimited': 'Manage all your tickets without limit',
    'live_env': 'Live environment',
    'premium_banner_msg': 'Upgrade to Premium version',
    'contact_support': 'Contact Support',
    'delete_account': 'Delete my account',
    'delete_account_warning': 'Warning: this action is irreversible. All your data will be deleted.',
    'dark_mode': 'Dark mode',
    'language': 'Language',
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
