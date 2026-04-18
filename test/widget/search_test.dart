import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketscan_new/presentation/pages/search_page.dart';
import 'package:ticketscan_new/core/services/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  testWidgets('SearchPage input field is usable', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr', 'FR'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: SearchPage(),
      ),
    );

    // Attendre que la page soit stable
    await tester.pumpAndSettle();

    // Trouver le TextField par son type (on force un rafraîchissement si besoin)
    final Finder textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    // Simuler la saisie
    await tester.enterText(textFieldFinder, 'Lidl');
    await tester.pump();

    // Vérifier que le texte a bien été saisi
    expect(find.text('Lidl'), findsOneWidget);
  });
}
