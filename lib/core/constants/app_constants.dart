class AppConstants {
  // Informations de l'application
  static const String appName = 'TicketScan';
  static const String appVersion = '1.0.0';
  
  // Configuration Firebase
  static const String firebaseProjectId = 'ticketscan-flutter';
  static const String firebaseStorageBucket = 'ticketscan-flutter.appspot.com';
  
  // Préférences utilisateur
  static const String prefThemeMode = 'theme_mode';
  static const String prefLanguage = 'language';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefWarrantyNotifications = 'warranty_notifications';
  
  // Durées par défaut
  static const int defaultWarrantyYears = 2;
  static const int warrantyNotificationDays = 30;
  
  // Limites
  static const int maxTicketsPerPage = 20;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  
  // Patterns pour l'OCR
  static const List<String> commonStoreNames = [
    'CARREFOUR', 'LECLERC', 'AUCHAN', 'MONOPRIX', 'CASINO', 
    'INTERMARCHE', 'GEANT', 'LIDL', 'ALDI', 'SPAR',
    'FNAC', 'DARTY', 'BOULANGER', 'MEDIAMARKT', 'CDISCOUNT'
  ];
  
  static const List<String> totalKeywords = [
    'TOTAL', 'MONTANT', 'SOMME', 'A PAYER', 'REGLEMENT', 'PAYE'
  ];
  
  // Messages d'erreur
  static const String errorMessageGeneric = 'Une erreur est survenue. Veuillez réessayer.';
  static const String errorMessageNetwork = 'Erreur de connexion. Vérifiez votre internet.';
  static const String errorMessageCamera = 'Erreur d\'accès à la caméra.';
  static const String errorMessageStorage = 'Erreur de stockage.';
  
  // Messages de succès
  static const String successMessageTicketSaved = 'Ticket enregistré avec succès!';
  static const String successMessageTicketDeleted = 'Ticket supprimé avec succès!';
  static const String successMessageImageUploaded = 'Image téléchargée avec succès!';
  
  // URLs
  static const String privacyPolicyUrl = 'https://ticketscan.app/privacy';
  static const String termsOfServiceUrl = 'https://ticketscan.app/terms';
  static const String supportUrl = 'https://ticketscan.app/support';
  
  // Animation durations
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);
  
  // Débogage
  static const bool enableDebugLogs = true;
  static const String logTag = 'TicketScan';
}
