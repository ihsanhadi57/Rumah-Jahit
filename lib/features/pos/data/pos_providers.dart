import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore_for_file: deprecated_member_use
import 'package:flutter_riverpod/legacy.dart';

import '../../inventory/domain/product.dart';
import '../../inventory/data/inventory_providers.dart';
import '../domain/transaction_model.dart';
import 'transaction_repository.dart';

// Re-export cart provider for convenience
export 'cart_notifier.dart'
    show cartProvider, CartState, CartItem, CartNotifier, CustomCartItem;

// ── Repository Provider ──

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

// ── Filtered Products for POS ──

/// Currently selected school level filter
final posSchoolLevelProvider = StateProvider<String?>((ref) => null);

/// Currently selected product type filter
final posTypeProvider = StateProvider<String?>((ref) => null);

/// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Products filtered by selected filters and search query
final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  final schoolLevelFilter = ref.watch(posSchoolLevelProvider);
  final typeFilter = ref.watch(posTypeProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return productsAsync.whenData((products) {
    var filtered = products;

    // Apply school level filter
    if (schoolLevelFilter != null) {
      filtered = filtered.where((p) {
        return p.schoolLevels.contains(schoolLevelFilter);
      }).toList();
    }

    // Apply product type filter
    if (typeFilter != null) {
      filtered = filtered.where((p) {
        return p.type.toLowerCase().contains(typeFilter.toLowerCase());
      }).toList();
    }

    // Apply search query
    if (query.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.displayName.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  });
});

// ── Transaction Streams ──

final todayTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchToday();
});

final allTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchAll();
});
