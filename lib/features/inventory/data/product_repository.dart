import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/product.dart';

class ProductRepository {
  final _collection = FirebaseFirestore.instance.collection('products');

  /// Real-time stream of all products
  Stream<List<Product>> watchAll() {
    return _collection
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  /// Get a single product by ID
  Future<Product?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Product.fromFirestore(doc);
  }

  /// Add a new product
  Future<void> add(Product product) async {
    await _collection.add(product.toFirestore());
  }

  /// Batch-add multiple products (for multi-size product creation)
  Future<void> addBatch(List<Product> products) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final product in products) {
      final docRef = _collection.doc();
      batch.set(docRef, product.toFirestore());
    }
    await batch.commit();
  }

  /// Update an existing product
  Future<void> update(Product product) async {
    await _collection.doc(product.id).update(product.toFirestore());
  }

  /// Batch-update multiple products
  Future<void> updateBatch(List<Product> products) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final product in products) {
      batch.update(_collection.doc(product.id), product.toFirestore());
    }
    await batch.commit();
  }

  /// Delete a product by ID
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  /// Deduct stock (used during POS transaction)
  Future<void> deductStock(String id, int quantity) async {
    await _collection.doc(id).update({
      'current_stock': FieldValue.increment(-quantity),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Add stock (used when SPK is completed)
  Future<void> addStock(String id, int quantity) async {
    await _collection.doc(id).update({
      'current_stock': FieldValue.increment(quantity),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
