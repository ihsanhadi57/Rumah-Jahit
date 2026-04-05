import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rumah_jahit/features/payroll/data/payroll_providers.dart';
import 'package:rumah_jahit/features/payroll/domain/payroll_record.dart';
import '../../../../core/utils/currency_utils.dart';

class DetailedPayrollCard extends ConsumerWidget {
  final String userId;

  const DetailedPayrollCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payrollAsync = ref.watch(unpaidPayrollByUserProvider(userId));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rincian Gaji Belum Dibayar',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Table Header
          Row(
            children: [
              Expanded(flex: 3, child: _headerText('TANGGAL')),
              Expanded(flex: 7, child: _headerText('PEKERJAAN / ALASAN')),
              Expanded(flex: 4, child: _headerText('JUMLAH')),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.black12),
          const SizedBox(height: 8),

          // Items
          payrollAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(child: Text('Gagal memuat: $err')),
            data: (records) {
              if (records.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Semua gaji telah terbayar.',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: records.map((record) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildRowItem(context, record),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade500,
        letterSpacing: 0.5,
        height: 1.4,
      ),
    );
  }

  Widget _buildRowItem(BuildContext context, PayrollRecord record) {
    final dateStr = DateFormat('dd MMM\nyyyy').format(record.createdAt);
    final title = record.spkTitle ?? record.note ?? 'Penyesuaian';

    // Amount with color
    final color = record.totalWage < 0
        ? Colors.red.shade700
        : Theme.of(context).colorScheme.primary;
    final amountSign = record.totalWage > 0 ? '+' : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            dateStr,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey.shade600,
              height: 1.3,
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (record.spkId != null)
                Text(
                  '${record.piecesCount} pcs x (${formatCurrency(record.wagePerPiece)})',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            '$amountSign${record.formattedTotalWage}',
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
