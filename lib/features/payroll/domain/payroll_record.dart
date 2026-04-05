import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/currency_utils.dart';

class PayrollRecord {
  final String id;
  final String userId;
  final String userName;
  final String type; // "spk" or "adjustment"
  final String? spkId;
  final String? spkTitle;
  final String? note;
  final int piecesCount;
  final double wagePerPiece;
  final double totalWage;
  final String status; // UNPAID, PAID
  final DateTime createdAt;

  const PayrollRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    this.spkId,
    this.spkTitle,
    this.note,
    required this.piecesCount,
    required this.wagePerPiece,
    required this.totalWage,
    required this.status,
    required this.createdAt,
  });

  factory PayrollRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PayrollRecord(
      id: doc.id,
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      type: data['type'] ?? 'spk',
      spkId: data['spk_id'],
      spkTitle: data['spk_title'],
      note: data['note'],
      piecesCount: (data['pieces_count'] ?? 0).toInt(),
      wagePerPiece: (data['wage_per_piece'] ?? 0).toDouble(),
      totalWage: (data['total_wage'] ?? 0).toDouble(),
      status: data['status'] ?? 'UNPAID',
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'user_name': userName,
      'type': type,
      'spk_id': spkId,
      'spk_title': spkTitle,
      'note': note,
      'pieces_count': piecesCount,
      'wage_per_piece': wagePerPiece,
      'total_wage': totalWage,
      'status': status,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  String get formattedTotalWage => formatCurrency(totalWage);

  bool get isAdjustment => type == 'adjustment';
  bool get isPaid => status == 'PAID';

  PayrollRecord copyWith({
    String? id,
    String? userId,
    String? userName,
    String? type,
    String? spkId,
    String? spkTitle,
    String? note,
    int? piecesCount,
    double? wagePerPiece,
    double? totalWage,
    String? status,
    DateTime? createdAt,
  }) {
    return PayrollRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      spkId: spkId ?? this.spkId,
      spkTitle: spkTitle ?? this.spkTitle,
      note: note ?? this.note,
      piecesCount: piecesCount ?? this.piecesCount,
      wagePerPiece: wagePerPiece ?? this.wagePerPiece,
      totalWage: totalWage ?? this.totalWage,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
