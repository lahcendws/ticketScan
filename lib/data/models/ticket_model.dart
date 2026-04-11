class TicketModel {
  final String? id;
  final String storeName;
  final DateTime date;
  final double totalAmount;
  final List<String> products;
  final String imageUrl;
  final DateTime warrantyEndDate;
  final List<String> extractedText;
  final DateTime createdAt;

  TicketModel({
    this.id,
    required this.storeName,
    required this.date,
    required this.totalAmount,
    required this.products,
    required this.imageUrl,
    required this.warrantyEndDate,
    this.extractedText = const [],
    required this.createdAt,
  });

  // Convertir en Map pour Supabase (utilisant snake_case)
  Map<String, dynamic> toMap() {
    return {
      'store_name': storeName,
      'date': date.toIso8601String(),
      'total_amount': totalAmount,
      'products': products,
      'image_url': imageUrl,
      'warranty_end_date': warrantyEndDate.toIso8601String(),
      'extracted_text': extractedText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Créer depuis un document Supabase (gérant snake_case)
  factory TicketModel.fromMap(Map<String, dynamic> data) {
    return TicketModel(
      id: data['id']?.toString(),
      storeName: data['store_name'] ?? data['storeName'] ?? '',
      date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
      totalAmount: (data['total_amount'] ?? data['totalAmount'] ?? 0.0).toDouble(),
      products: List<String>.from(data['products'] ?? []),
      imageUrl: data['image_url'] ?? data['imageUrl'] ?? '',
      warrantyEndDate: DateTime.parse(data['warranty_end_date'] ?? data['warrantyEndDate'] ?? DateTime.now().toIso8601String()),
      extractedText: List<String>.from(data['extracted_text'] ?? data['extractedText'] ?? []),
      createdAt: DateTime.parse(data['created_at'] ?? data['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Copier avec modifications
  TicketModel copyWith({
    String? id,
    String? storeName,
    DateTime? date,
    double? totalAmount,
    List<String>? products,
    String? imageUrl,
    DateTime? warrantyEndDate,
    List<String>? extractedText,
    DateTime? createdAt,
  }) {
    return TicketModel(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
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
