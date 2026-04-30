import 'package:flutter_test/flutter_test.dart';
import 'package:ticketscan_new/core/services/subscription_service.dart';
import 'package:ticketscan_new/data/models/ticket_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriptionService Logic Tests', () {
    late SubscriptionService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = SubscriptionService.internal(); 
      await service.init(isTest: true); 
    });

    test('Initial logic should be free', () {
      expect(service.isPremium, false);
    });

    test('Free limit should be 3', () {
      expect(service.freeLimit, 3);
    });

    test('canScan should be true when less than 3 total tickets exist', () {
      final now = DateTime.now();
      
      final tickets = [
        TicketModel(storeName: 'A', date: now, totalAmount: 10, currency: '€', products: [], imageUrls: [], warrantyEndDate: now.add(const Duration(days: 365)), createdAt: now),
        TicketModel(storeName: 'B', date: now, totalAmount: 10, currency: '€', products: [], imageUrls: [], warrantyEndDate: now.add(const Duration(days: 365)), createdAt: now),
      ];

      expect(service.canScan(tickets), isTrue);
    });

    test('canScan should be false when 3 total tickets exist', () {
      final now = DateTime.now();
      
      final tickets = [
        TicketModel(storeName: 'A', date: now, totalAmount: 10, currency: '€', products: [], imageUrls: [], warrantyEndDate: now.add(const Duration(days: 365)), createdAt: now),
        TicketModel(storeName: 'B', date: now, totalAmount: 10, currency: '€', products: [], imageUrls: [], warrantyEndDate: now.add(const Duration(days: 365)), createdAt: now),
        TicketModel(storeName: 'C', date: now, totalAmount: 10, currency: '€', products: [], imageUrls: [], warrantyEndDate: now.add(const Duration(days: 365)), createdAt: now),
      ];

      expect(service.canScan(tickets), isFalse);
    });

    test('canScan should count expired tickets too (total limit rule)', () {
      final now = DateTime.now();
      
      final tickets = [
        TicketModel(storeName: 'A', date: now, totalAmount: 10, currency: '€', products: [], imageUrls: [], warrantyEndDate: now.add(const Duration(days: 365)), createdAt: now),
        TicketModel(storeName: 'B', date: now, totalAmount: 10, currency: '€', products: [], imageUrls: [], warrantyEndDate: now.subtract(const Duration(days: 1)), createdAt: now),
        TicketModel(storeName: 'C', date: now, totalAmount: 10, currency: '€', products: [], imageUrls: [], warrantyEndDate: now.subtract(const Duration(days: 1)), createdAt: now),
      ];

      // Même expirés, les 3 tickets bloquent le scan (règle stricte)
      expect(service.canScan(tickets), isFalse);
    });
  });
}
