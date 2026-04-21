import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';

class VersionService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>?> checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await _supabase
          .from('app_config')
          .select()
          .maybeSingle();

      if (response == null) return null;

      final minVersion = response['min_version'] as String;

      return {
        'needsUpdate': isUpdateRequired(currentVersion, minVersion),
        'maintenance': response['is_under_maintenance'] ?? false,
        'url': response['update_url'] ?? '',
      };
    } catch (e) {
      debugPrint('Version check error: $e');
      return null;
    }
  }

  // MÉTHODE ISOLÉE POUR LES TESTS
  static bool isUpdateRequired(String currentVersion, String minVersion) {
    try {
      List<int> currentParts = currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> minParts = minVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        int curr = i < currentParts.length ? currentParts[i] : 0;
        int min = i < minParts.length ? minParts[i] : 0;
        if (curr < min) return true;
        if (curr > min) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
