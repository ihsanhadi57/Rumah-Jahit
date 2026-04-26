import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/finance_providers.dart';
import '../domain/finance_transaction.dart';
import '../../../../core/utils/currency_utils.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final transactionsAsync = ref.watch(filteredFinanceTransactionsProvider);
    final balanceAsync = ref.watch(totalBalanceProvider);
    final incomeAsync = ref.watch(totalIncomeProvider);
    final expenseAsync = ref.watch(totalExpenseProvider);
    final dateRange = ref.watch(financeDateRangeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: Text(
          'Pencatatan Keuangan',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => _showDateRangePicker(context, ref),
            icon: Icon(
              dateRange != null ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: dateRange != null ? colors.primary : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 768;

          if (isTablet) {
            return _buildTabletLayout(
              context,
              ref,
              balanceAsync,
              incomeAsync,
              expenseAsync,
              transactionsAsync,
              colors,
              dateRange,
            );
          }

          return _buildMobileLayout(
            context,
            ref,
            balanceAsync,
            incomeAsync,
            expenseAsync,
            transactionsAsync,
            colors,
            dateRange,
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<double> balanceAsync,
    AsyncValue<double> incomeAsync,
    AsyncValue<double> expenseAsync,
    AsyncValue<List<FinanceTransaction>> transactionsAsync,
    ColorScheme colors,
    DateTimeRange? dateRange,
  ) {
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(financeTransactionsProvider),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildBalanceCard(balanceAsync, incomeAsync, expenseAsync, colors),
          const SizedBox(height: 28),
          _buildQuickActions(context, ref, colors),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Riwayat Transaksi',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              if (dateRange != null)
                GestureDetector(
                  onTap: () => ref.read(financeDateRangeProvider.notifier).state = null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Reset',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.close, size: 14, color: colors.primary),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (dateRange != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _formatDateRange(dateRange),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 16),
          _buildFilterChips(ref, colors),
          const SizedBox(height: 16),
          _buildTransactionList(ref, transactionsAsync, colors, shrinkWrap: true, physics: const NeverScrollableScrollPhysics()),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<double> balanceAsync,
    AsyncValue<double> incomeAsync,
    AsyncValue<double> expenseAsync,
    AsyncValue<List<FinanceTransaction>> transactionsAsync,
    ColorScheme colors,
    DateTimeRange? dateRange,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Summary & Actions
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(balanceAsync, incomeAsync, expenseAsync, colors),
                  const SizedBox(height: 32),
                  Text(
                    'Aksi Cepat',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActions(context, ref, colors),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: colors.primary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Catatan keuangan ini disinkronkan secara real-time dengan seluruh perangkat.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: colors.primary.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right Column: Transactions
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Transaksi',
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                          ),
                        ),
                        if (dateRange != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _formatDateRange(dateRange),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        if (dateRange != null)
                          TextButton.icon(
                            onPressed: () => ref.read(financeDateRangeProvider.notifier).state = null,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Reset Filter'),
                            style: TextButton.styleFrom(foregroundColor: Colors.grey),
                          ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showDateRangePicker(context, ref),
                          icon: const Icon(Icons.date_range_rounded, size: 18),
                          label: const Text('Pilih Tanggal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary.withValues(alpha: 0.1),
                            foregroundColor: colors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildFilterChips(ref, colors),
                const SizedBox(height: 16),
                Expanded(child: _buildTransactionList(ref, transactionsAsync, colors, shrinkWrap: false, physics: const AlwaysScrollableScrollPhysics())),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(
    AsyncValue<double> balanceAsync,
    AsyncValue<double> incomeAsync,
    AsyncValue<double> expenseAsync,
    ColorScheme colors,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [colors.primary, const Color(0xFF005857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL SALDO',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Icon(Icons.account_balance_wallet_outlined, color: Colors.white.withValues(alpha: 0.5), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          balanceAsync.when(
            loading: () => const Text('...', style: TextStyle(color: Colors.white, fontSize: 32)),
            error: (_, _) => const Text('Error', style: TextStyle(color: Colors.white, fontSize: 32)),
            data: (balance) => Text(
              formatCurrency(balance),
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              _buildSummaryItem(
                Icons.arrow_downward,
                'Masuk',
                incomeAsync.maybeWhen(data: (v) => formatCurrency(v), orElse: () => 'Rp 0'),
                Colors.white.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 12),
              _buildSummaryItem(
                Icons.arrow_upward,
                'Keluar',
                expenseAsync.maybeWhen(data: (v) => formatCurrency(v), orElse: () => 'Rp 0'),
                Colors.white.withValues(alpha: 0.15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String amount, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                  Flexible(
                    child: Text(
                      amount,
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref, ColorScheme colors) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Uang Masuk',
            Icons.add_rounded,
            const Color(0xFF10B981),
            () => _showTransactionBottomSheet(context, ref, type: FinanceTransactionType.income),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            'Uang Keluar',
            Icons.remove_rounded,
            const Color(0xFFF43F5E),
            () => _showTransactionBottomSheet(context, ref, type: FinanceTransactionType.expense),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(
    WidgetRef ref,
    AsyncValue<List<FinanceTransaction>> transactionsAsync,
    ColorScheme colors, {
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Gagal memuat data')),
      data: (transactions) {
        if (transactions.isEmpty) {
          return shrinkWrap
              ? _buildEmptyState()
              : Center(child: _buildEmptyState());
        }

        return ListView.separated(
          shrinkWrap: shrinkWrap,
          physics: physics,
          itemCount: transactions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isIncome = tx.type == FinanceTransactionType.income;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                      color: isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.title,
                          style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.grey.shade900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(tx.createdAt),
                          style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isIncome ? '+' : '-'} ${formatCurrency(tx.amount)}',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          color: isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                          fontSize: 15,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey.shade400),
                        onPressed: () => _confirmDelete(context, ref, tx),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChips(WidgetRef ref, ColorScheme colors) {
    final currentFilter = ref.watch(financeTypeFilterProvider);
    
    return Row(
      children: [
        _filterChip(ref, 'Semua', FinanceFilterType.all, currentFilter, colors),
        const SizedBox(width: 8),
        _filterChip(ref, 'Masuk', FinanceFilterType.income, currentFilter, colors),
        const SizedBox(width: 8),
        _filterChip(ref, 'Keluar', FinanceFilterType.expense, currentFilter, colors),
      ],
    );
  }

  Widget _filterChip(WidgetRef ref, String label, FinanceFilterType type, FinanceFilterType current, ColorScheme colors) {
    final isSelected = type == current;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) ref.read(financeTypeFilterProvider.notifier).state = type;
      },
      selectedColor: colors.primary.withValues(alpha: 0.2),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? colors.primary : Colors.grey.shade600,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? colors.primary : Colors.grey.shade200,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
        ),
        const SizedBox(height: 20),
        Text(
          'Belum ada transaksi',
          style: GoogleFonts.manrope(
            color: Colors.grey.shade600,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Catat transaksi pertama Anda hari ini',
          style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
        ),
      ],
    );
  }

  void _showTransactionBottomSheet(BuildContext context, WidgetRef ref, {required FinanceTransactionType type}) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final colors = Theme.of(context).colorScheme;
    final isIncome = type == FinanceTransactionType.income;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isIncome ? Icons.add_business_rounded : Icons.payments_rounded,
                      color: isIncome ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    isIncome ? 'Tambah Pemasukan' : 'Catat Pengeluaran',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Keterangan Transaksi',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: isIncome ? 'Contoh: Jasa Jahit Seragam' : 'Contoh: Beli Benang & Kancing',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nominal',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: colors.primary),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Strip dots before parsing
                    final cleanAmount = amountController.text.replaceAll('.', '');
                    final amount = double.tryParse(cleanAmount) ?? 0;
                    
                    if (titleController.text.isNotEmpty && amount > 0) {
                      final tx = FinanceTransaction(
                        id: '',
                        title: titleController.text,
                        amount: amount,
                        type: type,
                        createdAt: DateTime.now(),
                      );
                      await ref.read(financeRepositoryProvider).addTransaction(tx);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Simpan Transaksi',
                    style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showDateRangePicker(BuildContext context, WidgetRef ref) async {
    final currentRange = ref.read(financeDateRangeProvider);
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: currentRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      ref.read(financeDateRangeProvider.notifier).state = pickedRange;
    }
  }

  String _formatDateRange(DateTimeRange? range) {
    if (range == null) return 'Semua Waktu';
    final start = DateFormat('dd MMM yyyy').format(range.start);
    final end = DateFormat('dd MMM yyyy').format(range.end);
    return '$start - $end';
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, FinanceTransaction tx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Hapus Transaksi', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        content: Text('Hapus catatan "${tx.title}" dari riwayat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(financeRepositoryProvider).deleteTransaction(tx.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFFF43F5E),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
