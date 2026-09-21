import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ticketscan_new/core/services/subscription_service.dart';
import 'package:ticketscan_new/data/models/ticket_provider.dart';
import 'package:ticketscan_new/presentation/pages/scan_page.dart';
import 'layout_overflow_helper.dart';

void main() {
  for (final width in const [225.0, 180.0]) {
    testWidgets('bottom controls fit a ${width.toInt()} pixel screen', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 600));
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

      expectNoHorizontalOverflow(
        tester,
        label: 'scan page at ${width.toInt()} pixels',
      );
    });
  }
}
