import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class OCRService {
  static final _supabase = Supabase.instance.client;

  static Future<TicketAnalysis> extractTextFromImages(List<String> imagePaths) async {
    try {
      // Convertir toutes les images en Base64
      List<String> base64Images = [];
      for (String path in imagePaths) {
        final bytes = await File(path).readAsBytes();
        base64Images.add(base64Encode(bytes));
      }

      // Appeler la fonction avec le tableau d'images
      final response = await _supabase.functions.invoke(
        'analyze-ticket',
        body: {'imagesBase64': base64Images},
      );

      if (response.status == 200) {
        final dynamic data = response.data;
        Map<String, dynamic> content = (data is String) ? jsonDecode(data) : Map<String, dynamic>.from(data);

        return TicketAnalysis(
          storeName: content['storeName']?.toString() ?? 'Magasin',
          storeAddress: content['storeAddress']?.toString(),
          category: content['category']?.toString() ?? 'Électronique',
          date: DateTime.tryParse(content['date']?.toString() ?? '') ?? DateTime.now(),
          totalAmount: double.tryParse(content['totalAmount']?.toString() ?? '0') ?? 0.0,
          currency: content['currency']?.toString() ?? '€',
          products: (content['products'] as List?)?.map((p) => Map<String, dynamic>.from(p)).toList() ?? [],
          extractedText: [],
          // On prend la garantie la plus longue trouvée dans les produits
          warrantyYears: 2,
        );
      }
      throw Exception('Erreur serveur: ${response.status}');
    } catch (e) {
      throw Exception('Erreur analyse multi-images: $e');
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
