import 'package:cloud_firestore/cloud_firestore.dart';

class RawMaterial {
  final String id;
  final String name;
  final String unit;
  final double selectedStock;
  final double lowStockThreshold;
  final String? imageUrl;
  final DateTime updatedAt;

  const RawMaterial({
    required this.id,
    required this.name,
    required this.unit,
    required this.selectedStock,
    required this.lowStockThreshold,
    this.imageUrl,
    required this.updatedAt,
  });

  factory RawMaterial.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RawMaterial(
      id: doc.id,
      name: data['name'] ?? '',
      unit: data['unit'] ?? '',
      selectedStock: (data['selected_stock'] ?? 0).toDouble(),
      lowStockThreshold: (data['low_stock_threshold'] ?? 0).toDouble(),
      imageUrl: data['image_url'] as String?,
      updatedAt:
          (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'unit': unit,
      'selected_stock': selectedStock,
      'low_stock_threshold': lowStockThreshold,
      'image_url': imageUrl,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  /// Returns stock status label based on threshold
  String get stockStatus {
    if (selectedStock <= 0) return 'HABIS';
    if (selectedStock <= lowStockThreshold) return 'LOW';
    return 'OPTIMAL';
  }

  RawMaterial copyWith({
    String? id,
    String? name,
    String? unit,
    double? selectedStock,
    double? lowStockThreshold,
    String? imageUrl,
    DateTime? updatedAt,
  }) {
    return RawMaterial(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      selectedStock: selectedStock ?? this.selectedStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      imageUrl: imageUrl ?? this.imageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
