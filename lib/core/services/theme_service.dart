import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ThemeService {
  static ThemeMode _themeMode = ThemeMode.system;

  static ThemeMode get themeMode => _themeMode;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(AppConstants.prefThemeMode);
      
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          default:
            _themeMode = ThemeMode.system;
        }
      }
    } catch (e) {
      print('Erreur initialisation thème: $e');
    }
  }

  static Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString;
      
      switch (themeMode) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        default:
          themeString = 'system';
      }
      
      await prefs.setString(AppConstants.prefThemeMode, themeString);
    } catch (e) {
      print('Erreur sauvegarde thème: $e');
    }
  }

  static bool isDarkMode(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      default:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }

  static String getThemeModeString() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      default:
        return 'Système';
    }
  }
}
