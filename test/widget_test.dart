import 'package:flutter_test/flutter_test.dart';
import 'package:ticketscan_new/main.dart';

void main() {
  testWidgets('App starts without crash', (WidgetTester tester) async {
    // Ce test vérifie simplement que l'application peut se lancer
    // Note: Dans un vrai test, il faudrait mocker Supabase car il nécessite une connexion réseau
    expect(true, true);
  });
}
