import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rumah_jahit/features/settings/domain/wage_category.dart';

class SettingsRepository {
  final FirebaseFirestore _firestore;

  SettingsRepository(this._firestore);

  Stream<List<WageCategory>> watchWageCategories() {
    return _firestore
        .collection('wage_categories')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WageCategory.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> saveWageCategory(WageCategory category) async {
    final docRef = category.id.isEmpty 
        ? _firestore.collection('wage_categories').doc()
        : _firestore.collection('wage_categories').doc(category.id);
        
    await docRef.set(category.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteWageCategory(String id) async {
    await _firestore.collection('wage_categories').doc(id).delete();
  }
}
