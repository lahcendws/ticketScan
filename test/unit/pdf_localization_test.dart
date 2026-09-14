import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ticketscan_new/core/services/app_localizations.dart';

void main() {
  test('PDF labels are available in French and English', () {
    final french = AppLocalizations(const Locale('fr', 'FR'));
    final english = AppLocalizations(const Locale('en', 'US'));

    expect(french.get('pdf_warranty_certificate'), 'ATTESTATION DE GARANTIE');
    expect(english.get('pdf_warranty_certificate'), 'WARRANTY CERTIFICATE');
    expect(french.get('pdf_purchase_proof'), "PREUVE D'ACHAT (PHOTO)");
    expect(english.get('pdf_purchase_proof'), 'PROOF OF PURCHASE (PHOTO)');
    expect(french.get('pdf_warrantied'), 'Garanti');
    expect(english.get('pdf_warrantied'), 'Warrantied');
  });
}
