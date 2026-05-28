import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../payroll/data/payroll_providers.dart';
import '../../../payroll/domain/app_user.dart';
import '../../../settings/data/settings_providers.dart';
import '../../../settings/domain/wage_category.dart';
import '../../domain/product.dart';
import '../../data/inventory_providers.dart';

class _RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final number = int.parse(digitsOnly);
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    final prefixed = 'Rp ${buffer.toString()}';
    return TextEditingValue(
      text: prefixed,
      selection: TextSelection.collapsed(offset: prefixed.length),
    );
  }
}

class QuickProductionBottomSheet extends ConsumerStatefulWidget {
  final List<Product> variants;
  final String productName;
  final String productType;

  const QuickProductionBottomSheet({
    super.key,
    required this.variants,
    required this.productName,
    required this.productType,
  });

  @override
  ConsumerState<QuickProductionBottomSheet> createState() =>
      _QuickProductionBottomSheetState();
}

class _QuickProductionBottomSheetState
    extends ConsumerState<QuickProductionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  
  Product? _selectedVariant;
  AppUser? _selectedTailor;
  WageCategory? _selectedWageCategory;
  final _quantityController = TextEditingController();
  
  bool _isLoading = false;
  bool _isWageInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.variants.isNotEmpty) {
      _selectedVariant = widget.variants.first;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVariant == null || _selectedTailor == null || _selectedWageCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pastikan semua form telah diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quantity = int.parse(_quantityController.text.replaceAll(RegExp(r'[^\d]'), ''));
      final wage = _selectedWageCategory!.amount;

      final service = ref.read(quickProductionServiceProvider);
      
      await service.addQuickProduction(
        product: _selectedVariant!,
        tailor: _selectedTailor!,
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tailorsAsync = ref.watch(tailorsStreamProvider);
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
                      'Setoran Cepat',
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
                  'Tambah stok dan catat gaji penjahit.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // Size Dropdown
                DropdownButtonFormField<Product>(
                  value: _selectedVariant,
                  decoration: InputDecoration(
                    labelText: 'Ukuran Produk',
                    labelStyle: GoogleFonts.inter(fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF2F4F4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: widget.variants.map((v) {
                    return DropdownMenuItem(
                      value: v,
                      child: Text('Ukuran ${v.size}'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedVariant = v),
                  validator: (v) => v == null ? 'Pilih ukuran' : null,
                ),
                const SizedBox(height: 16),

                // Tailor Dropdown
                tailorsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Gagal memuat penjahit: $e'),
                  data: (tailors) {
                    return DropdownButtonFormField<AppUser>(
                      value: _selectedTailor,
                      decoration: InputDecoration(
                        labelText: 'Penjahit',
                        labelStyle: GoogleFonts.inter(fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFF2F4F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: tailors.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t.name),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedTailor = v),
                      validator: (v) => v == null ? 'Pilih penjahit' : null,
                    );
                  },
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
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Wajib diisi';
                          if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Tidak valid';
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
                          if (!_isWageInitialized && categories.isNotEmpty) {
                            // find default
                            final typeLower = widget.productType.toLowerCase();
                            for (final cat in categories) {
                              final catName = cat.name.toLowerCase();
                              if (typeLower.contains(catName) || catName.contains(typeLower)) {
                                _selectedWageCategory = cat;
                                break;
                              }
                            }
                            // Hardcode request from user: if 'baju', default to first category containing 'baju'
                            if (_selectedWageCategory == null && typeLower.contains('baju')) {
                               try {
                                 _selectedWageCategory = categories.firstWhere((c) => c.name.toLowerCase().contains('baju'));
                               } catch (_) {}
                            }
                            // Must use post frame callback to set state if building
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _isWageInitialized = true;
                                });
                              }
                            });
                          }

                          return DropdownButtonFormField<WageCategory>(
                            value: _selectedWageCategory,
                            decoration: InputDecoration(
                              labelText: 'Kategori Upah',
                              labelStyle: GoogleFonts.inter(fontSize: 14),
                              filled: true,
                              fillColor: const Color(0xFFF2F4F4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            items: categories.map((cat) {
                              final str = cat.amount.toInt().toString();
                              final buffer = StringBuffer();
                              for (int i = 0; i < str.length; i++) {
                                if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
                                buffer.write(str[i]);
                              }
                              final formattedAmount = 'Rp ${buffer.toString()}';

                              return DropdownMenuItem(
                                value: cat,
                                child: Text('${cat.name} ($formattedAmount)'),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedWageCategory = v),
                            validator: (v) => v == null ? 'Pilih upah' : null,
                            isExpanded: true,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
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
                            'Simpan Setoran',
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
