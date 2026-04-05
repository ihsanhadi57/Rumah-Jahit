import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:rumah_jahit/core/widgets/detail_widgets.dart';
import 'package:rumah_jahit/core/widgets/status_badge.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../data/inventory_providers.dart';
import '../domain/raw_material.dart';
import 'widgets/add_raw_material_form.dart';

class RawMaterialDetailScreen extends ConsumerWidget {
  final String materialId;

  const RawMaterialDetailScreen({super.key, required this.materialId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final materialAsync = ref.watch(rawMaterialByIdProvider(materialId));

    return Scaffold(
      backgroundColor: colors.surface,
      body: materialAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (material) {
          if (material == null) {
            return const Center(child: Text('Bahan tidak ditemukan'));
          }
          return _DetailBody(material: material);
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final RawMaterial material;

  const _DetailBody({required this.material});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // ── Hero Image SliverAppBar ──
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background:
                material.imageUrl != null && material.imageUrl!.isNotEmpty
                ? Image.network(
                    material.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _ImagePlaceholder(colors: colors),
                  )
                : _ImagePlaceholder(colors: colors),
          ),
          actions: [
            // Edit
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) =>
                      AddRawMaterialDialog(existingMaterial: material),
                );
              },
            ),
            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),

        // ── Content ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                AppStatusBadge(status: material.stockStatus),
                const SizedBox(height: 16),

                // Material Name
                Text(
                  material.name,
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF001F1F),
                  ),
                ),
                const SizedBox(height: 4),
                // Updated Time
                Text(
                  'Diperbarui: ${DateFormat('dd MMM yyyy, HH:mm').format(material.updatedAt)}',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 28),

                DetailSection(
                  label: 'STOK & BATAS',
                  icon: Icons.inventory_2_outlined,
                  children: [
                    DetailInfoRow(
                      label: 'Stok Saat Ini',
                      value: '${_formatStock(material.selectedStock)} ${material.unit}',
                      valueColor: colors.primary,
                    ),
                    DetailInfoRow(
                      label: 'Batas Minimum',
                      value: '${_formatStock(material.lowStockThreshold)} ${material.unit}',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Stock Adjustment ──
                Text(
                  'Penyesuaian Stok',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF001F1F),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StockActionButton(
                        icon: Icons.add,
                        label: 'Tambah Stok',
                        color: const Color(0xFF00897B),
                        onPressed: () =>
                            _showStockAdjustment(context, ref, isAdd: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StockActionButton(
                        icon: Icons.remove,
                        label: 'Kurangi Stok',
                        color: Colors.orange.shade700,
                        onPressed: () =>
                            _showStockAdjustment(context, ref, isAdd: false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatStock(double val) {
    return val == val.truncateToDouble()
        ? val.toInt().toString()
        : val
              .toStringAsFixed(2)
              .replaceAll(RegExp(r'0+$'), '')
              .replaceAll(RegExp(r'\.$'), '');
  }

  void _showStockAdjustment(
    BuildContext context,
    WidgetRef ref, {
    required bool isAdd,
  }) {
    final controller = TextEditingController();
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isAdd ? 'Tambah Stok' : 'Kurangi Stok',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: colors.primary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              material.name,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: colors.primary,
              ),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: material.unit,
                filled: true,
                fillColor: const Color(0xFFF2F4F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(controller.text.replaceAll(',', '.'));
              if (qty == null || qty <= 0) {
                SnackBarUtils.show(
                  ctx,
                  'Masukkan angka yang valid',
                  isError: true,
                );
                return;
              }
              final repo = ref.read(rawMaterialRepositoryProvider);
              if (isAdd) {
                await repo.addStock(material.id, qty);
              } else {
                await repo.deductStock(material.id, qty);
              }
              if (ctx.mounted) {
                Navigator.pop(ctx);
                SnackBarUtils.show(
                  ctx,
                  isAdd
                      ? 'Stok berhasil ditambah +$qty ${material.unit}'
                      : 'Stok berhasil dikurangi -$qty ${material.unit}',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdd
                  ? const Color(0xFF00897B)
                  : Colors.orange.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isAdd ? 'Tambah' : 'Kurangi',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Bahan?',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: colors.primary,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${material.name}"? Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Delete image from storage if exists
                if (material.imageUrl != null &&
                    material.imageUrl!.isNotEmpty) {
                  try {
                    await FirebaseStorage.instance
                        .ref('raw_materials/${material.id}.jpg')
                        .delete();
                  } catch (_) {
                    // Image may not exist in storage, ignore
                  }
                }

                await ref
                    .read(rawMaterialRepositoryProvider)
                    .delete(material.id);

                if (ctx.mounted) Navigator.pop(ctx); // close dialog
                if (context.mounted) Navigator.pop(context); // back to list
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  SnackBarUtils.show(
                    context,
                    'Gagal menghapus: $e',
                    isError: true,
                  );
                }
              }
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
}

// ─── Reusable Widgets ─────────────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  final ColorScheme colors;

  const _ImagePlaceholder({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 64,
          color: colors.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}



class _StockActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _StockActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    );
  }
}
