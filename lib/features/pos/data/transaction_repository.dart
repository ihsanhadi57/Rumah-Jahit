import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/transaction_model.dart';
import '../../inventory/domain/production_order.dart';

class TransactionRepository {
  final _collection = FirebaseFirestore.instance.collection('transactions');
  final _spkCollection = FirebaseFirestore.instance.collection(
    'production_orders',
  );

  TransactionRepository();

  /// Create a transaction with atomic stock deduction via WriteBatch.
  /// If there are custom items, auto-create 1 SPK per custom item.
  Future<void> createTransaction(
    TransactionModel transaction,
    List<TransactionItem> items,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. Create the transaction document
    final txRef = _collection.doc();
    batch.set(txRef, transaction.toFirestore());

    // 2. Add each item to the sub-collection
    for (final item in items) {
      final itemRef = txRef.collection('items').doc();
      batch.set(itemRef, item.toFirestore());
    }

    // 3. Deduct stock for each product-based item (skip custom items)
    final productsCol = FirebaseFirestore.instance.collection('products');
    for (final item in items) {
      if (item.isCustom) continue;
      batch.update(productsCol.doc(item.productId), {
        'current_stock': FieldValue.increment(-item.quantity),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    // 4. Auto-create 1 SPK per custom item
    final customItems = items.where((i) => i.isCustom).toList();

    // Fetch wage categories for auto-detecting wage
    List<QueryDocumentSnapshot<Map<String, dynamic>>> wageCategoryDocs = [];
    if (customItems.isNotEmpty) {
      final snapshot = await FirebaseFirestore.instance
          .collection('wage_categories')
          .get();
      wageCategoryDocs = snapshot.docs;
    }

    for (final customItem in customItems) {
      double detectedWage = 0;
      final productNameLower = customItem.productName.toLowerCase();

      for (final doc in wageCategoryDocs) {
        final data = doc.data();
        final catName = data['name'] as String? ?? '';
        final catAmount = (data['amount'] as num?)?.toDouble() ?? 0.0;

        if (catName.isNotEmpty &&
            productNameLower.contains(catName.toLowerCase())) {
          detectedWage = catAmount;
          break;
        }
      }

      final spkRef = _spkCollection.doc();
      final spk = ProductionOrder(
        id: spkRef.id,
        title:
            '${customItem.productName} - ${transaction.customerName ?? "Pelanggan"}',
        spkType: 'PERSONAL',
        productName: customItem.productName,
        productType: customItem.productType ?? 'custom',
        items: [
          SpkVariant(
            productId: '',
            size: customItem.size,
            targetQuantity: customItem.quantity,
          ),
        ],
        targetQuantity: customItem.quantity,
        status: 'PENDING',
        completedQuantity: 0,
        tailorAssignments: [],
        wagePerPiece: detectedWage,
        reports: [],
        materialsUsed: [],
        startDate: DateTime.now(),
        estimatedCompletionDate:
            transaction.pickupDate ??
            DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
        transactionId: txRef.id,
        customerName: transaction.customerName,
        customerPhone: transaction.customerPhone,
        pickupDate: transaction.pickupDate,
      );
      batch.set(spkRef, spk.toFirestore());
    }

    // 5. Add to Finance (as Income)
    if (transaction.amountPaid > 0) {
      final financeRef = FirebaseFirestore.instance
          .collection('finance_transactions')
          .doc();
      batch.set(financeRef, {
        'title': 'Transaksi',
        'amount': transaction.amountPaid,
        'type': 'income',
        'createdAt': FieldValue.serverTimestamp(),
        'category': 'POS',
        'note': 'Pelanggan: ${transaction.customerName ?? "Pelanggan Umum"}',
      });
    }

    // Commit the batch atomically
    await batch.commit();
  }

  /// Stream of today's transactions
  Stream<List<TransactionModel>> watchToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _collection
        .where(
          'created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('created_at', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream of all transactions (for history)
  Stream<List<TransactionModel>> watchAll() {
    return _collection
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap((snapshot) async {
          final txs = <TransactionModel>[];
          for (final doc in snapshot.docs) {
            final itemsSnapshot = await doc.reference.collection('items').get();
            final items = itemsSnapshot.docs
                .map((itemDoc) => TransactionItem.fromFirestore(itemDoc))
                .toList();
            txs.add(TransactionModel.fromFirestore(doc, items: items));
          }
          return txs;
        });
  }

  /// Update transaction status
  Future<void> updateStatus(String transactionId, String newStatus) async {
    await _collection.doc(transactionId).update({'status': newStatus});
  }

  /// Update transaction status and amount paid
  Future<void> updateStatusAndAmountPaid(
    String transactionId,
    String newStatus,
    double newAmountPaid,
  ) async {
    final doc = await _collection.doc(transactionId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final oldAmountPaid = (data['amount_paid'] as num?)?.toDouble() ?? 0.0;
    final incomeAmount = newAmountPaid - oldAmountPaid;

    final batch = FirebaseFirestore.instance.batch();

    // Update transaction
    batch.update(_collection.doc(transactionId), {
      'status': newStatus,
      'amount_paid': newAmountPaid,
    });

    // Add to finance if there's additional payment
    if (incomeAmount > 0) {
      final financeRef = FirebaseFirestore.instance
          .collection('finance_transactions')
          .doc();
      final tx = TransactionModel.fromFirestore(doc);

      batch.set(financeRef, {
        'title': 'Pelunasan',
        'amount': incomeAmount,
        'type': 'income',
        'createdAt': FieldValue.serverTimestamp(),
        'category': 'POS',
        'note': 'Pelanggan: ${tx.customerName ?? "Pelanggan Umum"}',
      });
    }

    await batch.commit();
  }

  /// Cancel a transaction (sets status to CANCELLED, restores stock)
  Future<void> cancel(String transactionId) async {
    // Fetch the transaction items first
    final itemsSnapshot = await _collection
        .doc(transactionId)
        .collection('items')
        .get();

    final batch = FirebaseFirestore.instance.batch();

    // Restore stock for each non-custom item
    final productsCol = FirebaseFirestore.instance.collection('products');
    for (final itemDoc in itemsSnapshot.docs) {
      final data = itemDoc.data();
      final isCustom = data['is_custom'] ?? false;
      if (isCustom) continue;

      final productId = data['product_id'] as String;
      final quantity = (data['quantity'] as num).toInt();
      batch.update(productsCol.doc(productId), {
        'current_stock': FieldValue.increment(quantity),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    // Update transaction status
    batch.update(_collection.doc(transactionId), {'status': 'CANCELLED'});

    await batch.commit();
  }
}
