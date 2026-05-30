import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/app_user.dart';
import '../../../settings/data/settings_providers.dart';
import '../../../settings/domain/wage_category.dart';
import '../../../inventory/domain/product.dart';
import '../../../inventory/data/inventory_providers.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/product_picker_sheet.dart';

class EmployeeQuickProductionBottomSheet extends ConsumerStatefulWidget {
  final AppUser employee;
  final String? initialProductGroup;

  const EmployeeQuickProductionBottomSheet({
    super.key,
    required this.employee,
    this.initialProductGroup,
  });

  @override
  ConsumerState<EmployeeQuickProductionBottomSheet> createState() =>
      _EmployeeQuickProductionBottomSheetState();
}

class _EmployeeQuickProductionBottomSheetState
    extends ConsumerState<EmployeeQuickProductionBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedProductGroup;
  Product? _selectedVariant;
  WageCategory? _selectedWageCategory;
  final _quantityController = TextEditingController();

  bool _isLoading = false;
  bool _isWageInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedProductGroup = widget.initialProductGroup;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVariant == null || _selectedWageCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pastikan semua form telah diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quantity = int.parse(
        _quantityController.text.replaceAll(RegExp(r'[^\d]'), ''),
      );
      final wage = _selectedWageCategory!.amount;

      final service = ref.read(quickProductionServiceProvider);

      await service.addQuickProduction(
        product: _selectedVariant!,
        tailor: widget.employee,
        quantity: quantity,
        wagePerPiece: wage,
        note: 'Ukuran: ${_selectedVariant!.size}',
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stok dan gaji berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showProductPicker(
    BuildContext context,
    Map<String, List<Product>> grouped,
    ColorScheme colors,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ProductPickerSheet(
          grouped: grouped,
          selectedKey: _selectedProductGroup,
          colors: colors,
          title: 'Pilih Produk',
          subtitle: 'Cari dan pilih produk yang baru saja dijahit',
          onSelected: (key) {
            setState(() {
              _selectedProductGroup = key;
              _selectedVariant = null; // Reset variant when product changes
              _selectedWageCategory = null; // Reset wage
              _isWageInitialized = false;
            });
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final productsAsync = ref.watch(productsStreamProvider);
    final wageCategoriesAsync = ref.watch(wageCategoriesStreamProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tambah Hasil Kerja',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Text(
                  'Catat hasil jahitan ${widget.employee.name}.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Product Selection ──
                Text(
                  'Produk',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                productsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (products) {
                    final grouped = <String, List<Product>>{};
                    for (final p in products) {
                      final key =
                          '${p.name}_${p.schoolLevels.join('_')}_${p.type}';
                      grouped.putIfAbsent(key, () => []).add(p);
                    }

                    String? selectedDisplayName;
                    if (_selectedProductGroup != null &&
                        grouped.containsKey(_selectedProductGroup)) {
                      final first = grouped[_selectedProductGroup]!.first;
                      selectedDisplayName =
                          '${first.name} ${first.schoolLevels.join('/')} - ${first.type}';
                    }

                    return GestureDetector(
                      onTap: () => _showProductPicker(context, grouped, colors),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F4),
                          borderRadius: BorderRadius.circular(12),
                          border: _selectedProductGroup != null
                              ? Border.all(
                                  color: colors.primary.withValues(alpha: 0.3),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedProductGroup != null
                                  ? Icons.checkroom
                                  : Icons.search,
                              size: 18,
                              color: _selectedProductGroup != null
                                  ? colors.primary
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                  selectedDisplayName ?? 'Pilih produk...',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: _selectedProductGroup != null
                                      ? Colors.black87
                                      : Colors.grey.shade400,
                                  fontWeight: _selectedProductGroup != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // ── Variant/Size Selection ──
                if (_selectedProductGroup != null) ...[
                  DropdownButtonFormField<Product>(
                    initialValue: _selectedVariant,
                    decoration: InputDecoration(
                      labelText: 'Ukuran',
                      labelStyle: GoogleFonts.inter(fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF2F4F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    items: (() {
                      if (productsAsync.value == null) return <DropdownMenuItem<Product>>[];
                      final filtered = productsAsync.value!
                          .where((p) => '${p.name}_${p.schoolLevels.join('_')}_${p.type}' == _selectedProductGroup)
                          .toList();
                      const sizeOrder = {'S': 0, 'M': 1, 'L': 2, 'XL': 3, 'XXL': 4, 'All Size': 5};
                      filtered.sort((a, b) {
                        final orderA = sizeOrder[a.size] ?? 99;
                        final orderB = sizeOrder[b.size] ?? 99;
                        return orderA.compareTo(orderB);
                      });
                      return filtered.map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Text('Ukuran ${v.size}'),
                        );
                      }).toList();
                    })(),
                    onChanged: (v) => setState(() => _selectedVariant = v),
                    validator: (v) => v == null ? 'Pilih ukuran' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      // Quantity
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: 'Jumlah (pcs)',
                            labelStyle: GoogleFonts.inter(fontSize: 14),
                            filled: true,
                            fillColor: const Color(0xFFF2F4F4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Wajib diisi';
                            if (int.tryParse(v) == null || int.parse(v) <= 0) {
                              return 'Tidak valid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Wage
                      Expanded(
                        flex: 2,
                        child: wageCategoriesAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (e, _) => Text('Error: $e'),
                          data: (categories) {
                            if (!_isWageInitialized &&
                                categories.isNotEmpty &&
                                _selectedProductGroup != null) {
                              final groupProducts = productsAsync.value
                                  ?.where((p) => '${p.name}_${p.schoolLevels.join('_')}_${p.type}' == _selectedProductGroup)
                                  .toList();
                                  
                              if (groupProducts != null && groupProducts.isNotEmpty) {
                                final firstProduct = groupProducts.first;
                                final nameLower = firstProduct.name.toLowerCase();
                                final typeLower = firstProduct.type.toLowerCase();
                                
                                // First, try matching by product name
                                for (final cat in categories) {
                                  final catName = cat.name.toLowerCase();
                                  if (nameLower.contains(catName) || catName.contains(nameLower)) {
                                    _selectedWageCategory = cat;
                                    break;
                                  }
                                }
                                
                                // Second, if not found, try matching by product type
                                if (_selectedWageCategory == null) {
                                  for (final cat in categories) {
                                    final catName = cat.name.toLowerCase();
                                    if (typeLower.contains(catName) || catName.contains(typeLower)) {
                                      _selectedWageCategory = cat;
                                      break;
                                    }
                                  }
                                }

                                // Fallback if name or type contains 'baju'
                                if (_selectedWageCategory == null &&
                                    (nameLower.contains('baju') || typeLower.contains('baju'))) {
                                  try {
                                    _selectedWageCategory = categories.firstWhere(
                                      (c) => c.name.toLowerCase().contains('baju'),
                                    );
                                  } catch (_) {}
                                }
                              }

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _isWageInitialized = true;
                                  });
                                }
                              });
                            }

                            return DropdownButtonFormField<WageCategory>(
                              initialValue: _selectedWageCategory,
                              decoration: InputDecoration(
                                labelText: 'Kategori Upah',
                                labelStyle: GoogleFonts.inter(fontSize: 14),
                                filled: true,
                                fillColor: const Color(0xFFF2F4F4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              items: categories.map((cat) {
                                final formattedAmount = formatCurrency(cat.amount);

                                return DropdownMenuItem(
                                  value: cat,
                                  child: Text('${cat.name} ($formattedAmount)'),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedWageCategory = v),
                              validator: (v) => v == null ? 'Pilih upah' : null,
                              isExpanded: true,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _selectedProductGroup == null)
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Simpan Hasil Kerja',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
