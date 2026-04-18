import 'package:flutter_test/flutter_test.dart';
import 'package:ticketscan_new/data/models/ticket_model.dart';

void main() {
  group('TicketModel Logic Tests', () {
    test('isWarrantyExpired should return true if date is in the past', () {
      final ticket = TicketModel(
        storeName: 'Test Store',
        date: DateTime.now().subtract(const Duration(days: 400)),
        totalAmount: 10.0,
        products: [],
        imageUrls: [],
        warrantyEndDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
      );

      expect(ticket.isWarrantyExpired(), true);
    });

    test('isWarrantyExpiringSoon should return true if expiry is within 30 days', () {
      final ticket = TicketModel(
        storeName: 'Test Store',
        date: DateTime.now(),
        totalAmount: 10.0,
        products: [],
        imageUrls: [],
        warrantyEndDate: DateTime.now().add(const Duration(days: 15)),
        createdAt: DateTime.now(),
      );

      expect(ticket.isWarrantyExpiringSoon(), true);
    });

    test('TicketModel.fromMap should handle malformed image_urls string', () {
      final map = {
        'store_name': 'LIDL',
        'total_amount': 20.5,
        'image_urls': '["https://test.com/photo.jpg"]', // Format texte JSON
        'date': '2024-01-01T00:00:00.000Z',
        'warranty_end_date': '2026-01-01T00:00:00.000Z',
        'products': [{'name': 'Lait', 'price': '1.20'}],
      };

      final ticket = TicketModel.fromMap(map);
      
      expect(ticket.imageUrls.length, 1);
      expect(ticket.imageUrls.first, 'https://test.com/photo.jpg');
    });
  });
}
