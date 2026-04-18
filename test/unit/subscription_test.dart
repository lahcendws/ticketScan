import 'package:flutter_test/flutter_test.dart';
import 'package:ticketscan_new/core/services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // CRUCIAL : Initialise l'environnement Flutter pour les tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriptionService Logic Tests', () {
    setUp(() {
      // Simule les SharedPreferences pour le test
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial logic should be free with 0 scans', () {
      // Comme c'est un singleton, on y accède via la factory
      final service = SubscriptionService();
      
      // On vérifie que les valeurs de départ sont correctes
      expect(service.isPremium, false);
      expect(service.scansThisMonth, 0);
      expect(service.canScan, true);
    });

    test('Free limit should be exactly 10', () {
      final service = SubscriptionService();
      expect(service.freeLimit, 10);
    });
  });
}
