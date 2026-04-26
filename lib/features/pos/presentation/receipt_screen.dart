import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/currency_utils.dart';
import 'package:rumah_jahit/features/inventory/data/inventory_providers.dart';
import 'package:rumah_jahit/features/pos/data/pos_providers.dart';

import 'package:rumah_jahit/features/pos/domain/transaction_model.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  final TransactionModel transaction;

  const ReceiptScreen({super.key, required this.transaction});

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isSharing = false;

  void _simulateAction(String actionName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$actionName (Fitur menyusul)'),
        backgroundColor: const Color(0xFF004D4C),
      ),
    );
  }

  Future<void> _shareViaWhatsApp() async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final tx = widget.transaction;

      // Ensure rendering finishes
      await Future.delayed(const Duration(milliseconds: 300));

      // 1. Capture Image of the Receipt Widget
      RenderRepaintBoundary? boundary =
          _receiptKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception("Gagal merender struk.");
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception("Gagal memproses gambar struk.");
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // 2. Save Image File
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/receipt_${tx.id}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      // Build receipt text in Indonesian
      final buffer = StringBuffer();
      buffer.writeln('📋 *STRUK PEMBAYARAN - RUMAH JAHIT ALYA*');
      buffer.writeln('━━━━━━━━━━━━━━━━━━');
      buffer.writeln('🆔 Nomor Transaksi: ${tx.formattedId}');
      buffer.writeln(
        '📅 Tanggal: ${DateFormat('dd MMM yyyy, HH:mm').format(tx.createdAt)}',
      );
      if (tx.customerName != null && tx.customerName!.isNotEmpty) {
        buffer.writeln('👤 Pelanggan: ${tx.customerName}');
      }
      buffer.writeln('');

      final stockItems = tx.stockItems;
      final customItems = tx.customOrderItems;

      if (stockItems.isNotEmpty) {
        buffer.writeln('📦 *KOLEKSI STOK*');
        for (final item in stockItems) {
          buffer.writeln(
            '  • ${item.quantity}x ${item.productName} — ${formatCurrency(item.totalPrice)}',
          );
        }
        buffer.writeln('');
      }

      if (customItems.isNotEmpty) {
        buffer.writeln('✂️ *JAHITAN KUSTOM*');
        for (final item in customItems) {
          String sizeInfo = item.size.isNotEmpty ? ' [Size: ${item.size}]' : '';
          buffer.writeln(
            '  • ${item.quantity}x ${item.productName}$sizeInfo — ${formatCurrency(item.totalPrice)}',
          );
        }
        if (tx.pickupDate != null) {
          buffer.writeln(
            '📍 Estimasi Selesai: ${DateFormat('dd MMM yyyy').format(tx.pickupDate!)}',
          );
        }
        buffer.writeln('');
      }

      buffer.writeln('━━━━━━━━━━━━━━━━━━');
      if (tx.discount > 0) {
        buffer.writeln('Subtotal: ${formatCurrency(tx.subtotal)}');
        buffer.writeln('Potongan: -${formatCurrency(tx.discount)}');
      }
      buffer.writeln('💰 *TOTAL BAYAR: ${tx.formattedGrandTotal}*');
      buffer.writeln('━━━━━━━━━━━━━━━━━━');
      buffer.writeln(
        'Status: ${tx.status == 'SUCCESS' || tx.status == 'SUCCESSFUL' ? '✅ Lunas' : '⏳ Menunggu Pelunasan'}',
      );
      buffer.writeln('');
      buffer.writeln(
        '_"Ketelitian di setiap jahitan. Terima kasih telah mempercayakan busana Anda kepada Rumah Jahit Alya."_',
      );

      // 3. Share the file and text
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imagePath)],
          text: buffer.toString(),
          title: 'Struk RJA - ${tx.formattedId}',
        ),
      );
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
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final bool isPending = tx.status == 'PENDING';
    final stockItems = tx.stockItems;
    final customItems = tx.customOrderItems;
    final hasCustom = customItems.isNotEmpty;

    // Calculate SPK progress if this transaction has custom items
    int totalSpks = 0;
    int completedSpks = 0;
    bool allSpksCompleted = false;

    if (hasCustom) {
      final spkAsync = ref.watch(productionOrdersStreamProvider);
      final relatedSpks =
          spkAsync.value?.where((spk) => spk.transactionId == tx.id).toList() ??
          [];

      totalSpks = relatedSpks.length;
      completedSpks = relatedSpks.where((spk) => spk.isCompleted).length;
      allSpksCompleted = totalSpks > 0 && completedSpks == totalSpks;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFA),
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Receipt',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF003D3D),
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF003D3D)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildStatusBanner(
                        isPending,
                        hasCustom,
                        allSpksCompleted,
                        completedSpks,
                        totalSpks,
                      ),
                      _buildReceiptCard(tx, stockItems, customItems, hasCustom),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                padding: const EdgeInsets.all(20),
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(color: Color(0xFFF9FAFA)),
                child: _buildActionButtons(tx, isPending, hasCustom),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(
    bool isPending,
    bool hasCustom,
    bool allSpksCompleted,
    int completedSpks,
    int totalSpks,
  ) {
    if (!isPending && (!hasCustom || allSpksCompleted))
      return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.amber.shade800, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menunggu Pengerjaan',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasCustom
                      ? '$completedSpks/$totalSpks SPK selesai. Lanjutkan proses di tab gudang.'
                      : 'Pesanan sedang dalam proses',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(
    TransactionModel tx,
    List<TransactionItem> stockItems,
    List<TransactionItem> customItems,
    bool hasCustom,
  ) {
    return RepaintBoundary(
      key: _receiptKey,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // -- LOGO & HEADER --
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF004D4C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.checkroom, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Rumah Jahit Alya',
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF003D3D),
              ),
            ),
            const SizedBox(height: 24),
            _buildDottedLine(),
            const SizedBox(height: 24),

            // -- TXN ID & DATE --
            Text(
              tx.formattedId,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF001F1F),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat(
                'MMM dd, yyyy • HH:mm',
              ).format(tx.createdAt).toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),

            // -- Customer name if exists --
            if (tx.customerName != null && tx.customerName!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'a/n ${tx.customerName}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // -- STOCK ITEMS SECTION --
            if (stockItems.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'BARANG STOK',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...stockItems.map((item) => _buildItemRow(item)),
              if (hasCustom)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _buildDottedLine(),
                ),
            ],

            // -- CUSTOM ITEMS SECTION --
            if (hasCustom) ...[
              Row(
                children: [
                  Icon(
                    Icons.content_cut,
                    size: 14,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'PESANAN PERSONAL${tx.customerName != null ? " (${tx.customerName})" : ""}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.amber.shade700,
                        letterSpacing: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...customItems.map((item) => _buildItemRow(item, isCustom: true)),
              if (tx.pickupDate != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 13,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Est. Pengambilan: ${DateFormat('dd MMMM yyyy').format(tx.pickupDate!)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // -- Items fallback (no custom/stock separation for old data) --
            if (stockItems.isEmpty && customItems.isEmpty)
              ...tx.items.map((item) => _buildItemRow(item)),

            const SizedBox(height: 24),

            // -- TOTALS --
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  formatCurrency(tx.subtotal),
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: const Color(0xFF001F1F),
                  ),
                ),
              ],
            ),
            if (tx.discount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Diskon',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '-${formatCurrency(tx.discount)}',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL AMOUNT',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF004D4C),
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  tx.formattedGrandTotal,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: const Color(0xFF004D4C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // -- PAYMENT INFO BOX --
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _infoRow(
                    'Payment Method',
                    tx.paymentMethod == 'CASH' ? 'Tunai' : tx.paymentMethod,
                  ),
                  const SizedBox(height: 12),
                  _infoRow('Paid', formatCurrency(tx.amountPaid)),
                  const SizedBox(height: 12),
                  _infoRow(
                    tx.change >= 0 ? 'Change' : 'Sisa Kurang',
                    formatCurrency(tx.change >= 0 ? tx.change : -tx.change),
                    isGreen: tx.change >= 0,
                    isOrange: tx.change < 0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // -- SLOGAN --
            Text(
              '"Precision in every stitch. Thank you for choosing Rumah Jahit Alya."',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    TransactionModel tx,
    bool isPending,
    bool hasCustom,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Completion button for custom orders (Pelunasan dan Pengambilan)
        if (isPending && hasCustom) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await ref
                    .read(transactionRepositoryProvider)
                    .updateStatusAndAmountPaid(tx.id, 'SUCCESS', tx.grandTotal);
              },
              icon: const Icon(Icons.check_circle),
              label: Text(
                'Pelunasan dan Pengambilan',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF003D3D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _simulateAction('Print Thermal'),
                icon: const Icon(Icons.print, size: 20),
                label: Text(
                  'Print\nReceipt',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF004D4C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSharing ? null : _shareViaWhatsApp,
                icon: _isSharing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.share, size: 20),
                label: Text(
                  _isSharing ? 'Memproses...' : 'Share',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isSharing ? 0 : 2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemRow(TransactionItem item, {bool isCustom = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF001F1F),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${item.quantity} x ${formatCurrency(item.unitPrice)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (isCustom && item.size.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.size,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(item.totalPrice),
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: const Color(0xFF001F1F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool isGreen = false,
    bool isOrange = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: isGreen
                ? const Color(0xFF006766)
                : isOrange
                ? Colors.orange.shade800
                : const Color(0xFF001F1F),
          ),
        ),
      ],
    );
  }

  Widget _buildDottedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade300),
              ),
            );
          }),
        );
      },
    );
  }
}
