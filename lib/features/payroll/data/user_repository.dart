import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/app_user.dart';

class UserRepository {
  final _collection = FirebaseFirestore.instance.collection('users');

  /// Real-time stream of all users
  Stream<List<AppUser>> watchAll() {
    return _collection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList());
  }

  /// Stream of tailors only
  Stream<List<AppUser>> watchTailors() {
    return _collection
        .where('role', isEqualTo: 'tailor')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList());
  }

  /// Stream of all employees (tailors + cashiers)
  Stream<List<AppUser>> watchEmployees() {
    return _collection
        .where('role', whereIn: ['tailor', 'cashier'])
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList());
  }

  /// Get a single user by ID
  Future<AppUser?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  /// Add a new user
  Future<void> add(AppUser user) async {
    await _collection.doc(user.id).set(user.toFirestore());
  }

  /// Update an existing user
  Future<void> update(AppUser user) async {
    await _collection.doc(user.id).update(user.toFirestore());
  }

  /// Update cash advance balance
  Future<void> updateCashAdvance(String userId, double amount) async {
    await _collection.doc(userId).update({
      'cash_advance_balance': FieldValue.increment(amount),
    });
  }

  /// Delete a user
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }
}
