import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketscan_new/presentation/widgets/ticket_card.dart';
import 'package:ticketscan_new/data/models/ticket_model.dart';
import 'package:ticketscan_new/core/services/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:ticketscan_new/core/services/language_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  testWidgets('TicketCard displays store name and amount correctly', (WidgetTester tester) async {
    final testTicket = TicketModel(
      storeName: 'CARREFOUR',
      date: DateTime(2024, 1, 1),
      totalAmount: 45.50,
      products: [],
      imageUrls: [],
      warrantyEndDate: DateTime(2026, 1, 1),
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageService()),
        ],
        child: MaterialApp(
          locale: const Locale('fr', 'FR'),
          supportedLocales: const [Locale('fr', 'FR')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates, // Utilise la liste complète (Material + Cupertino + Widgets)
          ],
          home: Scaffold(
            body: TicketCard(ticket: testTicket),
          ),
        ),
      ),
    );

    // On laisse le temps aux widgets de se construire
    await tester.pump();

    // Vérifier que le nom du magasin est présent
    expect(find.text('CARREFOUR'), findsOneWidget);
    
    // Vérifier que le montant est présent (le formatage peut varier selon la locale, on cherche la partie fixe)
    expect(find.textContaining('45.50'), findsOneWidget);
  });
}
