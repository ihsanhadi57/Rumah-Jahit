import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/production_order.dart';

class ProductionOrderRepository {
  final _collection = FirebaseFirestore.instance.collection(
    'production_orders',
  );
  final _productsCollection = FirebaseFirestore.instance.collection('products');
  final _materialsCollection = FirebaseFirestore.instance.collection(
    'raw_materials',
  );
  final _payrollCollection = FirebaseFirestore.instance.collection(
    'payroll_records',
  );

  /// Real-time stream of all production orders
  Stream<List<ProductionOrder>> watchAll() {
    return _collection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductionOrder.fromFirestore(doc))
              .where((order) => !order.isDeleted)
              .toList(),
        );
  }

  /// Stream of active orders (PENDING + IN_PROGRESS)
  Stream<List<ProductionOrder>> watchActive() {
    return _collection
        .where('status', whereIn: ['PENDING', 'IN_PROGRESS'])
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductionOrder.fromFirestore(doc))
              .where((order) => !order.isDeleted)
              .toList(),
        );
  }

  /// Stream of completed orders
  Stream<List<ProductionOrder>> watchCompleted() {
    return _collection
        .where('status', isEqualTo: 'COMPLETED')
        .orderBy('completed_at', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductionOrder.fromFirestore(doc))
              .where((order) => !order.isDeleted)
              .toList(),
        );
  }

  /// Add a new production order
  Future<void> add(ProductionOrder order) async {
    final batch = FirebaseFirestore.instance.batch();
    final docRef = _collection.doc();

    final newOrder = order.copyWith(id: docRef.id);
    batch.set(docRef, newOrder.toFirestore());

    // Deduct raw materials immediately on creation
    for (final material in newOrder.materialsUsed) {
      if (material.materialId.isNotEmpty) {
        batch.update(_materialsCollection.doc(material.materialId), {
          'selected_stock': FieldValue.increment(-material.quantity),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  /// Update an existing order
  Future<void> update(ProductionOrder order) async {
    await _collection.doc(order.id).update(order.toFirestore());
  }

  /// Start production (PENDING → IN_PROGRESS)
  Future<void> startProduction(String id) async {
    await _collection.doc(id).update({'status': 'IN_PROGRESS'});
  }

  /// Update production progress
  Future<void> updateProgress(String id, List<SpkVariant> items, {int? completedQty}) async {
    if (completedQty != null) {
      // Custom/Personal SPK: update completed_quantity directly
      await _collection.doc(id).update({
        'completed_quantity': completedQty,
      });
    } else {
      // Restock SPK: calculate from items
      final totalCompleted = items.fold(
        0,
        (total, item) => total + item.completedQuantity,
      );
      await _collection.doc(id).update({
        'items': items.map((e) => e.toMap()).toList(),
        'completed_quantity': totalCompleted,
      });
    }
  }

  /// Update tailor assignments for a production order
  Future<void> updateTailorAssignments(
    String spkId,
    List<TailorAssignment> assignments,
  ) async {
    await _collection.doc(spkId).update({
      'tailor_assignments': assignments.map((e) => e.toMap()).toList(),
    });
  }

  /// Update wage per piece for a production order
  Future<void> updateWagePerPiece(String spkId, double wage) async {
    await _collection.doc(spkId).update({
      'wage_per_piece': wage,
    });
  }

  /// Add a daily report, increment stock instantly, and create a payroll record.
  Future<void> reportDailyProduction(
    ProductionOrder updatedOrder,
    ProductionReport newReport,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. Update the SPK document with new state (items, tailors, reports, completed qty)
    batch.update(_collection.doc(updatedOrder.id), updatedOrder.toFirestore());

    // 2. Instantly add stock for RESTOCK orders
    if (updatedOrder.isRestock && newReport.variantSize != null) {
      final variant = updatedOrder.items.firstWhere(
        (i) => i.size == newReport.variantSize,
        orElse: () => const SpkVariant(productId: '', size: '', targetQuantity: 0),
      );
      if (variant.productId.isNotEmpty) {
        batch.update(_productsCollection.doc(variant.productId), {
          'current_stock': FieldValue.increment(newReport.quantity),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    }

    // 3. Create a single explicit payroll record for this report
    final payrollDoc = _payrollCollection.doc();
    batch.set(payrollDoc, {
      'user_id': newReport.userId,
      'user_name': newReport.userName,
      'type': 'spk',
      'spk_id': updatedOrder.id,
      'spk_title': updatedOrder.title,
      'note': 'Laporan Harian ${newReport.variantSize ?? ''}'.trim(),
      'pieces_count': newReport.quantity,
      'wage_per_piece': newReport.wagePerPiece,
      'total_wage': newReport.quantity * newReport.wagePerPiece,
      'status': 'UNPAID',
      'created_at': FieldValue.serverTimestamp(),
      'report_id': newReport.id,
    });

    // 4. Annual Stats (Bonus Tahunan)
    final year = newReport.createdAt.year;
    final statDoc = FirebaseFirestore.instance
        .collection('tailor_annual_stats')
        .doc('${newReport.userId}_$year');
    
    batch.set(statDoc, {
      'user_id': newReport.userId,
      'user_name': newReport.userName,
      'year': year,
      'total_pieces': FieldValue.increment(newReport.quantity),
      'total_wage': FieldValue.increment(newReport.quantity * newReport.wagePerPiece),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> completeWithEffects(ProductionOrder order) async {
    final batch = FirebaseFirestore.instance.batch();

    // Just mark as COMPLETED. No stock/payroll effects since they happen during daily reports.
    batch.update(_collection.doc(order.id), {
      'status': 'COMPLETED',
      'completed_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Auto-complete linked transaction if all SPKs for it are done
    if (order.isPersonal && order.transactionId != null) {
      await _autoCompleteTransaction(order.transactionId!);
    }
  }

  /// Check if all SPKs linked to a transaction are COMPLETED.
  /// If yes, auto-update the transaction status to SUCCESSFUL.
  Future<void> _autoCompleteTransaction(String transactionId) async {
    final linkedSpks = await _collection
        .where('transaction_id', isEqualTo: transactionId)
        .get();

    final allCompleted = linkedSpks.docs.every((doc) {
      final data = doc.data();
      return data['status'] == 'COMPLETED';
    });

    if (allCompleted && linkedSpks.docs.isNotEmpty) {
      final txCollection =
          FirebaseFirestore.instance.collection('transactions');
      final txDoc = await txCollection.doc(transactionId).get();
      
      if (txDoc.exists) {
        final txData = txDoc.data()!;
        final amountPaid = (txData['amount_paid'] as num?)?.toDouble() ?? 0.0;
        final grandTotal = (txData['grand_total'] as num?)?.toDouble() ?? 0.0;

        if (amountPaid >= grandTotal) {
          await txCollection.doc(transactionId).update({
            'status': 'SUCCESSFUL',
          });
        } else {
          await txCollection.doc(transactionId).update({
            'status': 'READY',
          });
        }
      }
    }
  }

  /// Edit material usage quantity midway
  Future<void> updateMaterialUsage(
    String spkId,
    ProductionOrder order,
    String materialId,
    double difference,
  ) async {
    // difference = newQty - oldQty
    final batch = FirebaseFirestore.instance.batch();

    // 1. Calculate new materials list
    final newMaterials = order.materialsUsed.map((m) {
      if (m.materialId == materialId) {
        return m.copyWith(quantity: m.quantity + difference);
      }
      return m;
    }).toList();

    // 2. Update SPK document
    batch.update(_collection.doc(spkId), {
      'materials_used': newMaterials.map((e) => e.toMap()).toList(),
    });

    // 3. Adjust material stock
    // If we use MORE material (difference > 0), we DEDUCT stock (increment -difference)
    // If we use LESS material (difference < 0), we RESTORE stock (increment -difference becomes positive)
    batch.update(_materialsCollection.doc(materialId), {
      'selected_stock': FieldValue.increment(-difference),
      'updated_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Add new material midway
  Future<void> addMaterialUsage(
    String spkId,
    ProductionOrder order,
    MaterialUsed newMaterial,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    final updatedMaterials = [...order.materialsUsed, newMaterial];

    batch.update(_collection.doc(spkId), {
      'materials_used': updatedMaterials.map((e) => e.toMap()).toList(),
    });

    batch.update(_materialsCollection.doc(newMaterial.materialId), {
      'selected_stock': FieldValue.increment(-newMaterial.quantity),
      'updated_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Soft-delete an order: marks as deleted without removing data.
  /// Payroll records and stock changes remain intact.
  Future<void> softDelete(String orderId) async {
    await _collection.doc(orderId).update({
      'is_deleted': true,
      'deleted_at': FieldValue.serverTimestamp(),
    });
  }

  /// Hard-delete an order and restore materials (legacy — use softDelete instead)
  @Deprecated('Use softDelete() to preserve payroll/stock history')
  Future<void> delete(ProductionOrder order) async {
    final batch = FirebaseFirestore.instance.batch();

    batch.delete(_collection.doc(order.id));

    // Restore materials
    for (final material in order.materialsUsed) {
      if (material.materialId.isNotEmpty) {
        batch.update(_materialsCollection.doc(material.materialId), {
          'selected_stock': FieldValue.increment(material.quantity),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }
}
