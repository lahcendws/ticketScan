// Configuration Supabase pour remplacer Firebase
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseOptions {
  static String supabaseUrl = dotenv.env['SUPABASE_URL']!;
  static String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;

  static String get currentUrl => supabaseUrl;
  static String get currentAnonKey => supabaseAnonKey;
}
