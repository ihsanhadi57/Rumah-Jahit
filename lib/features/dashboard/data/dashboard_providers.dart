import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inventory/domain/raw_material.dart';
import '../../inventory/domain/production_order.dart';
import '../../inventory/data/inventory_providers.dart';
import '../../pos/domain/transaction_model.dart';
import '../../pos/data/pos_providers.dart';

// ── Dashboard Aggregation Providers ──

/// Today's total revenue (sum of grand_total from today's transactions)
final todayRevenueProvider = Provider<AsyncValue<double>>((ref) {
  final txAsync = ref.watch(todayTransactionsProvider);
  return txAsync.whenData((transactions) {
    return transactions
        .where((tx) => ['SUCCESS', 'SUCCESSFUL', 'PENDING'].contains(tx.status.toUpperCase()))
        .fold(0.0, (sum, tx) => sum + tx.grandTotal);
  });
});

/// Low-stock raw materials for dashboard alert
final dashboardLowStockProvider =
    Provider<AsyncValue<List<RawMaterial>>>((ref) {
  return ref.watch(lowStockMaterialsProvider);
});

/// Recent production orders for dashboard (top 5)
final recentSpkProvider =
    Provider<AsyncValue<List<ProductionOrder>>>((ref) {
  final ordersAsync = ref.watch(activeOrdersStreamProvider);
  return ordersAsync.whenData((orders) {
    return orders.take(5).toList();
  });
});

/// Recent transactions for dashboard (top 5 today)
final recentTransactionsProvider =
    Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final txAsync = ref.watch(todayTransactionsProvider);
  return txAsync.whenData((transactions) {
    return transactions.take(5).toList();
  });
});
