import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:rumah_jahit/features/pos/data/pos_providers.dart';
import 'package:rumah_jahit/features/pos/domain/transaction_model.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  DateTimeRange? _selectedDateRange;

  final List<String> _filters = ['Semua', 'Hari Ini', 'Minggu Ini', 'Pending', 'Selesai'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.toLowerCase());
  }

  bool _passesFilter(TransactionModel tx) {
    // 1. Search Query
    if (_searchQuery.isNotEmpty) {
      if (!tx.formattedId.toLowerCase().contains(_searchQuery)) {
        return false;
      }
    }

    // 2. Date Range Filter
    if (_selectedDateRange != null) {
      final start = _selectedDateRange!.start;
      final end = _selectedDateRange!.end;
      final txDate = DateTime(
        tx.createdAt.year,
        tx.createdAt.month,
        tx.createdAt.day,
      );
      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day);

      if (txDate.isBefore(startDate) || txDate.isAfter(endDate)) {
        return false;
      }
    }

    // 3. Chip Filter
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Hari Ini':
        if (tx.createdAt.year != now.year ||
            tx.createdAt.month != now.month ||
            tx.createdAt.day != now.day) {
          return false;
        }
        break;
      case 'Minggu Ini':
        final lastWeek = now.subtract(const Duration(days: 7));
        if (tx.createdAt.isBefore(lastWeek)) {
          return false;
        }
        break;
      case 'Selesai':
        if (tx.status != 'SUCCESS' && tx.status != 'SUCCESSFUL') {
          return false;
        }
        break;
      case 'Pending':
        if (tx.status != 'PENDING') {
          return false;
        }
        break;
      case 'Semua':
      default:
        break;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final isTablet = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFA),
        scrolledUnderElevation: 0,
        title: Text(
          'Riwayat Transaksi',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF003D3D),
          ),
        ),
        leading: ActionChip(
          onPressed: () => Navigator.of(context).pop(),
          backgroundColor: Colors.transparent,
          side: BorderSide.none,
          label: const Icon(Icons.arrow_back, color: Color(0xFF003D3D)),
        ),
        actions: [
          if (_selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              onPressed: () => setState(() => _selectedDateRange = null),
              tooltip: 'Hapus Filter Tanggal',
            ),
          IconButton(
            icon: Icon(
              Icons.date_range,
              color: _selectedDateRange != null
                  ? const Color(0xFF006766)
                  : const Color(0xFF003D3D),
            ),
            tooltip: 'Filter Tanggal',
            onPressed: () async {
              final result = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _selectedDateRange,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF003D3D),
                        onPrimary: Colors.white,
                        onSurface: Color(0xFF003D3D),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (result != null) {
                setState(() {
                  _selectedDateRange = result;
                  if (_selectedFilter == 'Hari Ini' ||
                      _selectedFilter == 'Minggu Ini') {
                    _selectedFilter = 'Semua';
                  }
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF003D3D)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: isTablet
                ? Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildSearchBar(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: _buildFilterChips(),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildFilterChips(),
                    ],
                  ),
          ),
          const SizedBox(height: 16),

          // List List
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (allData) {
                final data = allData.where(_passesFilter).toList();
                final isTablet = MediaQuery.of(context).size.width > 768;

                if (data.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada riwayat transaksi.',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                if (isTablet) {
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 500,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      mainAxisExtent: 320, // Approximate height for the card
                    ),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final tx = data[index];
                      return _buildTransactionCard(tx, colors.primary);
                    },
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: data.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final tx = data[index];
                    return _buildTransactionCard(tx, colors.primary);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Cari ID Pesanan...',
        hintStyle: GoogleFonts.inter(
          color: Colors.grey.shade400,
          fontSize: 13,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: Colors.grey.shade500,
          size: 20,
        ),
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = filter == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF004D4C) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx, Color primaryColor) {
    final bool isSuccess = tx.status == 'SUCCESS' || tx.status == 'SUCCESSFUL';
    final formatter = DateFormat('dd MMM yyyy • HH:mm');

    return GestureDetector(
      onTap: () {
        context.push('/pos/receipt', extra: tx);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID PESANAN',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF006766),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx.formattedId,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF003D3D),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? const Color(0xFFA4F0E9)
                        : Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSuccess ? Icons.check_circle : Icons.schedule,
                        size: 12,
                        color: isSuccess
                            ? const Color(0xFF004D4C)
                            : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSuccess ? 'SUCCESSFUL' : 'PENDING',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isSuccess
                              ? const Color(0xFF004D4C)
                              : Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  formatter.format(tx.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Items Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (tx.items.isEmpty)
                    Text(
                      'Tidak ada data item',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ...tx.items.take(2).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item.productId.startsWith('custom_')
                                  ? Icons.edit_note
                                  : Icons.checkroom,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity}x ${item.productName}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: const Color(0xFF001F1F),
                                  ),
                                ),
                                if (item.size.isNotEmpty)
                                  Text(
                                    item.size,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (tx.items.length > 2)
                    Text(
                      '+ ${tx.items.length - 2} item lainnya',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF006766),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Footer: Payment & Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            tx.paymentMethod == 'CASH'
                                ? Icons.money
                                : tx.paymentMethod == 'TRANSFER'
                                ? Icons.account_balance
                                : Icons.qr_code_2,
                            size: 14,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tx.paymentMethod == 'CASH'
                                ? 'Tunai'
                                : tx.paymentMethod == 'TRANSFER'
                                ? 'Transfer'
                                : 'QRIS',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx.customerName != null && tx.customerName!.isNotEmpty
                            ? 'PELANGGAN: ${tx.customerName!.toUpperCase()}'
                            : 'PELANGGAN: UMUM',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TOTAL TAGIHAN',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.formattedGrandTotal,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF003D3D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
