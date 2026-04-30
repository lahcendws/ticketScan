import 'package:flutter_test/flutter_test.dart';
import 'package:ticketscan_new/core/services/version_service.dart';

void main() {
  group('VersionService Logic Tests', () {
    test('isUpdateRequired should detect lower major version', () {
      expect(VersionService.isUpdateRequired('1.5.0', '2.0.0'), true);
    });

    test('isUpdateRequired should detect lower minor version', () {
      expect(VersionService.isUpdateRequired('1.1.0', '1.2.0'), true);
    });

    test('isUpdateRequired should detect lower patch version', () {
      expect(VersionService.isUpdateRequired('1.0.5', '1.0.10'), true);
    });

    test('isUpdateRequired should allow higher or equal versions', () {
      expect(VersionService.isUpdateRequired('1.1.0', '1.1.0'), false);
      expect(VersionService.isUpdateRequired('2.0.1', '1.9.9'), false);
    });

    test('Malformed version strings should fail safely', () {
      expect(VersionService.isUpdateRequired('abc', '1.0.0'), true);
    });
  });

  group('Maintenance Mode Simulation', () {
    test('Should detect maintenance flag from mock data', () {
      // Simulation de la réponse Supabase
      final mockResponse = {
        'min_version': '1.0.0',
        'is_under_maintenance': true,
        'update_url': 'http://test.com'
      };

      final bool isMaintenance = mockResponse['is_under_maintenance'] as bool;
      expect(isMaintenance, true);
    });

    test('Maintenance flag should be false by default if missing', () {
      final mockResponse = {
        'min_version': '1.0.0',
      };
      
      final bool isMaintenance = (mockResponse['is_under_maintenance'] as bool?) ?? false;
      expect(isMaintenance, false);
    });
  });
}
