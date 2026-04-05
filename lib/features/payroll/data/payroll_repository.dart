import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/payroll_record.dart';
import '../domain/tailor_annual_stat.dart';

class PayrollRepository {
  final _collection = FirebaseFirestore.instance.collection('payroll_records');

  /// Stream of all payroll records for a specific user
  Stream<List<PayrollRecord>> watchByUser(String userId) {
    return _collection
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PayrollRecord.fromFirestore(doc))
            .toList());
  }

  /// Stream of unpaid payroll records for a specific user
  Stream<List<PayrollRecord>> watchUnpaidByUser(String userId) {
    return _collection
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'UNPAID')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PayrollRecord.fromFirestore(doc))
            .toList());
  }

  /// Stream of all payroll records
  Stream<List<PayrollRecord>> watchAll() {
    return _collection
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PayrollRecord.fromFirestore(doc))
            .toList());
  }

  /// Generate a new payroll record
  Future<void> generate(PayrollRecord record) async {
    await _collection.add(record.toFirestore());
  }

  /// Mark a payroll as paid
  Future<void> markPaid(String id) async {
    await _collection.doc(id).update({
      'status': 'PAID',
    });
  }

  /// Delete a payroll record
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  /// Watch annual statistics for a specific user and year
  Stream<TailorAnnualStat?> watchAnnualStats(String userId, int year) {
    return FirebaseFirestore.instance
        .collection('tailor_annual_stats')
        .doc('${userId}_$year')
        .snapshots()
        .map((doc) => doc.exists ? TailorAnnualStat.fromFirestore(doc) : null);
  }
}
