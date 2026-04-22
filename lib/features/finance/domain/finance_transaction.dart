import 'package:cloud_firestore/cloud_firestore.dart';

enum FinanceTransactionType { income, expense }

class FinanceTransaction {
  final String id;
  final String title;
  final double amount;
  final FinanceTransactionType type;
  final DateTime createdAt;
  final String? category;
  final String? note;

  FinanceTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.category,
    this.note,
  });

  factory FinanceTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FinanceTransaction(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      type: data['type'] == 'income'
          ? FinanceTransactionType.income
          : FinanceTransactionType.expense,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      category: data['category'],
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'type': type == FinanceTransactionType.income ? 'income' : 'expense',
      'createdAt': Timestamp.fromDate(createdAt),
      'category': category,
      'note': note,
    };
  }
}
