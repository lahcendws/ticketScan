import 'package:flutter_test/flutter_test.dart';
import 'package:ticketscan_new/data/models/ticket_provider.dart';

void main() {
  test('rejects updates that remove every warranty product', () async {
    final provider = TicketProvider();

    expect(
      () => provider.updateTicket('ticket-id', {
        'products': [
          {'name': 'Produit', 'price': '10.00', 'hasWarranty': false},
        ],
      }),
      throwsA(isA<StateError>()),
    );
  });
}
