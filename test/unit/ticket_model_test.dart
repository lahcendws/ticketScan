import 'package:flutter_test/flutter_test.dart';
import 'package:ticketscan_new/data/models/ticket_model.dart';

void main() {
  group('TicketModel Logic & Parsing', () {
    test('isWarrantyExpired should detect past dates', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 365 * 3)); // 3 ans ago
      final ticket = TicketModel(
        storeName: 'Test',
        date: pastDate,
        totalAmount: 10,
        products: [],
        imageUrls: [],
        warrantyEndDate: pastDate.add(const Duration(days: 365 * 2)), // Garantie de 2 ans
        createdAt: DateTime.now(),
      );

      expect(ticket.isWarrantyExpired(), true);
    });

    test('Parsing should handle products as both objects and strings', () {
      final map = {
        'store_name': 'Test',
        'products': [
          {'name': 'Objet 1', 'price': '10.00', 'hasWarranty': true},
          '{"name": "Objet 2", "price": "5.00", "hasWarranty": false}'
        ],
        'image_urls': [],
        'date': DateTime.now().toIso8601String(),
        'total_amount': 15.0,
        'warranty_end_date': DateTime.now().toIso8601String(),
      };

      final ticket = TicketModel.fromMap(map);
      expect(ticket.products.length, 2);
      expect(ticket.products[0]['name'], 'Objet 1');
      expect(ticket.products[1]['name'], 'Objet 2');
    });
  });
}
