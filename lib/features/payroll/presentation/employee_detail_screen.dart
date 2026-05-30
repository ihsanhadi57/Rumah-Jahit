import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rumah_jahit/core/widgets/detail_widgets.dart';
import 'package:rumah_jahit/core/utils/currency_utils.dart';
import '../domain/app_user.dart';
import '../data/payroll_providers.dart';

import 'widgets/profile_summary_card.dart';
import 'widgets/payroll_adjustments_card.dart';
import 'widgets/detailed_payroll_card.dart';
import 'widgets/production_stats_card.dart';
import 'widgets/employee_quick_production_bottom_sheet.dart';
import 'package:rumah_jahit/features/inventory/data/inventory_providers.dart';
import 'package:rumah_jahit/features/inventory/domain/product.dart';
import 'package:rumah_jahit/core/widgets/product_picker_sheet.dart';

class EmployeeDetailScreen extends ConsumerStatefulWidget {
  final AppUser employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  ConsumerState<EmployeeDetailScreen> createState() =>
      _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends ConsumerState<EmployeeDetailScreen> {
  late AppUser _employee;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
  }

  // ─── Edit Profile Dialog ───
  Future<void> _showEditProfileDialog() async {
    final nameCtrl = TextEditingController(text: _employee.name);
    final phoneCtrl = TextEditingController(text: _employee.phone);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Profil',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    hintText: 'Masukkan nama',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF2F4F4),
                  ),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(
                    labelText: 'No. Telepon',
                    hintText: '08xxxxxxxxxx',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF2F4F4),
                  ),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                // Role display (read-only)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Role',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          Text(
                            _employee.roleDisplay,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D4C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Simpan',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      final updatedUser = _employee.copyWith(
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
      );
      await ref.read(userRepositoryProvider).update(updatedUser);
      setState(() {
        _employee = updatedUser;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Process Payout ───
  Future<void> _processPayout(List<String> recordIds, double total) async {
    if (recordIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Konfirmasi Pembayaran',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin membayar gaji sebesar ${formatCurrency(total)} ke ${_employee.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D4C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Bayar Sekarang'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(payrollRepositoryProvider);
      for (final id in recordIds) {
        await repo.markPaid(id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran gaji berhasil diselesaikan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses pembayaran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onTambahHasilKerjaPressed(
    ColorScheme colors,
    AsyncValue<List<Product>> productsAsync,
  ) {
    final products = productsAsync.value;
    if (products == null || products.isEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => EmployeeQuickProductionBottomSheet(
          employee: _employee,
        ),
      );
      return;
    }

    final grouped = <String, List<Product>>{};
    for (final p in products) {
      final key = '${p.name}_${p.schoolLevels.join('_')}_${p.type}';
      grouped.putIfAbsent(key, () => []).add(p);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ProductPickerSheet(
          grouped: grouped,
          selectedKey: null,
          colors: colors,
          title: 'Pilih Produk',
          subtitle: 'Cari dan pilih produk yang baru saja dijahit',
          onSelected: (key) {
            Navigator.pop(ctx);
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx2) => EmployeeQuickProductionBottomSheet(
                employee: _employee,
                initialProductGroup: key,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final payrollAsync = ref.watch(unpaidPayrollByUserProvider(_employee.id));
    final paidPayrollAsync = ref.watch(paidPayrollByUserProvider(_employee.id));
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          'Detail Karyawan',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: colors.primary,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth > 900;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: isTablet
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column: Profile & Production
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    ProfileSummaryCard(
                                      name: _employee.name,
                                      role: _employee.roleDisplay,
                                      avatarUrl: _employee.imageUrl,
                                      phone: _employee.phone,
                                      email: _employee.email,
                                      onEditProfile: _showEditProfileDialog,
                                    ),
                                    if (_employee.isTailor) ...[
                                      const SizedBox(height: 24),
                                      ProductionStatsCard(userId: _employee.id),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 32),
                              // Right Column: Payroll & History
                              Expanded(
                                flex: 7,
                                child: Column(
                                  children: [
                                    PayrollAdjustmentsCard(
                                      userId: _employee.id,
                                      userName: _employee.name,
                                    ),
                                    const SizedBox(height: 24),
                                    DetailedPayrollCard(userId: _employee.id),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _onTambahHasilKerjaPressed(colors, productsAsync),
                                        icon: const Icon(Icons.add),
                                        label: Text(
                                          'Tambah Hasil Kerja',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colors.primary
                                              .withValues(alpha: 0.1),
                                          foregroundColor: colors.primary,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    _buildPaidSalaryHistory(paidPayrollAsync),
                                    const SizedBox(
                                      height: 160,
                                    ), // Extra space for bottom bar
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              ProfileSummaryCard(
                                name: _employee.name,
                                role: _employee.roleDisplay,
                                avatarUrl: _employee.imageUrl,
                                phone: _employee.phone,
                                email: _employee.email,
                                onEditProfile: _showEditProfileDialog,
                              ),
                              if (_employee.isTailor) ...[
                                const SizedBox(height: 24),
                                ProductionStatsCard(userId: _employee.id),
                              ],
                              const SizedBox(height: 24),
                              PayrollAdjustmentsCard(
                                userId: _employee.id,
                                userName: _employee.name,
                              ),
                              const SizedBox(height: 24),
                              DetailedPayrollCard(userId: _employee.id),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _onTambahHasilKerjaPressed(colors, productsAsync),
                                  icon: const Icon(Icons.add),
                                  label: Text(
                                    'Tambah Hasil Kerja',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    foregroundColor: colors.primary,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildPaidSalaryHistory(paidPayrollAsync),
                              const SizedBox(
                                height: 140,
                              ), // Extra space for bottom bar
                            ],
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: payrollAsync.when(
                        data: (records) {
                          final total = records.fold<double>(
                            0,
                            (sum, r) => sum + r.totalWage,
                          );
                          final ids = records.map((r) => r.id).toList();

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TOTAL GAJI TERAKUMULASI',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.grey.shade500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        formatCurrency(total),
                                        style: GoogleFonts.manrope(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: colors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: total <= 0
                                      ? null
                                      : () => _processPayout(ids, total),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF004D4C),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'Bayar Gaji',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (error, stack) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Paid Salary History Widget ───
  Widget _buildPaidSalaryHistory(AsyncValue paidPayrollAsync) {
    return DetailSection(
      label: 'RIWAYAT GAJI TERBAYAR',
      icon: Icons.history,
      children: [
        paidPayrollAsync.when(
          data: (records) {
            if (records.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 40,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada riwayat pembayaran',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Group records by month
            final Map<String, List> grouped = {};
            for (final record in records) {
              final key = DateFormat('MMMM yyyy').format(record.createdAt);
              grouped.putIfAbsent(key, () => []);
              grouped[key]!.add(record);
            }

            return Column(
              children: grouped.entries.map((entry) {
                final monthTotal = entry.value.fold<double>(
                  0,
                  (sum, r) => sum + r.totalWage,
                );
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Colors.green.shade600,
                        ),
                      ),
                      title: Text(
                        entry.key,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${entry.value.length} item • ${formatCurrency(monthTotal)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      children: entry.value.map<Widget>((record) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                record.isAdjustment
                                    ? Icons.tune
                                    : Icons.checkroom,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.isAdjustment
                                          ? (record.note ?? 'Penyesuaian')
                                          : (record.spkTitle ?? 'SPK'),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      DateFormat(
                                        'dd MMM yyyy',
                                      ).format(record.createdAt),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatCurrency(record.totalWage),
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }
}
