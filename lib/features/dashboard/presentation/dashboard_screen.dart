import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rumah_jahit/features/dashboard/data/dashboard_providers.dart';

import '../../../../core/widgets/spk_item_card.dart';
import '../../../../core/widgets/transaction_item_card.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../auth/data/auth_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final revenueAsync = ref.watch(todayRevenueProvider);
    final lowStockAsync = ref.watch(dashboardLowStockProvider);
    final recentSpkAsync = ref.watch(recentSpkProvider);
    final recentTxAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colors.primaryContainer,
              child: Icon(Icons.storefront, size: 20, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'Rumah Jahit',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                color: colors.primary,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/auth');
            },
            icon: Icon(Icons.logout, color: colors.primary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 768;

          if (isTablet) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kiri: Hero & Low Stock
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroCard(context, revenueAsync, colors),
                        const SizedBox(height: 24),
                        _buildLowStock(lowStockAsync, colors),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Kanan: List (SPK & Transaksi)
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRecentSpk(context, recentSpkAsync, colors),
                        const SizedBox(height: 32),
                        _buildRecentTx(context, recentTxAsync, colors),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // Mobile Layout
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _buildHeroCard(context, revenueAsync, colors),
              const SizedBox(height: 24),
              _buildLowStock(lowStockAsync, colors),
              const SizedBox(height: 20),
              _buildRecentSpk(context, recentSpkAsync, colors),
              const SizedBox(height: 32),
              _buildRecentTx(context, recentTxAsync, colors),
              const SizedBox(height: 140),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    AsyncValue<double> revenueAsync,
    ColorScheme colors,
  ) {
    return InkWell(
      onTap: () => context.go('/dashboard/finance'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [colors.primary, const Color(0xFF006766)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PENDAPATAN HARI INI',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                revenueAsync.when(
                  loading: () => Text(
                    '...',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  error: (_, _) => Text(
                    'Error',
                    style: GoogleFonts.manrope(
                      color: Colors.white70,
                      fontSize: 24,
                    ),
                  ),
                  data: (revenue) => Text(
                    formatCurrency(revenue),
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Buka Catatan Keuangan',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: -10,
              bottom: -20,
              child: Icon(
                Icons.account_balance_wallet,
                size: 100,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStock(
    AsyncValue<List<dynamic>> lowStockAsync,
    ColorScheme colors,
  ) {
    return lowStockAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (lowStockItems) {
        if (lowStockItems.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.redAccent,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'MENDESAK',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'PERINGATAN STOK MENIPIS',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${lowStockItems.length} Items',
                style: GoogleFonts.manrope(
                  color: colors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lowStockItems.map((m) => m.name).take(3).join(', '),
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentSpk(
    BuildContext context,
    AsyncValue<List<dynamic>> recentSpkAsync,
    ColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SPK Terbaru',
              style: GoogleFonts.manrope(
                color: colors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/inventory'),
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.inter(
                  color: colors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        recentSpkAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) {
            final isIndexError = err.toString().contains('index');
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(height: 8),
                  Text(
                    isIndexError
                        ? 'Perlu membuat index di Firebase Console agar data bisa muncul.'
                        : 'Gagal memuat SPK terbaru.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.red.shade900,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isIndexError)
                    Text(
                      'Cek log debug untuk link otomatis.',
                      style: GoogleFonts.inter(
                        color: Colors.red.shade700,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            );
          },
          data: (spkList) {
            if (spkList.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Belum ada SPK aktif',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: spkList.take(4).map((order) {
                String statusLabel;
                Color statusColor;
                Color statusTextColor;

                if (order.isInProgress) {
                  statusLabel = 'PROSES';
                  statusColor = const Color(0xFFA4F0E9);
                  statusTextColor = const Color(0xFF004D4C);
                } else {
                  statusLabel = 'TERJADWAL';
                  statusColor = const Color(0xFFCBE7F5);
                  statusTextColor = const Color(0xFF1E40AF);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      context.go('/inventory/spk-detail', extra: order.id);
                    },
                    child: SpkItemCard(
                      icon: Icons.checkroom,
                      title: order.title,
                      subtitle:
                          '${order.tailorAssignments.length} Penjahit • Progress: ${(order.progressPercent * 100).toStringAsFixed(0)}%',
                      status: statusLabel,
                      statusColor: statusColor,
                      statusTextColor: statusTextColor,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentTx(
    BuildContext context,
    AsyncValue<List<dynamic>> recentTxAsync,
    ColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaksi Terbaru',
              style: GoogleFonts.manrope(
                color: colors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/pos/history'),
              child: Text(
                'Lihat Riwayat',
                style: GoogleFonts.inter(
                  color: colors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        recentTxAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Text(
            'Gagal memuat transaksi',
            style: GoogleFonts.inter(color: Colors.red),
          ),
          data: (txList) {
            if (txList.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Belum ada transaksi hari ini',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                ),
              );
            }
            return Column(
              children: txList.take(5).map((tx) {
                final timeStr = _formatTime(tx.createdAt);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TransactionItemCard(
                    icon: Icons.receipt_long,
                    title: 'Transaksi',
                    time: timeStr,
                    amount: '+${tx.formattedGrandTotal}',
                    status: '${tx.status} • ${tx.paymentMethod}',
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    if (isToday) {
      return 'Hari ini, $hour:$minute';
    }
    return '${date.day}/${date.month}, $hour:$minute';
  }
}
