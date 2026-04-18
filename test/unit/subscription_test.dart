import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketscan_new/core/services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Initialisation du lien avec les services Flutter pour les tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriptionService Logic Tests', () {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/in_app_purchase');

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      
      // On intercepte les appels au plugin In-App Purchase pour éviter les crashs de connexion
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return null; // On simule une réponse vide (succès)
      });
      
      // On intercepte aussi le canal Pigeon (Android spécifique) qui cause l'erreur
      const MethodChannel pigeonChannel = MethodChannel('dev.flutter.pigeon.in_app_purchase_android.InAppPurchaseApi.startConnection');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pigeonChannel, (MethodCall methodCall) async {
        return null;
      });
    });

    test('Initial logic should be free with 0 scans', () {
      final service = SubscriptionService();
      
      expect(service.isPremium, false);
      expect(service.scansThisMonth, 0);
      expect(service.canScan, true);
    });

    test('Free limit should be 10', () {
      final service = SubscriptionService();
      expect(service.freeLimit, 10);
    });
  });
}
