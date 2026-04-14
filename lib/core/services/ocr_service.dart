import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class OCRService {
  static final _supabase = Supabase.instance.client;

  static Future<TicketAnalysis> extractTextFromImage(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await _supabase.functions.invoke(
        'analyze-ticket',
        body: {'imageBase64': base64Image},
      );

      if (response.status == 200) {
        final dynamic data = response.data;
        Map<String, dynamic> content = (data is String) ? jsonDecode(data) : Map<String, dynamic>.from(data);

        return TicketAnalysis(
          storeName: content['storeName']?.toString() ?? 'Magasin',
          storeAddress: content['storeAddress']?.toString(),
          category: content['category']?.toString() ?? 'Alimentation',
          date: DateTime.tryParse(content['date']?.toString() ?? '') ?? DateTime.now(),
          totalAmount: double.tryParse(content['totalAmount']?.toString() ?? '0') ?? 0.0,
          currency: content['currency']?.toString() ?? '€',
          products: (content['products'] as List?)?.map((p) => Map<String, dynamic>.from(p)).toList() ?? [],
          extractedText: [],
          warrantyYears: 2,
        );
      }
      throw Exception('Erreur serveur: ${response.status}');
    } catch (e) {
      throw Exception('Erreur analyse: $e');
    }
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
  });
}
