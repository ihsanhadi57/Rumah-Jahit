import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/app_metric_card.dart';
import '../../../../core/widgets/inventory_spk_card.dart';
import '../../data/inventory_providers.dart';
import '../../domain/production_order.dart';

class SpkTabView extends ConsumerStatefulWidget {
  const SpkTabView({super.key});

  @override
  ConsumerState<SpkTabView> createState() => _SpkTabViewState();
}

class _SpkTabViewState extends ConsumerState<SpkTabView> {
  // 0 = Pesanan (CUSTOM), 1 = Produksi (RESTOCK)
  int _selectedSubTab = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ordersAsync = ref.watch(productionOrdersStreamProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        final isIndexError = error.toString().contains('index');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  isIndexError
                      ? 'Indeks Firestore Diperlukan'
                      : 'Terjadi Kesalahan',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isIndexError
                      ? 'Silakan klik link di log debug atau hubungi pengembang untuk mengaktifkan fitur ini.'
                      : '$error',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.red.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      data: (orders) => _buildContent(context, colors, orders),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colors,
    List<ProductionOrder> orders,
  ) {
    final isTablet = MediaQuery.of(context).size.width > 768;

    // Filter by sub-tab: 0=Personal, 1=Pesanan(Custom), 2=Stok(Restock)
    final filteredOrders = _selectedSubTab == 0
        ? orders.where((o) => o.isPersonal).toList()
        : _selectedSubTab == 1
            ? orders.where((o) => o.isCustom).toList()
            : orders.where((o) => o.isRestock).toList();

    // Calculate metrics from ALL orders
    final activeOrders = orders.where((o) => o.status != 'COMPLETED').toList();
    final inProgressOrders = orders
        .where((o) => o.status == 'IN_PROGRESS')
        .toList();
    final pendingOrders = orders.where((o) => o.status == 'PENDING').toList();
    final completedOrders = orders
        .where((o) => o.status == 'COMPLETED')
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
      children: [
        // Grid 2x2 Metrics (Mobile) or 1x4 Metrics (Tablet)
        if (isTablet)
          Row(
            children: [
              Expanded(child: _buildMetricCard('TOTAL AKTIF', activeOrders.length.toString(), Icons.assignment_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('PROSES', inProgressOrders.length.toString(), Icons.pending_actions)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('PENDING', pendingOrders.length.toString(), Icons.hourglass_empty)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('SELESAI', completedOrders.length.toString(), Icons.check_circle_outline)),
            ],
          )
        else
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildMetricCard('TOTAL AKTIF', activeOrders.length.toString(), Icons.assignment_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMetricCard('PROSES', inProgressOrders.length.toString(), Icons.pending_actions)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildMetricCard('PENDING', pendingOrders.length.toString(), Icons.hourglass_empty)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMetricCard('SELESAI', completedOrders.length.toString(), Icons.check_circle_outline)),
                ],
              ),
            ],
          ),
        const SizedBox(height: 24),

        // ── Sub-tab Toggle: Personal / Pesanan / Stok ──
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F4),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _buildSubTab(
                index: 0,
                icon: Icons.person_outline,
                label: 'Personal',
                count: orders.where((o) => o.isPersonal).length,
              ),
              const SizedBox(width: 4),
              _buildSubTab(
                index: 1,
                icon: Icons.storefront_outlined,
                label: 'Pesanan',
                count: orders.where((o) => o.isCustom).length,
              ),
              const SizedBox(width: 4),
              _buildSubTab(
                index: 2,
                icon: Icons.inventory_2_outlined,
                label: 'Stok',
                count: orders.where((o) => o.isRestock).length,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Search Bar
        if (isTablet)
          Row(
            children: [
              Expanded(flex: 3, child: _buildSearchBar()),
              const SizedBox(width: 16),
              _buildFilterButton(),
            ],
          )
        else
          Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildFilterButton(fullWidth: true),
            ],
          ),
        const SizedBox(height: 24),

        // SPK Cards
        if (filteredOrders.isEmpty)
          _buildEmptyState()
        else if (isTablet)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 500,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 180, // Approximate height
            ),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(context, filteredOrders[index]);
            },
          )
        else
          ...filteredOrders.map((order) => _buildOrderCard(context, order)),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return AppMetricCard(
      label: label,
      value: value,
      icon: icon,
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      height: 48,
      child: TextField(
        decoration: InputDecoration(
          hintText: _selectedSubTab == 0
              ? 'Cari nama pelanggan...'
              : _selectedSubTab == 1
                  ? 'Cari pesanan produksi...'
                  : 'Cari SPK stok...',
          hintStyle: GoogleFonts.inter(
            color: Colors.grey.shade500,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.shade500,
            size: 20,
          ),
          filled: true,
          fillColor: const Color(0xFFF2F4F4),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton({bool fullWidth = false}) {
    return Container(
      height: 48,
      width: fullWidth ? double.infinity : 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: fullWidth 
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.filter_list, color: Colors.black87),
              const SizedBox(width: 8),
              Text('Filter', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ],
          )
        : const Icon(Icons.filter_list, color: Colors.black87),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              _selectedSubTab == 0
                  ? Icons.person_outline
                  : _selectedSubTab == 1
                      ? Icons.storefront_outlined
                      : Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedSubTab == 0
                  ? 'Belum ada pesanan personal'
                  : _selectedSubTab == 1
                      ? 'Belum ada pesanan produksi'
                      : 'Belum ada SPK stok',
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, ProductionOrder order) {
    Color statusColor;
    Color statusTextColor;
    String statusLabel;

    switch (order.status) {
      case 'COMPLETED':
        statusColor = const Color(0xFFA4F0E9);
        statusTextColor = const Color(0xFF004D4C);
        statusLabel = 'SELESAI';
        break;
      case 'IN_PROGRESS':
        statusColor = const Color.fromARGB(255, 205, 234, 129);
        statusTextColor = const Color(0xFF004D4C);
        statusLabel = 'PROSES';
        break;
      default:
        statusColor = const Color(0xFFCBE7F5);
        statusTextColor = const Color(0xFF1E40AF);
        statusLabel = 'TERJADWAL';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          context.go('/inventory/spk-detail', extra: order.id);
        },
        child: InventorySpkCard(
          id: order.id,
          date: _formatDate(order.createdAt),
          title: order.title,
          status: statusLabel,
          statusColor: statusColor,
          statusTextColor: statusTextColor,
          progress: order.progressPercent,
          progressBarColor: order.isCompleted
              ? const Color(0xFF004D4C)
              : order.progressPercent > 0.8
                  ? Colors.red.shade700
                  : const Color(0xFF004D4C),
          bottomLeftWidget: Row(
            children: [
              // Type badge
              Builder(builder: (_) {
                String badgeLabel;
                Color badgeBg;
                Color badgeFg;
                if (order.isPersonal) {
                  badgeLabel = 'Personal';
                  badgeBg = Colors.amber.shade50;
                  badgeFg = Colors.amber.shade800;
                } else if (order.isCustom) {
                  badgeLabel = 'Pesanan';
                  badgeBg = Colors.orange.shade50;
                  badgeFg = Colors.orange.shade800;
                } else {
                  badgeLabel = 'Stok';
                  badgeBg = const Color(0xFFE0F2F1);
                  badgeFg = const Color(0xFF004D4C);
                }
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeLabel,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: badgeFg,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 8),
              // Customer name or tailor info
              if (order.isPersonal && order.customerName != null && order.customerName!.isNotEmpty) ...[
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    order.customerName!,
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (order.pickupDate != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '• ${DateFormat('dd MMM').format(order.pickupDate!)}',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ] else ...[
                Icon(
                  order.isCompleted ? Icons.check_circle : Icons.people_outline,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  order.isCompleted ? 'QC PASSED' : '${order.tailorAssignments.length} Penjahit',
                  style: GoogleFonts.inter(
                    color: order.isCompleted ? const Color(0xFF004D4C) : Colors.grey.shade600,
                    fontSize: 10,
                    fontWeight: order.isCompleted ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSubTab({
    required int index,
    required IconData icon,
    required String label,
    required int count,
  }) {
    final isSelected = _selectedSubTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSubTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? const Color(0xFF004D4C)
                    : Colors.grey.shade500,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  color: isSelected
                      ? const Color(0xFF004D4C)
                      : Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFA4F0E9)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? const Color(0xFF004D4C)
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MEI',
      'JUN',
      'JUL',
      'AGU',
      'SEP',
      'OKT',
      'NOV',
      'DES',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
