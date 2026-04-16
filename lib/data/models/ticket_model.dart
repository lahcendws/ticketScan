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
    // 1. Parsing robuste des produits
    List<Map<String, dynamic>> parsedProducts = [];
    final rawProducts = data['products'];
    if (rawProducts is List) {
      parsedProducts = rawProducts.map((item) {
        if (item is Map) return Map<String, dynamic>.from(item);
        if (item is String && item.startsWith('{')) {
          try { return Map<String, dynamic>.from(jsonDecode(item)); } catch (_) {}
        }
        return {'name': item.toString(), 'price': '0.00'};
      }).toList();
    }

    // 2. Parsing robuste des URLs d'images (enlève les JSON artifacts)
    List<String> urls = [];
    dynamic rawUrls = data['image_urls'] ?? data['image_url'];
    if (rawUrls != null) {
      if (rawUrls is List) {
        urls = rawUrls.map((e) => e.toString().replaceAll(RegExp(r'[\[\]" ]'), '')).toList();
      } else if (rawUrls is String) {
        if (rawUrls.startsWith('[')) {
          try {
            urls = List<String>.from(jsonDecode(rawUrls)).map((e) => e.replaceAll(RegExp(r'[\[\]" ]'), '')).toList();
          } catch (_) {
            urls = [rawUrls.replaceAll(RegExp(r'[\[\]" ]'), '')];
          }
        } else {
          urls = [rawUrls.replaceAll(RegExp(r'[\[\]" ]'), '')];
        }
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
      imageUrls: urls.where((u) => u.isNotEmpty).toList(),
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

  bool isWarrantyExpiringSoon() => warrantyEndDate.difference(DateTime.now()).inDays <= 30;
  bool isWarrantyExpired() => DateTime.now().isAfter(warrantyEndDate);
}
