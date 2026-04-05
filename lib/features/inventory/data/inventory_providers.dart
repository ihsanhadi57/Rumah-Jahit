import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore_for_file: deprecated_member_use
import 'package:flutter_riverpod/legacy.dart';

import '../domain/raw_material.dart';
import '../domain/product.dart';
import '../domain/production_order.dart';
import 'raw_material_repository.dart';
import 'product_repository.dart';
import 'production_order_repository.dart';

// ── Repository Providers ──

final rawMaterialRepositoryProvider = Provider<RawMaterialRepository>((ref) {
  return RawMaterialRepository();
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final productionOrderRepositoryProvider =
    Provider<ProductionOrderRepository>((ref) {
  return ProductionOrderRepository();
});

// ── Stream Providers ──

final rawMaterialsStreamProvider = StreamProvider<List<RawMaterial>>((ref) {
  return ref.watch(rawMaterialRepositoryProvider).watchAll();
});

final rawMaterialByIdProvider =
    StreamProvider.family<RawMaterial?, String>((ref, id) {
  return ref.watch(rawMaterialRepositoryProvider).watchById(id);
});

final lowStockMaterialsProvider = StreamProvider<List<RawMaterial>>((ref) {
  return ref.watch(rawMaterialRepositoryProvider).watchLowStock();
});

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchAll();
});

final productionOrdersStreamProvider =
    StreamProvider<List<ProductionOrder>>((ref) {
  return ref.watch(productionOrderRepositoryProvider).watchAll();
});

final activeOrdersStreamProvider =
    StreamProvider<List<ProductionOrder>>((ref) {
  return ref.watch(productionOrderRepositoryProvider).watchActive();
});

// ── Inventory Products Filtering ──

final inventorySearchQueryProvider = StateProvider<String>((ref) => '');
final inventorySchoolLevelProvider = StateProvider<String?>((ref) => null);
final inventoryTypeProvider = StateProvider<String?>((ref) => null);

final inventoryFilteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  final query = ref.watch(inventorySearchQueryProvider).toLowerCase();
  final schoolLevel = ref.watch(inventorySchoolLevelProvider);
  final type = ref.watch(inventoryTypeProvider);

  return productsAsync.whenData((products) {
    var filtered = products;

    if (schoolLevel != null) {
      filtered = filtered.where((p) => p.schoolLevels.contains(schoolLevel)).toList();
    }

    if (type != null) {
      filtered = filtered.where((p) => p.type.toLowerCase().contains(type.toLowerCase())).toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.displayName.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  });
});
