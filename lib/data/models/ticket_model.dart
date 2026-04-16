import 'dart:convert';

class TicketModel {
  final String? id;
  final String storeName;
  final String? storeAddress;
  final DateTime date;
  final double totalAmount;
  final String? currency;
  final String? category;
  final List<Map<String, dynamic>> products; 
  final List<String> imageUrls;
  final DateTime warrantyEndDate;
  final List<String> extractedText;
  final DateTime createdAt;

  TicketModel({
    this.id,
    required this.storeName,
    this.storeAddress,
    required this.date,
    required this.totalAmount,
    this.currency = '€',
    this.category = 'Autre',
    required this.products,
    required this.imageUrls,
    required this.warrantyEndDate,
    this.extractedText = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'store_name': storeName,
      'store_address': storeAddress,
      'date': date.toIso8601String(),
      'total_amount': totalAmount,
      'currency': currency,
      'category': category,
      'products': products,
      'image_urls': imageUrls,
      'warranty_end_date': warrantyEndDate.toIso8601String(),
      'extracted_text': extractedText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TicketModel.fromMap(Map<String, dynamic> data) {
    // 1. Gestion robuste des produits
    List<Map<String, dynamic>> parsedProducts = [];
    final rawProducts = data['products'];
    if (rawProducts is List) {
      parsedProducts = rawProducts.map((item) {
        if (item is Map) {
          return Map<String, dynamic>.from(item);
        } else {
          return {'name': item.toString(), 'price': '0.00'};
        }
      }).toList();
    }

    // 2. Gestion robuste des images
    List<String> urls = [];
    if (data['image_urls'] != null) {
      if (data['image_urls'] is List) {
        urls = List<String>.from(data['image_urls']);
      } else if (data['image_urls'] is String) {
        urls = [data['image_urls'].toString()];
      }
    } else if (data['image_url'] != null) {
      urls = [data['image_url'].toString()];
    }

    // 3. Gestion robuste du texte extrait (Le problème identifié)
    List<String> extracted = [];
    final rawExtracted = data['extracted_text'];
    if (rawExtracted is List) {
      extracted = List<String>.from(rawExtracted);
    } else if (rawExtracted is String) {
      // Si la base renvoie une chaîne au lieu d'une liste
      extracted = [rawExtracted];
    }

    return TicketModel(
      id: data['id']?.toString(),
      storeName: data['store_name'] ?? '',
      storeAddress: data['store_address'],
      date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
      totalAmount: (data['total_amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? '€',
      category: data['category'] ?? 'Autre',
      products: parsedProducts,
      imageUrls: urls,
      warrantyEndDate: DateTime.parse(data['warranty_end_date'] ?? DateTime.now().toIso8601String()),
      extractedText: extracted,
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  TicketModel copyWith({
    String? id,
    String? storeName,
    String? storeAddress,
    DateTime? date,
    double? totalAmount,
    String? currency,
    String? category,
    List<Map<String, dynamic>>? products,
    List<String>? imageUrls,
    DateTime? warrantyEndDate,
    List<String>? extractedText,
    DateTime? createdAt,
  }) {
    return TicketModel(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      products: products ?? this.products,
      imageUrls: imageUrls ?? this.imageUrls,
      warrantyEndDate: warrantyEndDate ?? this.warrantyEndDate,
      extractedText: extractedText ?? this.extractedText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool isWarrantyExpiringSoon() {
    final now = DateTime.now();
    final daysUntilExpiry = warrantyEndDate.difference(now).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  bool isWarrantyExpired() => DateTime.now().isAfter(warrantyEndDate);
}
