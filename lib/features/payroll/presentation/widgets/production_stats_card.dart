import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rumah_jahit/features/payroll/data/payroll_providers.dart';

class ProductionStatsCard extends ConsumerWidget {
  final String userId;

  const ProductionStatsCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentYear = DateTime.now().year;
    final statsAsync = ref.watch(tailorAnnualStatsProvider('${userId}_$currentYear'));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: statsAsync.when(
        data: (stats) {
          final totalPieces = stats?.totalPieces ?? 0;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STATISTIK PRODUKSI $currentYear',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Icon(Icons.show_chart, color: Colors.white70, size: 16),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$totalPieces',
                    style: GoogleFonts.manrope(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'pcs diselesaikan',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: 1.0, // Best practice or milestone
                backgroundColor: Colors.white12,
                color: Theme.of(context).colorScheme.secondaryContainer,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Text(
                'Data akumulasi otomatis untuk perhitungan bonus tahunan.',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (err, stack) => Text(
          'Gagal memuat statistik',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
      ),
    );
  }
}
