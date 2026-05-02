import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/currency_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:rumah_jahit/features/pos/data/pos_providers.dart';
import 'package:rumah_jahit/features/inventory/domain/product.dart';

import '../../../../core/widgets/product_card.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/custom_text_field.dart';
import 'package:flutter/services.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();

  final List<String> _schoolLevels = [
    'SD',
    'MIN',
    'SMP',
    'SMA',
  ];

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
    final screenWidth = MediaQuery.of(context).size.width;
    final schoolLevelFilter = ref.watch(posSchoolLevelProvider);
    final typeFilter = ref.watch(posTypeProvider);
    final filteredProducts = ref.watch(filteredProductsProvider);
    final cart = ref.watch(cartProvider);

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

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        scrolledUnderElevation: 0,
        title: Text(
          'Rumah Jahit',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: colors.primary,
            fontSize: 20,
          ),
        ),
        actions: [
          Center(
            child: IconButton(
              onPressed: () {
                context.push('/pos/history');
              },
              icon: Icon(
                Icons.receipt_long_outlined,
                color: colors.primary,
                size: 26,
              ),
            ),
          ),
          Center(
            child: IconButton(
              onPressed: () {
                context.push('/pos/checkout');
              },
              icon: Badge(
                label: Text(cart.totalItems.toString()),
                backgroundColor: colors.primary,
                isLabelVisible: cart.totalItems > 0,
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: colors.primary,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                filled: true,
                fillColor: const Color(0xFFF2F4F4),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. Horizontal Filter Chips
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
                      ref.read(posSchoolLevelProvider.notifier).state = null;
                      ref.read(posTypeProvider.notifier).state = null;
                    } else if (_schoolLevels.contains(filter)) {
                      if (schoolLevelFilter == filter) {
                        ref.read(posSchoolLevelProvider.notifier).state = null;
                      } else {
                        ref.read(posSchoolLevelProvider.notifier).state = filter;
                      }
                    } else if (_productTypes.contains(filter)) {
                      if (typeFilter == filter) {
                        ref.read(posTypeProvider.notifier).state = null;
                      } else {
                        ref.read(posTypeProvider.notifier).state = filter;
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary
                          : const Color(0xFFF2F4F4),
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
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
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
          const SizedBox(height: 12),

          // 3. Product Grid — Grouped by name+type+schoolLevels
          Expanded(
            child: filteredProducts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (products) {
                // Group products by name+type
                final grouped = <String, List<Product>>{};
                for (final p in products) {
                  final key =
                      '${p.name}_${p.schoolLevels.join(', ')}_${p.type}';
                  grouped.putIfAbsent(key, () => []).add(p);
                }
                final groupKeys = grouped.keys.toList();

                if (groupKeys.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada produk ditemukan',
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final crossAxisCount = screenWidth >= 1024 ? 5 : (screenWidth >= 768 ? 4 : 2);
                final childAspectRatio = screenWidth >= 768 ? 0.75 : 0.60;

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: groupKeys.length,
                  itemBuilder: (context, index) {
                    final key = groupKeys[index];
                    final variants = grouped[key]!;
                    final representative = variants.first;

                    // Price range display
                    final prices = variants.map((v) => v.price).toList()
                      ..sort();
                    final priceDisplay = prices.first == prices.last
                        ? representative.formattedPrice
                        : '${formatCurrency(prices.first)} - ${formatCurrency(prices.last)}';

                    // Sizes available
                    final sizes = variants.map((v) => v.size).toList();

                    final levelsString = representative.schoolLevels.join('/');

                    return GestureDetector(
                      onTap: () {
                        _showSizePicker(context, ref, variants, sizes);
                      },
                      child: ProductCard(
                        name:
                            '${representative.name} - $levelsString\n${representative.type}',
                        price: priceDisplay,
                        imageUrl:
                            representative.imageUrl ??
                            'https://picsum.photos/seed/${representative.id}/300/300',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // FAB Cart Checkout POS
      floatingActionButton: cart.isEmpty
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: 110.0),
              child: FloatingActionButton.extended(
                onPressed: () {
                  context.push('/pos/checkout');
                },
                backgroundColor: const Color(0xFF004D4C),
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                ),
                label: Row(
                  children: [
                    Text(
                      '${cart.totalItems} Items',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatCurrency(cart.grandTotal),
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showSizePicker(
    BuildContext context,
    WidgetRef ref,
    List<Product> variants,
    List<String> sizes,
  ) {
    final colors = Theme.of(context).colorScheme;

    // We no longer skip the bottom sheet if variants.length == 1
    // because we want to give the user the "Ukuran Kustom" option.

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      // isScrollControlled: true,
      // useSafeArea: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final representative = variants.first;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${representative.name} - ${representative.schoolLevels.join('/')} - ${representative.type}',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih ukuran:',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 600;
                  final columnCount = isTablet ? 6 : 3;
                  final itemWidth = (constraints.maxWidth - (10 * (columnCount - 1))) / columnCount;
                  
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        variants.map((variant) {
                          return GestureDetector(
                            onTap: () {
                              ref.read(cartProvider.notifier).addItem(variant);
                              Navigator.pop(ctx);
                              SnackBarUtils.show(
                                context,
                                '${variant.name} (${variant.size}) ditambahkan',
                                showAboveBar: true,
                              );
                            },
                            child: Container(
                              width: itemWidth,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F4F4),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    variant.size,
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: colors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      variant.formattedPrice,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Stok: ${variant.currentStock}',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList()..add(
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              _showProductCustomDialog(
                                context,
                                ref,
                                variants.first,
                              );
                            },
                            child: Container(
                              width: itemWidth,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    color: Colors.amber.shade800,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ukuran\nKustom',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber.shade800,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProductCustomDialog(
    BuildContext context,
    WidgetRef ref,
    Product baseProduct,
  ) {
    final descController = TextEditingController();
    final priceController = TextEditingController(
      text: formatCurrency(baseProduct.price),
    );
    final qtyController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Ukuran Kustom - ${baseProduct.name}',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text(
                //   'Pesanan ini akan langsung membuat SPK otomatis dengan tujuan pembuatan sesuai info pelanggan. Upah jahit akan disesuaikan otomatis dengan jenis pakaian.',
                //   style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                // ),
                // const SizedBox(height: 16),
                CustomTextField(
                  controller: descController,
                  label: 'Detail Ukuran (Opsional)*',
                  hint: 'P: 60, L: 45 / Jumbo',
                  icon: Icons.straighten,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Detail ukuran wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: priceController,
                  label: 'Harga per pcs*',
                  hint: '0',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    RupiahInputFormatter(),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    final digits = v.replaceAll(RegExp(r'[^\d]'), '');
                    if (int.tryParse(digits) == null || int.parse(digits) <= 0) {
                      return 'Harga > 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: qtyController,
                  label: 'Kuantitas *',
                  hint: '1',
                  icon: Icons.tag,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (int.tryParse(v) == null || int.parse(v) <= 0) {
                      return 'Min. 1';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final priceDigits = priceController.text.replaceAll(
                RegExp(r'[^\d]'),
                '',
              );

              final item = CustomCartItem(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                name: baseProduct.name,
                description: descController.text.trim(),
                price: double.parse(priceDigits),
                quantity: int.parse(qtyController.text),
                productType: baseProduct.type,
                baseProductId: baseProduct.id,
              );

              ref.read(cartProvider.notifier).addCustomItem(item);
              Navigator.pop(ctx);
              SnackBarUtils.show(
                context,
                '${baseProduct.name} Kustom ditambahkan ke keranjang',
                showAboveBar: true,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D4C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Tambahkan',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
