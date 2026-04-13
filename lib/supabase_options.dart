// Configuration Supabase pour remplacer Firebase
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseOptions {
  static String supabaseUrl = dotenv.env['SUPA_BASE_URL']!;
  static String supabaseAnonKey = dotenv.env['SUPA_BASE_ANON_KEY']!;

  static String get currentUrl => supabaseUrl;
  static String get currentAnonKey => supabaseAnonKey;
}
