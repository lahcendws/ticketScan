import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ThemeService {
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static ThemeMode get themeMode => themeModeNotifier.value;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(AppConstants.prefThemeMode);
      
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            themeModeNotifier.value = ThemeMode.light;
            break;
          case 'dark':
            themeModeNotifier.value = ThemeMode.dark;
            break;
          default:
            themeModeNotifier.value = ThemeMode.system;
        }
      }
    } catch (e) {
      print('Erreur initialisation thème: $e');
    }
  }

  static Future<void> setThemeMode(ThemeMode themeMode) async {
    themeModeNotifier.value = themeMode;
    
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
    switch (themeModeNotifier.value) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      default:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }

  static String getThemeModeString() {
    switch (themeModeNotifier.value) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      default:
        return 'Système';
    }
  }
}
