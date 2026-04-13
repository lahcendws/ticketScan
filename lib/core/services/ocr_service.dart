import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class OCRService {
  static final _supabase = Supabase.instance.client;

  static Future<TicketAnalysis> extractTextFromImage(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      // Appel de la Supabase Edge Function
      final response = await _supabase.functions.invoke(
        'analyze-ticket',
        body: {'imageBase64': base64Image},
      );

      if (response.status == 200) {
        final content = response.data;

        return TicketAnalysis(
          storeName: content['storeName'] ?? 'Magasin',
          date: DateTime.tryParse(content['date'] ?? '') ?? DateTime.now(),
          totalAmount: (content['totalAmount'] ?? 0.0).toDouble(),
          products: List<String>.from(content['products'] ?? []),
          extractedText: [],
          warrantyYears: 2,
        );
      } else if (response.status == 403) {
        throw Exception('LIMIT_REACHED');
      } else {
        throw Exception('Erreur serveur: ${response.status}');
      }
    } catch (e) {
      if (e.toString().contains('LIMIT_REACHED')) {
        rethrow;
      }
      throw Exception('Erreur lors de l\'analyse: $e');
    }
  }

  static TicketAnalysis analyzeTicketText(String text) {
    return TicketAnalysis(storeName: '', date: DateTime.now(), totalAmount: 0, products: [], extractedText: []);
  }

  static void dispose() {}
}

class TicketAnalysis {
  final String storeName;
  final DateTime date;
  final double totalAmount;
  final List<String> products;
  final List<String> extractedText;
  final int warrantyYears;

  TicketAnalysis({
    required this.storeName,
    required this.date,
    required this.totalAmount,
    required this.products,
    required this.extractedText,
    this.warrantyYears = 2,
  });
}
