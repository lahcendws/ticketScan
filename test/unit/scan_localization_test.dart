import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketscan_new/core/services/app_localizations.dart';
import 'package:ticketscan_new/core/services/ocr_service.dart';

void main() {
  group('Scan error localization', () {
    final french = AppLocalizations(const Locale('fr', 'FR'));
    final english = AppLocalizations(const Locale('en', 'US'));

    test('provides French and English scan error messages', () {
      const translations = {
        'scan_error_title': ('Erreur de scan', 'Scan error'),
        'scan_not_a_receipt': (
          'Cette photo ne semble pas montrer un ticket de caisse. Réessaie en cadrant bien le ticket, à plat et bien éclairé.',
          'This photo does not appear to show a receipt. Try again with the receipt fully in frame, flat, and well lit.',
        ),
        'scan_access_denied': ('Accès refusé', 'Access denied'),
        'scan_invalid_request': ('Requête invalide', 'Invalid request'),
        'scan_service_unavailable': (
          'Service de reconnaissance indisponible, réessaie dans un instant',
          'Recognition service unavailable. Please try again in a moment.',
        ),
        'scan_server_error': ('Erreur serveur', 'Server error'),
        'scan_multi_image_error': (
          'Erreur lors de l’analyse de plusieurs images',
          'Error analyzing multiple images.',
        ),
        'scan_technical_error': (
          'Une erreur technique est survenue pendant le scan.',
          'A technical error occurred during the scan.',
        ),
        'scan_unexpected_error': (
          'Une erreur inattendue est survenue.',
          'An unexpected error occurred.',
        ),
        'scan_save_error': (
          'Impossible d’enregistrer le ticket. Réessaie.',
          'Unable to save the receipt. Please try again.',
        ),
        'scan_quota_exceeded': (
          'Limite de scans gratuits atteinte.',
          'Free scan limit reached.',
        ),
      };

      for (final entry in translations.entries) {
        expect(french.get(entry.key), entry.value.$1);
        expect(english.get(entry.key), entry.value.$2);
      }
    });

    test('OCR exceptions expose stable localization keys', () {
      expect(
        NotAReceiptException('invalid image').messageKey,
        'scan_not_a_receipt',
      );
      expect(QuotaExceededException().messageKey, 'scan_quota_exceeded');
      expect(
        ScanTechnicalException(
          'access_denied',
          messageKey: 'scan_access_denied',
        ).messageKey,
        'scan_access_denied',
      );
    });
  });
}
