import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/raw_material.dart';

class RawMaterialRepository {
  final _collection = FirebaseFirestore.instance.collection('raw_materials');

  /// Real-time stream of all raw materials
  Stream<List<RawMaterial>> watchAll() {
    return _collection
        .orderBy('updated_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RawMaterial.fromFirestore(doc)).toList());
  }

  /// Stream of items below their low-stock threshold
  Stream<List<RawMaterial>> watchLowStock() {
    return watchAll().map((materials) => materials
        .where((m) => m.selectedStock <= m.lowStockThreshold)
        .toList());
  }

  /// Get a single raw material by ID (real-time)
  Stream<RawMaterial?> watchById(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return RawMaterial.fromFirestore(doc);
    });
  }

  /// Add a new raw material
  Future<void> add(RawMaterial material) async {
    await _collection.add(material.toFirestore());
  }

  /// Add and return the DocumentReference (for getting the auto-generated ID)
  Future<DocumentReference> addAndGetRef(RawMaterial material) async {
    return await _collection.add(material.toFirestore());
  }

  /// Update an existing raw material
  Future<void> update(RawMaterial material) async {
    await _collection.doc(material.id).update(material.toFirestore());
  }

  /// Delete a raw material by ID
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  /// Delete image from storage when deleting a material
  Future<void> deleteWithImage(String id, String? imageUrl) async {
    // Delete the Firestore document
    await _collection.doc(id).delete();
  }

  /// Deduct stock (used when SPK is submitted)
  Future<void> deductStock(String id, double quantity) async {
    await _collection.doc(id).update({
      'selected_stock': FieldValue.increment(-quantity),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Increment stock (used when receiving new materials)
  Future<void> addStock(String id, double quantity) async {
    await _collection.doc(id).update({
      'selected_stock': FieldValue.increment(quantity),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
