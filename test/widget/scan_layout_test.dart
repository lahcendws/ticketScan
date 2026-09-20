import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ticketscan_new/core/services/subscription_service.dart';
import 'package:ticketscan_new/data/models/ticket_provider.dart';
import 'package:ticketscan_new/presentation/pages/scan_page.dart';

void main() {
  testWidgets('bottom controls fit a narrow screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(225, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: SubscriptionService.internal()),
          ChangeNotifierProvider.value(value: TicketProvider()),
        ],
        child: const MaterialApp(
          home: ScanPage(initialImagePath: 'unused.jpg'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    final button = tester.renderObject<RenderBox>(find.byType(ElevatedButton));
    RenderObject? current = button.parent;
    while (current != null && current is! RenderFlex) {
      current = current.parent;
    }

    expect(current, isA<RenderFlex>());
    final controlsRow = current! as RenderFlex;
    expect(
      controlsRow.size.width,
      lessThanOrEqualTo(controlsRow.constraints.maxWidth),
    );
  });
}
