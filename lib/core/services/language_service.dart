import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  Locale _currentLocale = const Locale('fr', 'FR');

  Locale get currentLocale => _currentLocale;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(AppConstants.prefLanguage);

      if (savedLanguage != null) {
        _currentLocale = Locale(savedLanguage);
      }
    } catch (e) {
      debugPrint('Erreur initialisation langue: $e');
    }
    notifyListeners();
  }

  Future<void> setLanguage(Locale locale) async {
    if (_currentLocale == locale) return;
    
    _currentLocale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefLanguage, locale.languageCode);
    } catch (e) {
      debugPrint('Erreur sauvegarde langue: $e');
    }
  }

  String getLanguageDisplayText() {
    switch (_currentLocale.languageCode) {
      case 'en':
        return 'English';
      case 'fr':
      default:
        return 'Français';
    }
  }

  List<Locale> get supportedLocales => [
    const Locale('fr', 'FR'),
    const Locale('en', 'US'),
  ];
}
