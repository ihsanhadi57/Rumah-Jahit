import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:rumah_jahit/core/services/image_upload_service.dart';
import 'package:rumah_jahit/features/inventory/data/inventory_providers.dart';
import 'package:rumah_jahit/features/inventory/domain/product.dart';
import 'package:rumah_jahit/features/inventory/domain/production_order.dart';
import 'package:rumah_jahit/features/inventory/presentation/widgets/quick_production_bottom_sheet.dart';

/// Rupiah formatter (shared)
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

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productName;
  final String productType;
  final List<String> schoolLevels;

  const ProductDetailScreen({
    super.key,
    required this.productName,
    required this.productType,
    this.schoolLevels = const [],
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _isPopping = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Detail Produk',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: colors.primary,
          ),
        ),
        actions: [
          // Delete all variants
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
            onPressed: () => _confirmDeleteAll(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e', style: GoogleFonts.inter(color: Colors.red)),
        ),
        data: (allProducts) {
          // Filter to only this product's variants
          const sizeOrder = ['S', 'M', 'L', 'XL', 'XXL'];
          final variants =
              allProducts
                  .where(
                    (p) =>
                        p.name == widget.productName &&
                        p.type == widget.productType &&
                        p.schoolLevels.join('_') ==
                            widget.schoolLevels.join('_'),
                  )
                  .toList()
                ..sort((a, b) {
                  final ai = sizeOrder.indexOf(a.size.toUpperCase());
                  final bi = sizeOrder.indexOf(b.size.toUpperCase());
                  final aIdx = ai == -1 ? sizeOrder.length : ai;
                  final bIdx = bi == -1 ? sizeOrder.length : bi;
                  return aIdx.compareTo(bIdx);
                });

          if (variants.isEmpty) {
            if (!_isPopping) {
              _isPopping = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.of(context).pop();
              });
            }
            // Always return early — never access variants.first on empty list
            return const SizedBox.shrink();
          }

          final first = variants.first;
          final totalStock = variants.fold(0, (sum, p) => sum + p.currentStock);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            children: [
              // ── Product Image ──
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 220,
                  width: double.infinity,
                  color: const Color(0xFFF2F4F4),
                  child: first.imageUrl != null && first.imageUrl!.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              first.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _buildNoImagePlaceholder(),
                            ),
                            // Change Image overlay button
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => _changeImage(variants),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Ganti',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : GestureDetector(
                          onTap: () => _changeImage(variants),
                          child: _buildNoImagePlaceholder(),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Product Info ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '${first.name} - ${first.type}',
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF001F1F),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showEditNameDialog(variants),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: first.schoolLevels.map((level) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      level,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Total Stock summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total Stok',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$totalStock pcs',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Size Variants ──
              Text(
                'VARIAN UKURAN',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              ...variants.map((variant) => _buildVariantCard(variant, colors)),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => QuickProductionBottomSheet(
                        variants: variants,
                        productName: widget.productName,
                        productType: widget.productType,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Tambah Stok',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary.withValues(alpha: 0.1),
                    foregroundColor: colors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Riwayat Setoran dari SPK ──
              _buildSetoranHistory(ref, variants, colors),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap untuk tambah foto',
          style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildVariantCard(Product variant, ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Size badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              variant.size,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant.formattedPrice,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF001F1F),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      variant.currentStock > 10
                          ? Icons.check_circle
                          : Icons.warning,
                      size: 14,
                      color: variant.currentStock > 10
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stok: ${variant.currentStock} pcs',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit
              GestureDetector(
                onTap: () => _showEditDialog(variant),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Delete
              GestureDetector(
                onTap: () => _confirmDeleteVariant(variant),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Riwayat Setoran dari SPK ──
  Widget _buildSetoranHistory(
    WidgetRef ref,
    List<Product> variants,
    ColorScheme colors,
  ) {
    final ordersAsync = ref.watch(productionOrdersStreamProvider);

    return ordersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (allOrders) {
        // Collect variant product IDs for this product group
        final variantIds = variants.map((v) => v.id).toSet();

        // Collect all reports from all SPKs that reference this product's variants
        final entries = <_SetoranEntry>[];

        for (final order in allOrders) {
          // Check if this SPK has items referencing any of our variant IDs
          final matchingVariantIds = order.items
              .where((item) => variantIds.contains(item.productId))
              .map((item) => item.productId)
              .toSet();

          if (matchingVariantIds.isEmpty) continue;

          for (final report in order.reports) {
            // For restock with variant size, check if the size matches one of our variants
            if (report.variantSize != null) {
              final matchesSize = variants.any(
                (v) => v.size == report.variantSize,
              );
              if (!matchesSize) continue;
            }

            entries.add(
              _SetoranEntry(
                report: report,
                spkTitle: order.title,
                spkId: order.id,
              ),
            );
          }
        }

        if (entries.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort by date descending
        entries.sort(
          (a, b) => b.report.createdAt.compareTo(a.report.createdAt),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RIWAYAT SETORAN DARI SPK',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ...entries.map((entry) {
              final r = entry.report;
              final dateStr =
                  '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.spkTitle,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: colors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              r.userName,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+${r.quantity} pcs${r.variantSize != null ? ' (${r.variantSize})' : ''}',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // ── Image Change ──
  Future<void> _changeImage(List<Product> variants) async {
    final file = await ImageUploadService.pickFromGallery();
    if (file == null || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Delete old image if exists
      if (variants.first.imageUrl != null) {
        await ImageUploadService.deleteImage(variants.first.imageUrl!);
      }

      final url = await ImageUploadService.uploadProductImage(
        file,
        variants.first.name,
      );

      // Update all variants with new image URL
      final repo = ref.read(productRepositoryProvider);
      await repo.updateBatch(
        variants.map((v) => v.copyWith(imageUrl: url)).toList(),
      );

      if (mounted) Navigator.of(context).pop(); // close loading
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Edit Variant (Price & Stock) ──
  void _showEditDialog(Product variant) {
    final priceController = TextEditingController(
      text: 'Rp ${_formatNumber(variant.price.toInt())}',
    );
    final stockController = TextEditingController(
      text: variant.currentStock.toString(),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Stok & Harga ${variant.size}',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF003D3D),
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Price
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _RupiahInputFormatter(),
                ],
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Harga',
                  labelStyle: GoogleFonts.inter(fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF2F4F4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  final raw = v.replaceAll(RegExp(r'[^\d]'), '');
                  if (raw.isEmpty || int.tryParse(raw) == 0) {
                    return 'Harga tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Stock
              TextFormField(
                controller: stockController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Stok',
                  labelStyle: GoogleFonts.inter(fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF2F4F4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final rawPrice = priceController.text.replaceAll(
                RegExp(r'[^\d]'),
                '',
              );
              final newPrice = double.tryParse(rawPrice) ?? variant.price;
              final newStock =
                  int.tryParse(stockController.text) ?? variant.currentStock;

              final updated = variant.copyWith(
                price: newPrice,
                currentStock: newStock,
              );
              await ref.read(productRepositoryProvider).update(updated);

              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D4C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Simpan',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit Product Name & Type (Global for all sizes) ──
  void _showEditNameDialog(List<Product> variants) {
    final first = variants.first;
    final nameController = TextEditingController(text: first.name);

    final productTypes = [
      'Lengan Panjang',
      'Lengan Pendek',
      'Celana',
      'Rok',
      'Jas',
      'Perlengkapan Sekolah',
    ];

    String? selectedType = first.type;
    // Ensure current type is in the list
    if (!productTypes.contains(selectedType)) {
      productTypes.add(selectedType);
    }

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Edit Nama & Tipe',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: const Color(0xFF003D3D),
              ),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Nama Barang',
                      labelStyle: GoogleFonts.inter(fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF2F4F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Tipe',
                      labelStyle: GoogleFonts.inter(fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF2F4F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: productTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type,
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedType = v);
                      }
                    },
                    validator: (v) => (v == null) ? 'Wajib pilih tipe' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Batal',
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final newName = nameController.text.trim();
                  final newType = selectedType!;

                  if (newName == first.name && newType == first.type) {
                    Navigator.pop(ctx);
                    return;
                  }

                  final repo = ref.read(productRepositoryProvider);
                  await repo.updateBatch(
                    variants
                        .map((v) => v.copyWith(name: newName, type: newType))
                        .toList(),
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D4C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Simpan',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Delete Variant ──
  void _confirmDeleteVariant(Product variant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Varian ${variant.size}?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Varian ukuran ${variant.size} akan dihapus permanen.',
          style: GoogleFonts.inter(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(productRepositoryProvider).delete(variant.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Delete All Variants ──
  void _confirmDeleteAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Semua Varian?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Semua varian "${widget.productName} - ${widget.productType}" akan dihapus permanen.',
          style: GoogleFonts.inter(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final allProducts = ref.read(productsStreamProvider).value ?? [];
              final toDelete = allProducts
                  .where(
                    (p) =>
                        p.name == widget.productName &&
                        p.type == widget.productType &&
                        p.schoolLevels.join('_') ==
                            widget.schoolLevels.join('_'),
                  )
                  .toList();

              // Delete image
              if (toDelete.isNotEmpty && toDelete.first.imageUrl != null) {
                await ImageUploadService.deleteImage(toDelete.first.imageUrl!);
              }

              final repo = ref.read(productRepositoryProvider);
              for (final p in toDelete) {
                await repo.delete(p.id);
              }

              if (ctx.mounted) Navigator.pop(ctx);
              // Parent screen will auto-pop due to empty variants check
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Hapus Semua',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

class _SetoranEntry {
  final ProductionReport report;
  final String spkTitle;
  final String spkId;

  const _SetoranEntry({
    required this.report,
    required this.spkTitle,
    required this.spkId,
  });
}
