import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class LanguageService {
  static Locale _currentLocale = const Locale('fr', 'FR');

  static Locale get currentLocale => _currentLocale;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(AppConstants.prefLanguage);

      if (savedLanguage != null) {
        switch (savedLanguage) {
          case 'en':
            _currentLocale = const Locale('en', 'US');
            break;
          case 'fr':
          default:
            _currentLocale = const Locale('fr', 'FR');
        }
      }
    } catch (e) {
      print('Erreur initialisation langue: $e');
    }
  }

  static Future<void> setLanguage(Locale locale) async {
    _currentLocale = locale;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefLanguage, locale.languageCode);
    } catch (e) {
      print('Erreur sauvegarde langue: $e');
    }
  }

  static String getLanguageDisplayText() {
    switch (_currentLocale.languageCode) {
      case 'en':
        return 'English';
      case 'fr':
      default:
        return 'Français';
    }
  }

  static List<Locale> get supportedLocales => [
    const Locale('fr', 'FR'),
    const Locale('en', 'US'),
  ];
}
