import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketscan_new/core/services/app_localizations.dart';
import 'package:ticketscan_new/presentation/widgets/bottom_navigation.dart';
import 'layout_overflow_helper.dart';

void main() {
  for (final width in const [225.0, 180.0]) {
    testWidgets('bottom navigation fits a ${width.toInt()} pixel screen', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr', 'FR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigation(
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CustomBottomNavigation), findsOneWidget);
      expectNoHorizontalOverflow(
        tester,
        label: 'bottom navigation at ${width.toInt()} pixels',
      );
    });
  }
}
