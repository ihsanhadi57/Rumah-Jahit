import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../domain/finance_transaction.dart';

final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

final financeDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final financeTransactionsProvider = StreamProvider<List<FinanceTransaction>>((
  ref,
) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('finance_transactions')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => FinanceTransaction.fromFirestore(doc))
            .toList(),
      );
});

final filteredFinanceTransactionsProvider =
    Provider<AsyncValue<List<FinanceTransaction>>>((ref) {
      final transactionsAsync = ref.watch(financeTransactionsProvider);
      final range = ref.watch(financeDateRangeProvider);

      return transactionsAsync.whenData((list) {
        if (range == null) return list;
        // Set range end to the end of the day
        final endOfDay = DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
          23,
          59,
          59,
        );
        return list.where((tx) {
          return tx.createdAt.isAfter(range.start) &&
              tx.createdAt.isBefore(endOfDay);
        }).toList();
      });
    });

final totalBalanceProvider = Provider<AsyncValue<double>>((ref) {
  // Use filtered transactions so balance reflects selected period
  final transactions = ref.watch(filteredFinanceTransactionsProvider);
  return transactions.whenData((list) {
    return list.fold(0.0, (previousValue, element) {
      if (element.type == FinanceTransactionType.income) {
        return previousValue + element.amount;
      } else {
        return previousValue - element.amount;
      }
    });
  });
});

final totalIncomeProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(filteredFinanceTransactionsProvider).whenData((list) {
    return list
        .where((tx) => tx.type == FinanceTransactionType.income)
        .fold(0.0, (total, tx) => total + tx.amount);
  });
});

final totalExpenseProvider = Provider<AsyncValue<double>>((ref) {
  return ref.watch(filteredFinanceTransactionsProvider).whenData((list) {
    return list
        .where((tx) => tx.type == FinanceTransactionType.expense)
        .fold(0.0, (total, tx) => total + tx.amount);
  });
});

class FinanceRepository {
  final FirebaseFirestore _firestore;

  FinanceRepository(this._firestore);

  Future<void> addTransaction(FinanceTransaction transaction) async {
    await _firestore
        .collection('finance_transactions')
        .add(transaction.toFirestore());
  }

  Future<void> deleteTransaction(String id) async {
    await _firestore.collection('finance_transactions').doc(id).delete();
  }
}

final financeRepositoryProvider = Provider((ref) {
  return FinanceRepository(ref.watch(firestoreProvider));
});
