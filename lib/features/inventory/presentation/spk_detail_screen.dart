import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rumah_jahit/core/utils/currency_utils.dart';
import 'package:rumah_jahit/core/widgets/detail_widgets.dart';
import 'package:rumah_jahit/core/widgets/status_badge.dart';
import 'package:rumah_jahit/core/widgets/custom_text_field.dart';
import 'package:rumah_jahit/features/inventory/data/inventory_providers.dart';
import 'package:rumah_jahit/features/inventory/domain/production_order.dart';
import 'package:rumah_jahit/features/inventory/domain/raw_material.dart';
import 'package:rumah_jahit/features/payroll/data/payroll_providers.dart';

class SpkDetailScreen extends ConsumerWidget {
  final String spkId;

  const SpkDetailScreen({super.key, required this.spkId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final ordersAsync = ref.watch(productionOrdersStreamProvider);

    return ordersAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (orders) {
        final order = orders.where((o) => o.id == spkId).firstOrNull;
        if (order == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
          return const SizedBox.shrink();
        }
        return _buildPage(context, ref, order, colors);
      },
    );
  }

  Widget _buildPage(
    BuildContext context,
    WidgetRef ref,
    ProductionOrder order,
    ColorScheme colors,
  ) {
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
          'Detail SPK',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: colors.primary,
          ),
        ),
        actions: [
          if (order.isPending)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              onPressed: () => _confirmDelete(context, ref, order),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        children: [
          // ── Status & Type Badges ──
          Row(
            children: [
              AppStatusBadge(status: order.status),
              const SizedBox(width: 8),
              Builder(
                builder: (_) {
                  String label;
                  Color bg;
                  Color fg;
                  if (order.isPersonal) {
                    label = '👤 Personal';
                    bg = Colors.amber.shade50;
                    fg = Colors.amber.shade800;
                  } else if (order.isCustom) {
                    label = '📋 Pesanan';
                    bg = Colors.orange.shade50;
                    fg = Colors.orange.shade800;
                  } else {
                    label = '📦 Stok';
                    bg = const Color(0xFFE0F2F1);
                    fg = const Color(0xFF004D4C);
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              Text(
                _formatDate(order.createdAt),
                style: GoogleFonts.inter(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Title ──
          Text(
            order.title,
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF001F1F),
            ),
          ),
          const SizedBox(height: 20),

          // ── Customer Info (only for PERSONAL) ──
          if (order.isPersonal) ...[
            DetailSection(
              label: 'INFO PELANGGAN',
              icon: Icons.person_outline,
              children: [
                if (order.customerName != null)
                  DetailInfoRow(label: 'Nama', value: order.customerName!),
                if (order.customerPhone != null)
                  DetailInfoRow(label: 'WhatsApp', value: order.customerPhone!),
                if (order.pickupDate != null)
                  DetailInfoRow(
                    label: 'Tanggal Ambil',
                    value: _formatDate(order.pickupDate!),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── Product Info ──
          DetailSection(
            label: 'PRODUK TARGET',
            icon: Icons.checkroom_outlined,
            children: [
              DetailInfoRow(
                label: 'Produk',
                value: order.productType.isNotEmpty
                    ? '${order.productName} - ${order.productType}'
                    : order.productName,
              ),
              if (order.isRestock)
                ...order.items.map(
                  (item) => DetailInfoRow(
                    label: 'Ukuran ${item.size}',
                    value:
                        '${item.completedQuantity} / ${item.targetQuantity} pcs',
                  ),
                ),
              DetailInfoRow(
                label: 'Total Jumlah',
                value: '${order.targetQuantity} pcs',
              ),
              if (!order.isRestock)
                DetailInfoRow(
                  label: 'Total Selesai',
                  value: '${order.completedQuantity} pcs',
                ),
              // Editable wage row
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upah/pcs',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          order.formattedWage,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (!order.isCompleted) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () =>
                                _showEditWageDialog(context, ref, order),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 14,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Dates ──
          DetailSection(
            label: 'JADWAL',
            icon: Icons.calendar_today,
            children: [
              DetailInfoRow(
                label: 'Mulai',
                value: _formatDate(order.startDate),
              ),
              DetailInfoRow(
                label: 'Estimasi Selesai',
                value: _formatDate(order.estimatedCompletionDate),
              ),
              if (order.completedAt != null)
                DetailInfoRow(
                  label: 'Selesai Pada',
                  value: _formatDate(order.completedAt!),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Tailors ──
          DetailSection(
            label: 'PENJAHIT (${order.tailorAssignments.length})',
            icon: Icons.people_outline,
            trailing: (!order.isCompleted)
                ? GestureDetector(
                    onTap: () => _showAddTailorDialog(context, ref, order),
                    child: Text(
                      '+ Tambah Penjahit',
                      style: GoogleFonts.inter(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  )
                : null,
            children: [
              if (order.tailorAssignments.isEmpty && !order.isCompleted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Belum ada penjahit. Tambahkan sebelum menyelesaikan SPK.',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ...order.tailorAssignments.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.userName,
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${t.completedPieces} dkerjakan',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (!order.isCompleted && t.completedPieces == 0) ...[
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () =>
                                  _removeTailor(context, ref, order, t),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Upah Terakumulasi',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  formatCurrency(order.completedQuantity * order.wagePerPiece),
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Materials ──
          DetailSection(
            label: 'BAHAN MENTAH',
            icon: Icons.inventory_2_outlined,
            trailing: (!order.isCompleted)
                ? GestureDetector(
                    onTap: () => _showAddMaterialDialog(context, ref, order),
                    child: Text(
                      '+ Tambah Bahan',
                      style: GoogleFonts.inter(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  )
                : null,
            children: [
              if (order.materialsUsed.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Belum ada bahan mentah tercatat.',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ...order.materialsUsed.map((m) {
                return _buildMaterialRow(context, ref, order, m, colors);
              }),
            ],
          ),
          const SizedBox(height: 16),

          // ── Riwayat Setoran ──
          if (order.reports.isNotEmpty)
            DetailSection(
              label: 'RIWAYAT SETORAN (${order.reports.length})',
              icon: Icons.history,
              children: order.reports.reversed.map((r) {
                final dateStr =
                    '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              r.userName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
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
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${r.quantity} pcs${r.variantSize != null ? ' (${r.variantSize})' : ''}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              formatCurrency(r.quantity * r.wagePerPiece),
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),

          // ── Action Buttons ──
          if (order.isPending)
            ElevatedButton.icon(
              onPressed: () => _startProduction(context, ref, order),
              icon: const Icon(Icons.play_arrow),
              label: Text(
                'Mulai Produksi',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

          if (order.isInProgress) ...[
            ElevatedButton.icon(
              onPressed: () => _showCatatLaporanDialog(context, ref, order),
              icon: const Icon(Icons.edit_note_outlined),
              label: Text(
                'Catat Hasil Produksi',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF004D4C),
                side: const BorderSide(color: Color(0xFF004D4C)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _completeSpk(context, ref, order),
              icon: const Icon(Icons.check_circle),
              label: Text(
                'Selesai — Proses Semua',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004D4C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],

          if (order.isInProgress)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '↑ Setiap laporan langsung menambah stok & mencatat upah secara real-time',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
            ),

          if (order.isCompleted) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: colors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SPK Selesai',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                        Text(
                          order.isOrder
                              ? 'Bahan dan upah telah diproses'
                              : 'Stok, bahan, dan upah telah diproses',
                          style: GoogleFonts.inter(
                            color: colors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Actions ──
  void _showCatatLaporanDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionOrder order,
  ) {
    if (order.tailorAssignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan penjahit terlebih dahulu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (order.wagePerPiece <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upah per potong belum diset.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CatatLaporanSheet(order: order),
    );
  }

  void _startProduction(
    BuildContext context,
    WidgetRef ref,
    ProductionOrder order,
  ) {
    if (order.tailorAssignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda belum menugaskan penjahit satupun.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (order.wagePerPiece <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upah per potong belum diisi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Mulai Produksi?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Status SPK akan diperbarui menjadi Sedang Dikerjakan.',
          style: GoogleFonts.inter(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(productionOrderRepositoryProvider)
                  .startProduction(order.id);
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
              'Mulai',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _completeSpk(
    BuildContext context,
    WidgetRef ref,
    ProductionOrder order,
  ) {
    if (order.tailorAssignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda belum menugaskan penjahit satupun.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (order.wagePerPiece <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upah per potong belum diisi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Selesaikan SPK?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tindakan ini akan menandai Order Produksi (SPK) ini sebagai selesai secara permanen.',
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Catatan: Penambahan stok produk dan upah penjahit sudah terekam otomatis setiap kali Laporan Harian dicatat. '
              'Tindakan ini tidak akan menggandakan penambahan stok/upah.',
              style: GoogleFonts.inter(
                color: Colors.orange.shade800,
                fontSize: 12,
                fontStyle: FontStyle.italic,
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
              await ref
                  .read(productionOrderRepositoryProvider)
                  .completeWithEffects(order);
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
              'Selesaikan',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialRow(
    BuildContext context,
    WidgetRef ref,
    ProductionOrder order,
    MaterialUsed m,
    ColorScheme colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            m.materialName,
            style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
          ),
          Row(
            children: [
              Text(
                '${m.quantity} ${m.unit}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (!order.isCompleted) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showEditMaterialDialog(context, ref, order, m),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit, size: 14, color: colors.primary),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showEditMaterialDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionOrder order,
    MaterialUsed material,
  ) {
    final controller = TextEditingController(
      text: material.quantity.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Pemakaian Bahan',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bahan: ${material.materialName}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mengubah jumlah akan otomatis menyesuaikan stok bahan mentah.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Jumlah (${material.unit})',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
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
              final val = double.tryParse(controller.text) ?? 0;
              if (val <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jumlah tidak valid'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final difference = val - material.quantity;

              if (difference != 0) {
                await ref
                    .read(productionOrderRepositoryProvider)
                    .updateMaterialUsage(
                      order.id,
                      order,
                      material.materialId,
                      difference,
                    );
              }
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

  void _showAddMaterialDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionOrder order,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Consumer(
              builder: (context, ref, child) {
                final materialsAsync = ref.watch(rawMaterialsStreamProvider);

                return materialsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (allMaterials) {
                    final unusedMaterials = allMaterials
                        .where(
                          (m) => !order.materialsUsed.any(
                            (used) => used.materialId == m.id,
                          ),
                        )
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Tambah Bahan Mentah',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: unusedMaterials.isEmpty
                              ? Center(
                                  child: Text(
                                    'Semua bahan sudah ditambahkan atau gudang kosong.',
                                    style: GoogleFonts.inter(
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  itemCount: unusedMaterials.length,
                                  itemBuilder: (ctx, i) {
                                    final mat = unusedMaterials[i];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        mat.name,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Stok: ${mat.selectedStock} ${mat.unit}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      trailing: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _promptNewMaterialQuantity(
                                            context,
                                            ref,
                                            order,
                                            mat,
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF004D4C,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Pilih',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _promptNewMaterialQuantity(
    BuildContext context,
    WidgetRef ref,
    ProductionOrder order,
    RawMaterial mat,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Input Jumlah Bahan',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mat.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Jumlah Digunakan (${mat.unit})',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
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
              final val = double.tryParse(controller.text) ?? 0;
              if (val <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jumlah tidak valid'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newMaterialUsed = MaterialUsed(
                materialId: mat.id,
                materialName: mat.name,
                quantity: val,
                unit: mat.unit,
              );

              await ref
                  .read(productionOrderRepositoryProvider)
                  .addMaterialUsage(order.id, order, newMaterialUsed);

              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D4C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddTailorDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionOrder order,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return Consumer(
              builder: (context, ref, child) {
                final tailorsAsync = ref.watch(tailorsStreamProvider);

                return tailorsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (allTailors) {
                    // Filter out already assigned tailors
                    final availableTailors = allTailors
                        .where(
                          (t) => !order.tailorAssignments.any(
                            (a) => a.userId == t.id,
                          ),
                        )
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tambah Penjahit',
                                style: GoogleFonts.manrope(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pilih penjahit lalu tentukan jumlah potong',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: availableTailors.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Text(
                                      'Semua penjahit sudah ditambahkan.',
                                      style: GoogleFonts.inter(
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  itemCount: availableTailors.length,
                                  itemBuilder: (ctx, i) {
                                    final tailor = availableTailors[i];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(
                                          0xFFE0F2F1,
                                        ),
                                        child: Text(
                                          tailor.name.isNotEmpty
                                              ? tailor.name[0].toUpperCase()
                                              : '?',
                                          style: GoogleFonts.manrope(
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF004D4C),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        tailor.name,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        tailor.role,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      trailing: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _addTailorDirect(
                                            context,
                                            ref,
                                            order,
                                            tailor,
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF004D4C,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Pilih',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _addTailorDirect(
    BuildContext context,
    WidgetRef ref,
    ProductionOrder order,
    dynamic tailor,
  ) async {
    final newAssignments = [
      ...order.tailorAssignments,
      TailorAssignment(userId: tailor.id, userName: tailor.name),
    ];

    try {
      await ref
          .read(productionOrderRepositoryProvider)
          .updateTailorAssignments(order.id, newAssignments);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambah penjahit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeTailor(
    BuildContext context,
    WidgetRef ref,
    ProductionOrder order,
    TailorAssignment tailor,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Penjahit?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${tailor.userName} akan dihapus dari SPK ini.',
          style: GoogleFonts.inter(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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

    if (confirm == true) {
      final newAssignments = order.tailorAssignments
          .where((t) => t.userId != tailor.userId)
          .toList();
      await ref
          .read(productionOrderRepositoryProvider)
          .updateTailorAssignments(order.id, newAssignments);
    }
  }

  void _showEditWageDialog(
    BuildContext context,
    WidgetRef ref,
    ProductionOrder order,
  ) {
    final controller = TextEditingController(
      text: order.wagePerPiece > 0
          ? formatCurrency(
              order.wagePerPiece,
            ).replaceAll('Rp ', '').replaceAll('.', '')
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Upah per Potong',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Masukkan upah yang diterima penjahit per potong.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: InputDecoration(
                labelText: 'Upah (Rp)',
                prefixText: 'Rp ',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
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
              final numericString = controller.text.replaceAll(
                RegExp(r'[^0-9]'),
                '',
              );
              final val = double.tryParse(numericString) ?? 0;
              if (val <= 0) return;

              await ref
                  .read(productionOrderRepositoryProvider)
                  .updateWagePerPiece(order.id, val);
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

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProductionOrder order,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus SPK?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '"${order.title}" akan dihapus permanen.',
          style: GoogleFonts.inter(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(productionOrderRepositoryProvider).delete(order);
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

  // ── Formatters ──
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _CatatLaporanSheet extends ConsumerStatefulWidget {
  final ProductionOrder order;
  const _CatatLaporanSheet({required this.order});

  @override
  ConsumerState<_CatatLaporanSheet> createState() => _CatatLaporanSheetState();
}

class _CatatLaporanSheetState extends ConsumerState<_CatatLaporanSheet> {
  final _qtyController = TextEditingController();
  String? _selectedUserId;
  String? _selectedVariantSize;
  bool _isLoading = false;

  OverlayEntry? _errorEntry;

  @override
  void dispose() {
    _errorEntry?.remove();
    _qtyController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    _errorEntry?.remove();

    _errorEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.red.shade800,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_errorEntry!);
    Future.delayed(const Duration(seconds: 3), () {
      if (_errorEntry != null && _errorEntry!.mounted) {
        _errorEntry!.remove();
        _errorEntry = null;
      }
    });
  }

  void _submit() async {
    if (_selectedUserId == null) {
      _showError('Pilih penjahit.');
      return;
    }
    if (widget.order.isRestock &&
        widget.order.items.isNotEmpty &&
        _selectedVariantSize == null) {
      _showError('Pilih ukuran.');
      return;
    }
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      _showError('Jumlah potongan harus lebih dari 0.');
      return;
    }

    int maxAllowed =
        widget.order.targetQuantity - widget.order.completedQuantity;
    if (widget.order.isRestock &&
        widget.order.items.isNotEmpty &&
        _selectedVariantSize != null) {
      final variant = widget.order.items.firstWhere(
        (i) => i.size == _selectedVariantSize,
      );
      maxAllowed = variant.targetQuantity - variant.completedQuantity;
    }

    if (qty > maxAllowed) {
      _showError('Jumlah melebihi sisa target ($maxAllowed pcs).');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tailor = widget.order.tailorAssignments.firstWhere(
        (t) => t.userId == _selectedUserId,
      );
      final report = ProductionReport(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        userId: tailor.userId,
        userName: tailor.userName,
        quantity: qty,
        wagePerPiece: widget.order.wagePerPiece,
        createdAt: DateTime.now(),
        variantSize: _selectedVariantSize,
      );

      final updatedTailors = widget.order.tailorAssignments.map((t) {
        if (t.userId == _selectedUserId) {
          return TailorAssignment(
            userId: t.userId,
            userName: t.userName,
            completedPieces: t.completedPieces + qty,
          );
        }
        return t;
      }).toList();

      List<SpkVariant> updatedItems = List.from(widget.order.items);
      int newCompletedQty = widget.order.completedQuantity;

      if (widget.order.isRestock && _selectedVariantSize != null) {
        updatedItems = updatedItems.map((item) {
          if (item.size == _selectedVariantSize) {
            return SpkVariant(
              productId: item.productId,
              size: item.size,
              targetQuantity: item.targetQuantity,
              completedQuantity: item.completedQuantity + qty,
            );
          }
          return item;
        }).toList();
        newCompletedQty = updatedItems.fold(
          0,
          (total, item) => total + item.completedQuantity,
        );
      } else {
        newCompletedQty += qty;
      }

      final updatedOrder = widget.order.copyWith(
        tailorAssignments: updatedTailors,
        items: updatedItems,
        completedQuantity: newCompletedQty,
        reports: [...widget.order.reports, report],
      );

      await ref
          .read(productionOrderRepositoryProvider)
          .reportDailyProduction(updatedOrder, report);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showError('Gagal: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Catat Hasil Produksi',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // --- Pilih Penjahit Dropdown ---
          DropdownButtonFormField<String>(
            initialValue: _selectedUserId,
            isExpanded: true,
            icon: const Icon(Icons.expand_more, size: 20, color: Colors.grey),
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              labelText: 'Pilih Penjahit',
              labelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF001F1F),
              ),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              prefixIcon: Icon(
                Icons.person_outline,
                size: 18,
                color: Colors.grey.shade500,
              ),
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
            selectedItemBuilder: (context) {
              return widget.order.tailorAssignments.map((t) {
                return Text(
                  t.userName,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
                );
              }).toList();
            },
            items: widget.order.tailorAssignments.map((t) {
              return DropdownMenuItem(
                value: t.userId,
                child: Text(t.userName, style: GoogleFonts.inter(fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedUserId = val),
          ),
          const SizedBox(height: 16),

          // --- Pilih Ukuran Dropdown (Restock) ---
          if (widget.order.isRestock && widget.order.items.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedVariantSize,
              isExpanded: true,
              icon: const Icon(Icons.expand_more, size: 20, color: Colors.grey),
              dropdownColor: Colors.white,
              decoration: InputDecoration(
                labelText: 'Pilih Ukuran',
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF001F1F),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                prefixIcon: Icon(
                  Icons.straighten,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
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
              selectedItemBuilder: (context) {
                return widget.order.items.map((item) {
                  return Text(
                    'Ukuran ${item.size}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  );
                }).toList();
              },
              items: widget.order.items.map((item) {
                return DropdownMenuItem(
                  value: item.size,
                  child: Text(
                    'Ukuran ${item.size} (Sisa: ${item.targetQuantity - item.completedQuantity})',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedVariantSize = val),
            ),
            const SizedBox(height: 16),
          ],

          CustomTextField(
            controller: _qtyController,
            label: 'Jumlah Potong',
            hint: '0',
            suffixText: 'Pcs',
            icon: Icons.inventory_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D4C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Simpan Laporan',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }
}
