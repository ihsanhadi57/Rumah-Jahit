import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/product.dart';
import '../../payroll/domain/app_user.dart';

class QuickProductionService {
  final FirebaseFirestore _firestore;

  QuickProductionService(this._firestore);

  Future<void> addQuickProduction({
    required Product product,
    required AppUser tailor,
    required int quantity,
    required double wagePerPiece,
    required String note,
  }) async {
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    // 1. Tambah stok produk
    final productRef = _firestore.collection('products').doc(product.id);
    batch.update(productRef, {
      'current_stock': FieldValue.increment(quantity),
      'updated_at': now,
    });

    // 2. Buat catatan gaji (PayrollRecord)
    final payrollRef = _firestore.collection('payroll_records').doc();
    batch.set(payrollRef, {
      'user_id': tailor.id,
      'user_name': tailor.name,
      'type': 'tambah stok', // User requested label "tambah stok"
      'spk_id': null,
      'spk_title': product.name, // Use product name for reference
      'note': note,
      'pieces_count': quantity,
      'wage_per_piece': wagePerPiece,
      'total_wage': quantity * wagePerPiece,
      'status': 'UNPAID',
      'created_at': now,
    });

    // 3. Tambah statistik tahunan penjahit
    final year = DateTime.now().year;
    final statRef = _firestore.collection('tailor_annual_stats').doc('${tailor.id}_$year');
    batch.set(statRef, {
      'user_id': tailor.id,
      'user_name': tailor.name,
      'year': year,
      'total_pieces': FieldValue.increment(quantity),
      'total_wage': FieldValue.increment(quantity * wagePerPiece),
      'updated_at': now,
    }, SetOptions(merge: true));

    await batch.commit();
  }
}
