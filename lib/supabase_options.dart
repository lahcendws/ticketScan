// Configuration Supabase pour remplacer Firebase
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class SupabaseOptions {
  static const String supabaseUrl = 'https://hymtkrhncajixgmamsbt.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh5bXRrcmhuY2FqaXhnbWFtc2J0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwMDUxMTIsImV4cCI6MjA4OTU4MTExMn0.Bf2525ETZ2V-K0rFeY_pWiuJkPWM2wo2X2Aw5GIqM78';
  
  static String get currentUrl => supabaseUrl;
  static String get currentAnonKey => supabaseAnonKey;
}
