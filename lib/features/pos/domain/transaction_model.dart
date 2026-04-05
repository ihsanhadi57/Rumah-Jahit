import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/currency_utils.dart';

class TransactionItem {
  final String productId;
  final String productName;
  final String size;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final bool isCustom;
  final String? productType;

  const TransactionItem({
    required this.productId,
    required this.productName,
    required this.size,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.isCustom = false,
    this.productType,
  });

  factory TransactionItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionItem(
      productId: data['product_id'] ?? '',
      productName: data['product_name'] ?? '',
      size: data['size'] ?? '',
      quantity: (data['quantity'] ?? 0).toInt(),
      unitPrice: (data['unit_price'] ?? 0).toDouble(),
      totalPrice: (data['total_price'] ?? 0).toDouble(),
      isCustom: data['is_custom'] ?? false,
      productType: data['product_type'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'product_id': productId,
      'product_name': productName,
      'size': size,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'is_custom': isCustom,
      if (productType != null) 'product_type': productType,
    };
  }
}

class TransactionModel {
  final String id;
  final String cashierId;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final String paymentMethod; // CASH, TRANSFER, QRIS
  final double amountPaid;
  final String status; // SUCCESS, PENDING, CANCELLED
  final DateTime createdAt;
  final List<TransactionItem> items;

  // Customer info (for custom/personal orders)
  final String? customerName;
  final String? customerPhone;
  final DateTime? pickupDate;
  final bool hasCustomItems;

  const TransactionModel({
    required this.id,
    required this.cashierId,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    required this.paymentMethod,
    required this.amountPaid,
    required this.status,
    required this.createdAt,
    this.items = const [],
    this.customerName,
    this.customerPhone,
    this.pickupDate,
    this.hasCustomItems = false,
  });

  factory TransactionModel.fromFirestore(
    DocumentSnapshot doc, {
    List<TransactionItem> items = const [],
  }) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      cashierId: data['cashier_id'] ?? '',
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      grandTotal: (data['grand_total'] ?? 0).toDouble(),
      paymentMethod: data['payment_method'] ?? 'CASH',
      amountPaid: (data['amount_paid'] ?? 0).toDouble(),
      status: data['status'] ?? 'SUCCESS',
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: items,
      customerName: data['customer_name'] as String?,
      customerPhone: data['customer_phone'] as String?,
      pickupDate: (data['pickup_date'] as Timestamp?)?.toDate(),
      hasCustomItems: data['has_custom_items'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cashier_id': cashierId,
      'subtotal': subtotal,
      'discount': discount,
      'grand_total': grandTotal,
      'payment_method': paymentMethod,
      'amount_paid': amountPaid,
      'status': status,
      'created_at': FieldValue.serverTimestamp(),
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'pickup_date':
          pickupDate != null ? Timestamp.fromDate(pickupDate!) : null,
      'has_custom_items': hasCustomItems,
    };
  }

  double get change => amountPaid - grandTotal;

  String get formattedId {
    if (id.isEmpty) return '#RJA-UNKNOWN';
    final y = createdAt.year.toString();
    final m = createdAt.month.toString().padLeft(2, '0');
    final d = createdAt.day.toString().padLeft(2, '0');
    final suffix = id.length >= 4
        ? id.substring(0, 4).toUpperCase()
        : id.toUpperCase();
    return '#RJA-$y$m$d-$suffix';
  }

  String get formattedGrandTotal => formatCurrency(grandTotal);
  String get formattedSubtotal => formatCurrency(subtotal);
  String get formattedDiscount => formatCurrency(discount);
  String get formattedAmountPaid => formatCurrency(amountPaid);
  String get formattedChange => formatCurrency(change);

  /// Items that are stock-based (not custom)
  List<TransactionItem> get stockItems =>
      items.where((i) => !i.isCustom).toList();

  /// Items that are custom/personal orders
  List<TransactionItem> get customOrderItems =>
      items.where((i) => i.isCustom).toList();
}
