import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/currency_utils.dart';

class Product {
  final String id;
  final String name;
  final List<String> schoolLevels;
  final String type;
  final String size;
  final double price;
  final int currentStock;
  final String? imageUrl;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.schoolLevels,
    required this.type,
    required this.size,
    required this.price,
    required this.currentStock,
    this.imageUrl,
    required this.updatedAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      schoolLevels: List<String>.from(data['school_levels'] ?? []),
      type: data['type'] ?? '',
      size: data['size'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      currentStock: (data['current_stock'] ?? 0).toInt(),
      imageUrl: data['image_url'],
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'school_levels': schoolLevels,
      'type': type,
      'size': size,
      'price': price,
      'current_stock': currentStock,
      'image_url': imageUrl,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  /// Formatted display name: "Baju OSIS SMP/MTs - L. Panjang - M"
  String get displayName {
    final levels = schoolLevels.join('/');
    return '$name $levels - $type - $size';
  }

  /// Formatted price string
  String get formattedPrice => formatCurrency(price);

  Product copyWith({
    String? id,
    String? name,
    List<String>? schoolLevels,
    String? type,
    String? size,
    double? price,
    int? currentStock,
    String? imageUrl,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      schoolLevels: schoolLevels ?? this.schoolLevels,
      type: type ?? this.type,
      size: size ?? this.size,
      price: price ?? this.price,
      currentStock: currentStock ?? this.currentStock,
      imageUrl: imageUrl ?? this.imageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
