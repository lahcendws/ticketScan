import 'package:flutter_test/flutter_test.dart';
import 'package:ticketscan_new/core/services/ticket_share_service.dart';
import 'package:ticketscan_new/data/models/ticket_model.dart';

void main() {
  final ticket = TicketModel(
    storeName: 'CARREFOUR',
    date: DateTime(2026, 9, 11),
    totalAmount: 45.5,
    currency: '€',
    products: [
      {'name': 'Cafetière', 'price': '45.50', 'hasWarranty': true},
    ],
    imageUrls: [],
    warrantyEndDate: DateTime(2028, 9, 11),
    createdAt: DateTime(2026, 9, 11),
  );

  test('builds a complete French share message', () {
    final message = TicketShareService.buildMessage(ticket);

    expect(message, contains('Magasin : CARREFOUR'));
    expect(message, contains('Date d\'achat : 11/09/2026'));
    expect(message, contains('Montant total : 45.50 €'));
    expect(message, contains('Fin de garantie : 11/09/2028'));
    expect(message, contains('Cafetière : 45.50 €'));
  });

  test('builds an English share message', () {
    final message = TicketShareService.buildMessage(ticket, locale: 'en_US');

    expect(message, contains('Store : CARREFOUR'));
    expect(message, contains('Purchase date : 11/09/2026'));
    expect(message, contains('Total amount : 45.50 €'));
    expect(message, contains('Warranty end date : 11/09/2028'));
    expect(message, contains('Products'));
  });
}
