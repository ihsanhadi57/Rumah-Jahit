import 'package:cloud_firestore/cloud_firestore.dart';

class TailorAnnualStat {
  final String userId;
  final String userName;
  final int year;
  final int totalPieces;
  final double totalWage;
  final DateTime updatedAt;

  const TailorAnnualStat({
    required this.userId,
    required this.userName,
    required this.year,
    required this.totalPieces,
    required this.totalWage,
    required this.updatedAt,
  });

  factory TailorAnnualStat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TailorAnnualStat(
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      year: (data['year'] ?? DateTime.now().year).toInt(),
      totalPieces: (data['total_pieces'] ?? 0).toInt(),
      totalWage: (data['total_wage'] ?? 0).toDouble(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'user_name': userName,
      'year': year,
      'total_pieces': totalPieces,
      'total_wage': totalWage,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
