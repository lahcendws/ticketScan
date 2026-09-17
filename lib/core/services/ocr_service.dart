import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Exceptions dédiées, pour que l'UI puisse réagir différemment ----------

class NotAReceiptException implements Exception {
  final String reason;
  NotAReceiptException(this.reason);

  @override
  String toString() =>
      "Cette photo ne semble pas montrer un ticket de caisse ($reason).";
}

class QuotaExceededException implements Exception {
  @override
  String toString() => "Limite de scans gratuits atteinte.";
}

class ScanTechnicalException implements Exception {
  final String message;
  ScanTechnicalException(this.message);

  @override
  String toString() => message;
}

class OCRService {
  static final _supabase = Supabase.instance.client;

  static Future<TicketAnalysis> extractTextFromImages(
      List<String> imagePaths,
      ) async {
    List<String> base64Images = [];
    for (String path in imagePaths) {
      final bytes = await File(path).readAsBytes();
      base64Images.add(base64Encode(bytes));
    }

    try {
      final response = await _supabase.functions.invoke(
        'scan-receipt-v2',
        body: {'imagesBase64': base64Images},
      );

      final dynamic data = response.data;
      final Map<String, dynamic> content = (data is String)
          ? jsonDecode(data) as Map<String, dynamic>
          : Map<String, dynamic>.from(data as Map);

      return _parseAnalysis(content);
    } on FunctionException catch (e) {
      // DEBUG temporaire : à retirer une fois le flux validé
      // ignore: avoid_print
      print('FunctionException status=${e.status} details=${e.details} (${e.details.runtimeType})');

      final details = e.details;
      final Map<String, dynamic>? body = details is String
          ? (jsonDecode(details) as Map<String, dynamic>?)
          : (details is Map ? Map<String, dynamic>.from(details) : null);

      final code = body?['error']?.toString();

      switch (e.status) {
        case 422:
          throw NotAReceiptException(body?['reason']?.toString() ?? 'unknown');
        case 403:
          if (code == 'LIMIT_REACHED') throw QuotaExceededException();
          throw ScanTechnicalException('Accès refusé');
        case 400:
          throw ScanTechnicalException(code ?? 'Requête invalide');
        case 502:
          throw ScanTechnicalException('Service de reconnaissance indisponible, réessaie dans un instant');
        default:
          throw ScanTechnicalException('Erreur serveur (${e.status})');
      }
    } on NotAReceiptException {
      rethrow;
    } on QuotaExceededException {
      rethrow;
    } catch (e) {
      throw ScanTechnicalException('Erreur analyse multi-images: $e');
    }
  }

  static TicketAnalysis _parseAnalysis(Map<String, dynamic> content) {
    final products = (content['products'] as List?)
        ?.map((p) => Map<String, dynamic>.from(p as Map))
        .toList() ??
        [];

    // La garantie est portée par chaque produit, pas par un champ global.
    // On prend la durée max déclarée parmi les produits sous garantie,
    // à défaut 2 ans si au moins un produit est concerné, sinon 0.
    final warrantedDurations = products
        .where((p) => p['hasWarranty'] == true)
        .map((p) => int.tryParse(p['warrantyDurationYears']?.toString() ?? '') ?? 2)
        .toList();
    final warrantyYears = warrantedDurations.isEmpty
        ? 0
        : warrantedDurations.reduce((a, b) => a > b ? a : b);

    return TicketAnalysis(
      storeName: content['storeName']?.toString() ?? 'Magasin',
      storeAddress: content['storeAddress']?.toString(),
      category: content['category']?.toString() ?? 'Autre',
      date: DateTime.tryParse(content['date']?.toString() ?? '') ?? DateTime.now(),
      totalAmount: double.tryParse(content['totalAmount']?.toString() ?? '0') ?? 0.0,
      currency: content['currency']?.toString() ?? '€',
      products: products,
      extractedText: const [],
      warrantyYears: warrantyYears,
      needsConfirmation: content['needsConfirmation'] == true,
    );
  }
}

class TicketAnalysis {
  final String storeName;
  final String? storeAddress;
  final String category;
  final DateTime date;
  final double totalAmount;
  final String currency;
  final List<Map<String, dynamic>> products;
  final List<String> extractedText;
  final int warrantyYears;
  final bool needsConfirmation;

  TicketAnalysis({
    required this.storeName,
    this.storeAddress,
    required this.category,
    required this.date,
    required this.totalAmount,
    required this.currency,
    required this.products,
    required this.extractedText,
    required this.warrantyYears,
    this.needsConfirmation = false,
  });
}