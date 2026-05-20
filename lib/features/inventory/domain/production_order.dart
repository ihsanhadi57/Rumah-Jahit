import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/currency_utils.dart';

/// Represents a tailor's assignment within an SPK
class TailorAssignment {
  final String userId;
  final String userName;
  final int completedPieces;

  const TailorAssignment({
    required this.userId,
    required this.userName,
    this.completedPieces = 0,
  });

  factory TailorAssignment.fromMap(Map<String, dynamic> map) {
    return TailorAssignment(
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? '',
      completedPieces: (map['completed_pieces'] ?? map['pieces_count'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'completed_pieces': completedPieces,
    };
  }

  TailorAssignment copyWith({
    String? userId,
    String? userName,
    int? completedPieces,
  }) {
    return TailorAssignment(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      completedPieces: completedPieces ?? this.completedPieces,
    );
  }
}

/// Represents a daily production report by a tailor
class ProductionReport {
  final String id;
  final String userId;
  final String userName;
  final String? variantSize;
  final int quantity;
  final double wagePerPiece;
  final DateTime createdAt;

  const ProductionReport({
    required this.id,
    required this.userId,
    required this.userName,
    this.variantSize,
    required this.quantity,
    required this.wagePerPiece,
    required this.createdAt,
  });

  factory ProductionReport.fromMap(Map<String, dynamic> map) {
    return ProductionReport(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? '',
      variantSize: map['variant_size'],
      quantity: (map['quantity'] ?? 0).toInt(),
      wagePerPiece: (map['wage_per_piece'] ?? 0).toDouble(),
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'variant_size': variantSize,
      'quantity': quantity,
      'wage_per_piece': wagePerPiece,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}

/// Represents a raw material used in production
class MaterialUsed {
  final String materialId;
  final String materialName;
  final double quantity;
  final String unit;

  const MaterialUsed({
    required this.materialId,
    required this.materialName,
    required this.quantity,
    required this.unit,
  });

  factory MaterialUsed.fromMap(Map<String, dynamic> map) {
    return MaterialUsed(
      materialId: map['material_id'] ?? '',
      materialName: map['material_name'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'material_id': materialId,
      'material_name': materialName,
      'quantity': quantity,
      'unit': unit,
    };
  }

  MaterialUsed copyWith({
    String? materialId,
    String? materialName,
    double? quantity,
    String? unit,
  }) {
    return MaterialUsed(
      materialId: materialId ?? this.materialId,
      materialName: materialName ?? this.materialName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }
}

/// Represents a specific product variant (size) and its quantity in an SPK
class SpkVariant {
  final String productId;
  final String size;
  final int targetQuantity;
  final int completedQuantity;

  const SpkVariant({
    required this.productId,
    required this.size,
    required this.targetQuantity,
    this.completedQuantity = 0,
  });

  factory SpkVariant.fromMap(Map<String, dynamic> map) {
    return SpkVariant(
      productId: map['product_id'] ?? '',
      size: map['size'] ?? '',
      targetQuantity: (map['target_quantity'] ?? 0).toInt(),
      completedQuantity: (map['completed_quantity'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'size': size,
      'target_quantity': targetQuantity,
      'completed_quantity': completedQuantity,
    };
  }

  bool get hasTarget => targetQuantity > 0;
}

class ProductionOrder {
  final String id;
  final String title;
  final String spkType; // 'RESTOCK', 'CUSTOM', or 'PERSONAL'

  // Product info
  final String productName;
  final String productType;
  final List<SpkVariant> items; // New: support multiple sizes
  final int targetQuantity; // Total of all items

  // Status & progress
  final String status; // PENDING, IN_PROGRESS, COMPLETED
  final int completedQuantity;

  // Tailors
  final List<TailorAssignment> tailorAssignments;
  final double wagePerPiece;

  // Reports
  final List<ProductionReport> reports;

  // Materials
  final List<MaterialUsed> materialsUsed;

  // Dates
  final DateTime startDate;
  final DateTime estimatedCompletionDate;
  final DateTime createdAt;
  final DateTime? completedAt;

  // Soft delete
  final bool isDeleted;
  final DateTime? deletedAt;

  // Link to POS transaction (for custom orders from checkout)
  final String? transactionId;
  final String? customerName;
  final String? customerPhone;
  final DateTime? pickupDate;

  // Legacy fields (optional/nullable to maintain compatibility)
  final String? targetProductId;
  final String? productSize;

  const ProductionOrder({
    required this.id,
    required this.title,
    this.spkType = 'RESTOCK',
    required this.productName,
    required this.productType,
    required this.items,
    required this.targetQuantity,
    required this.status,
    required this.completedQuantity,
    required this.tailorAssignments,
    required this.wagePerPiece,
    required this.reports,
    required this.materialsUsed,
    required this.startDate,
    required this.estimatedCompletionDate,
    required this.createdAt,
    this.completedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.transactionId,
    this.customerName,
    this.customerPhone,
    this.pickupDate,
    this.targetProductId,
    this.productSize,
  });

  factory ProductionOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>?)
            ?.map((e) => SpkVariant.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Handle legacy data where items list might be empty but single fields exist
    final legacyId = data['target_product_id'] as String?;
    final legacySize = data['product_size'] as String?;
    final legacyQty = (data['target_quantity'] ?? 0).toInt();

    final finalItems = itemsList.isNotEmpty
        ? itemsList
        : (legacyId != null && legacyId.isNotEmpty
            ? [
                SpkVariant(
                    productId: legacyId,
                    size: legacySize ?? '',
                    targetQuantity: legacyQty)
              ]
            : <SpkVariant>[]);

    return ProductionOrder(
      id: doc.id,
      title: data['title'] ?? '',
      spkType: data['spk_type'] ?? 'RESTOCK',
      productName: data['product_name'] ?? '',
      productType: data['product_type'] ?? '',
      items: finalItems,
      targetQuantity: (data['target_quantity'] ?? 0).toInt(),
      status: data['status'] ?? 'PENDING',
      completedQuantity: (data['completed_quantity'] ?? 0).toInt(),
      tailorAssignments: (data['tailor_assignments'] as List<dynamic>?)
              ?.map(
                  (e) => TailorAssignment.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      wagePerPiece: (data['wage_per_piece'] ?? 0).toDouble(),
      reports: (data['reports'] as List<dynamic>?)
              ?.map(
                  (e) => ProductionReport.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      materialsUsed: (data['materials_used'] as List<dynamic>?)
              ?.map((e) => MaterialUsed.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      startDate:
          (data['start_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estimatedCompletionDate:
          (data['estimated_completion_date'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completed_at'] as Timestamp?)?.toDate(),
      isDeleted: data['is_deleted'] == true,
      deletedAt: (data['deleted_at'] as Timestamp?)?.toDate(),
      transactionId: data['transaction_id'] as String?,
      customerName: data['customer_name'] as String?,
      customerPhone: data['customer_phone'] as String?,
      pickupDate: (data['pickup_date'] as Timestamp?)?.toDate(),
      targetProductId: legacyId,
      productSize: legacySize,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'spk_type': spkType,
      'product_name': productName,
      'product_type': productType,
      'items': items.map((e) => e.toMap()).toList(),
      'target_quantity': targetQuantity,
      'status': status,
      'completed_quantity': completedQuantity,
      'tailor_assignments':
          tailorAssignments.map((e) => e.toMap()).toList(),
      'wage_per_piece': wagePerPiece,
      'reports': reports.map((e) => e.toMap()).toList(),
      'materials_used': materialsUsed.map((e) => e.toMap()).toList(),
      'start_date': Timestamp.fromDate(startDate),
      'estimated_completion_date':
          Timestamp.fromDate(estimatedCompletionDate),
      'created_at': FieldValue.serverTimestamp(),
      'completed_at': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt != null
          ? Timestamp.fromDate(deletedAt!)
          : null,
      'transaction_id': transactionId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'pickup_date': pickupDate != null
          ? Timestamp.fromDate(pickupDate!)
          : null,
      // Keep legacy fields for a bridge period if needed
      'target_product_id': targetProductId,
      'product_size': productSize,
    };
  }

  double get progressPercent {
    if (targetQuantity == 0) return 0;
    return (completedQuantity / targetQuantity).clamp(0.0, 1.0);
  }

  /// Whether this SPK has a defined target quantity
  bool get hasTarget => targetQuantity > 0;

  int get totalAssignedPieces => targetQuantity; // Replaced logic since assignment does not track initial pieces. We just use target.

  double get totalWageCost => targetQuantity * wagePerPiece;

  bool get isCompleted => status == 'COMPLETED';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isCustom => spkType == 'CUSTOM';
  bool get isPersonal => spkType == 'PERSONAL';
  bool get isRestock => spkType == 'RESTOCK';
  bool get isOrder => isCustom || isPersonal; // Combined for tab filtering
  bool get isPending => status == 'PENDING';

  /// Formatted wage string
  String get formattedWage => formatCurrency(wagePerPiece);
  String get formattedTotalCost => formatCurrency(totalWageCost);

  ProductionOrder copyWith({
    String? id,
    String? title,
    String? spkType,
    String? productName,
    String? productType,
    List<SpkVariant>? items,
    int? targetQuantity,
    String? status,
    int? completedQuantity,
    List<TailorAssignment>? tailorAssignments,
    double? wagePerPiece,
    List<ProductionReport>? reports,
    List<MaterialUsed>? materialsUsed,
    DateTime? startDate,
    DateTime? estimatedCompletionDate,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    String? transactionId,
    String? customerName,
    String? customerPhone,
    DateTime? pickupDate,
    String? targetProductId,
    String? productSize,
  }) {
    return ProductionOrder(
      id: id ?? this.id,
      title: title ?? this.title,
      spkType: spkType ?? this.spkType,
      productName: productName ?? this.productName,
      productType: productType ?? this.productType,
      items: items ?? this.items,
      targetQuantity: targetQuantity ?? this.targetQuantity,
      status: status ?? this.status,
      completedQuantity: completedQuantity ?? this.completedQuantity,
      tailorAssignments: tailorAssignments ?? this.tailorAssignments,
      wagePerPiece: wagePerPiece ?? this.wagePerPiece,
      reports: reports ?? this.reports,
      materialsUsed: materialsUsed ?? this.materialsUsed,
      startDate: startDate ?? this.startDate,
      estimatedCompletionDate:
          estimatedCompletionDate ?? this.estimatedCompletionDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      transactionId: transactionId ?? this.transactionId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      pickupDate: pickupDate ?? this.pickupDate,
      targetProductId: targetProductId ?? this.targetProductId,
      productSize: productSize ?? this.productSize,
    );
  }
}

