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
  final String imageUrl;
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
    required this.imageUrl,
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
      'image_url': imageUrl,
      'warranty_end_date': warrantyEndDate.toIso8601String(),
      'extracted_text': extractedText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TicketModel.fromMap(Map<String, dynamic> data) {
    // Logique robuste pour la liste de produits
    List<Map<String, dynamic>> parsedProducts = [];
    final rawProducts = data['products'];

    if (rawProducts is List) {
      parsedProducts = rawProducts.map((item) {
        if (item is Map) {
          return Map<String, dynamic>.from(item);
        } else {
          // Si c'est une ancienne donnée (String), on la convertit en objet
          return {'name': item.toString(), 'price': '0.00'};
        }
      }).toList();
    } else if (rawProducts is String) {
      // Cas où Supabase renvoie une string JSON
      try {
        parsedProducts = List<Map<String, dynamic>>.from(jsonDecode(rawProducts));
      } catch (e) {
        parsedProducts = [{'name': rawProducts, 'price': '0.00'}];
      }
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
      imageUrl: data['image_url'] ?? '',
      warrantyEndDate: DateTime.parse(data['warranty_end_date'] ?? DateTime.now().toIso8601String()),
      extractedText: List<String>.from(data['extracted_text'] ?? []),
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
    String? imageUrl,
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
      imageUrl: imageUrl ?? this.imageUrl,
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

  bool isWarrantyExpired() {
    return DateTime.now().isAfter(warrantyEndDate);
  }
}
