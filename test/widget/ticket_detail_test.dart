import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketscan_new/presentation/pages/ticket_detail_page.dart';
import 'package:ticketscan_new/data/models/ticket_model.dart';
import 'package:ticketscan_new/core/services/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:ticketscan_new/core/services/language_service.dart';
import 'package:ticketscan_new/core/services/subscription_service.dart';
import 'package:ticketscan_new/data/models/ticket_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  testWidgets('TicketDetailPage displays products cleanly (no braces)', (WidgetTester tester) async {
    final testTicket = TicketModel(
      id: '123',
      storeName: 'BOULANGER',
      date: DateTime.now(),
      totalAmount: 150.0,
      currency: '€',
      products: [
        {'name': 'Aspirateur', 'price': '150.00', 'hasWarranty': true}
      ],
      imageUrls: [],
      warrantyEndDate: DateTime.now().add(const Duration(days: 365)),
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageService()),
          ChangeNotifierProvider(create: (_) => SubscriptionService()),
          ChangeNotifierProvider(create: (_) => TicketProvider()),
        ],
        child: MaterialApp(
          locale: const Locale('fr', 'FR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: TicketDetailPage(ticket: testTicket),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Vérifier que le nom du produit est affiché seul
    expect(find.text('Aspirateur'), findsOneWidget);
    
    // Vérifier qu'il n'y a PAS d'accolades dans l'affichage du produit
    expect(find.textContaining('{'), findsNothing);
  });
}
