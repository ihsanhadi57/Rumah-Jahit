import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/inventory_providers.dart';
import '../../domain/product.dart';
import 'barang_jadi_card.dart';

class BarangJadiTabView extends ConsumerStatefulWidget {
  const BarangJadiTabView({super.key});

  @override
  ConsumerState<BarangJadiTabView> createState() => _BarangJadiTabViewState();
}

class _BarangJadiTabViewState extends ConsumerState<BarangJadiTabView> {
  final _searchController = TextEditingController();

  final List<String> _schoolLevels = ['SD', 'MIN', 'SMP', 'SMA'];
  final List<String> _productTypes = [
    'Lengan Panjang',
    'Lengan Pendek',
    'Celana',
    'Rok',
    'Jas',
    'Perlengkapan Sekolah',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final productsAsync = ref.watch(inventoryFilteredProductsProvider);
    final schoolLevelFilter = ref.watch(inventorySchoolLevelProvider);
    final typeFilter = ref.watch(inventoryTypeProvider);

    List<String> activeFiltersList = ['Semua'];
    
    if (schoolLevelFilter != null) {
      activeFiltersList.add(schoolLevelFilter);
    } else {
      activeFiltersList.addAll(_schoolLevels);
    }

    if (typeFilter != null) {
      activeFiltersList.add(typeFilter);
    } else {
      activeFiltersList.addAll(_productTypes);
    }

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child:
            Text('Error: $error', style: GoogleFonts.inter(color: Colors.red)),
      ),
      data: (products) => _buildContent(context, products, activeFiltersList, schoolLevelFilter, typeFilter, colors),
    );
  }

  Widget _buildContent(BuildContext context, List<Product> products, List<String> activeFiltersList, String? schoolLevelFilter, String? typeFilter, ColorScheme colors) {
    // Group products by name for display as cards with variants
    final grouped = <String, List<Product>>{};
    for (final product in products) {
      final key = '${product.name}_${product.type}_${product.schoolLevels.join('_')}';
      grouped.putIfAbsent(key, () => []).add(product);
    }

    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(inventorySearchQueryProvider.notifier).state = value;
              },
              decoration: const InputDecoration(
                hintText: 'Cari barang jadi...',
                prefixIcon: Icon(Icons.search, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        
        // Filter Chips
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: activeFiltersList.length,
            itemBuilder: (context, index) {
              final filter = activeFiltersList[index];
              final isSelected = filter == schoolLevelFilter || 
                                 filter == typeFilter || 
                                 (filter == 'Semua' && schoolLevelFilter == null && typeFilter == null);

              return GestureDetector(
                onTap: () {
                  if (filter == 'Semua') {
                    ref.read(inventorySchoolLevelProvider.notifier).state = null;
                    ref.read(inventoryTypeProvider.notifier).state = null;
                  } else if (_schoolLevels.contains(filter)) {
                    if (schoolLevelFilter == filter) {
                      ref.read(inventorySchoolLevelProvider.notifier).state = null;
                    } else {
                      ref.read(inventorySchoolLevelProvider.notifier).state = filter;
                    }
                  } else if (_productTypes.contains(filter)) {
                    if (typeFilter == filter) {
                      ref.read(inventoryTypeProvider.notifier).state = null;
                    } else {
                      ref.read(inventoryTypeProvider.notifier).state = filter;
                    }
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary : const Color(0xFFF2F4F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        filter,
                        style: GoogleFonts.inter(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      if (isSelected && filter != 'Semua') ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.close, size: 14, color: Colors.white),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Product List
        Expanded(
          child: products.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checkroom_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        grouped.isEmpty && _searchController.text.isNotEmpty || schoolLevelFilter != null || typeFilter != null
                            ? 'Tidak ada produk ditemukan'
                            : 'Belum ada barang jadi',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (grouped.isEmpty && _searchController.text.isEmpty && schoolLevelFilter == null && typeFilter == null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tap + untuk menambahkan produk baru',
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 768;
                  
                  final items = grouped.entries.map((entry) {
                    final groupProducts = entry.value;
                    final first = groupProducts.first;
                    final totalStock = groupProducts.fold(
                        0, (sum, p) => sum + p.currentStock);
                    final variants = <String, String>{};
                    for (final p in groupProducts) {
                      variants[p.size] = p.currentStock.toString();
                    }

                    return GestureDetector(
                      onTap: () {
                        context.go('/inventory/product-detail', extra: {
                          'name': first.name,
                          'type': first.type,
                          'schoolLevels': first.schoolLevels,
                        });
                      },
                      child: BarangJadiCard(
                        category: first.schoolLevels.join('/'),
                        title: '${first.name} - ${first.type}',
                        subtitle: first.formattedPrice,
                        stock: totalStock.toString(),
                        unit: 'pcs',
                        variants: variants,
                        price: first.formattedPrice,
                        imageUrl: first.imageUrl ?? '',
                      ),
                    );
                  }).toList();

                  if (isTablet) {
                    final isLargeTablet = constraints.maxWidth >= 1024;
                    final columnCount = isLargeTablet ? 3 : 2;

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: 310, // Increased to 310 to give ample room for 2-line titles and paddings without overflowing
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return items[index];
                      },
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: items[index],
                      );
                    },
                  );
                },
              ),
        ),
      ],
    );
  }
}
