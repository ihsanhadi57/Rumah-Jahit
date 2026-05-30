import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:rumah_jahit/features/inventory/data/inventory_providers.dart';
import 'package:rumah_jahit/features/inventory/domain/product.dart';
import 'package:rumah_jahit/features/inventory/domain/production_order.dart';
import 'package:rumah_jahit/features/inventory/domain/raw_material.dart';
import 'package:rumah_jahit/features/payroll/data/payroll_providers.dart';
import 'package:rumah_jahit/core/utils/currency_utils.dart';
import 'package:rumah_jahit/core/utils/snackbar_utils.dart';
import 'package:rumah_jahit/core/widgets/custom_text_field.dart';
import 'package:rumah_jahit/core/widgets/product_picker_sheet.dart';
import 'package:rumah_jahit/features/settings/data/settings_providers.dart';
import 'package:rumah_jahit/features/settings/domain/wage_category.dart';


class AddSpkForm extends ConsumerStatefulWidget {
  const AddSpkForm({super.key});

  @override
  ConsumerState<AddSpkForm> createState() => _AddSpkFormState();
}

class _AddSpkFormState extends ConsumerState<AddSpkForm> {
  final _formKey = GlobalKey<FormState>();
  // null = type not yet chosen, user is on type selection screen
  String? _spkType; // 'RESTOCK' or 'CUSTOM'
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1 (RESTOCK): Product & Dates
  String? _selectedProductGroup;
  final _titleController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _estimatedEndDate = DateTime.now().add(const Duration(days: 7));

  // Step 1 (CUSTOM): Manual product info
  final _customProductNameController = TextEditingController();
  final _customProductTypeController = TextEditingController();

  // Step 2: Wage & Materials (tailors auto-assigned)
  final _wageController = TextEditingController();
  bool _hasAutoDetectedWage = false;
  WageCategory? _selectedWageCategory;
  bool _isManualWage = true;
  final List<RawMaterial> _selectedMaterialsList = [];
  final Map<String, TextEditingController> _materialQtyControllers = {};

  @override
  void dispose() {
    _titleController.dispose();
    _wageController.dispose();
    _customProductNameController.dispose();
    _customProductTypeController.dispose();
    for (final c in _materialQtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // If type not selected yet, show type selection
    if (_spkType == null) {
      return _buildTypeSelection(colors);
    }

    final productsAsync = ref.watch(productsStreamProvider);
    final materialsAsync = ref.watch(rawMaterialsStreamProvider);
    final wageCategoriesAsync = ref.watch(wageCategoriesStreamProvider);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          maxWidth: 480,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buat SPK Baru',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _spkType == 'CUSTOM'
                                ? Colors.orange.shade50
                                : colors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _spkType == 'CUSTOM'
                                ? '📋 Pesanan Produksi'
                                : '📦 Tambah Stok',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _spkType == 'CUSTOM'
                                  ? Colors.orange.shade800
                                  : colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: Colors.grey.shade400),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _buildStepIndicator(colors),
              const SizedBox(height: 20),

              // ── Content ──
              Flexible(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: _currentStep == 0
                        ? _spkType == 'CUSTOM'
                              ? _buildCustomStep1(colors)
                              : _buildRestockStep1(productsAsync, colors)
                        : _buildStep2WageMaterials(
                            materialsAsync,
                            wageCategoriesAsync,
                            colors,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Navigation Buttons ──
              Row(
                children: [
                  // Back button: go to previous step OR back to type selection
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (_currentStep > 0) {
                          setState(() => _currentStep--);
                        } else {
                          // Go back to type selection
                          setState(() => _spkType = null);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Kembali',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _currentStep < 1 ? 'Lanjut' : 'Simpan SPK',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // TYPE SELECTION SCREEN
  // ══════════════════════════════════════
  Widget _buildTypeSelection(ColorScheme colors) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Buat SPK Baru',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: Colors.grey.shade400),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih jenis SPK yang ingin dibuat',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // Option 1: Tambah Stok
              _buildTypeCard(
                colors: colors,
                icon: Icons.inventory_2_outlined,
                title: 'Tambah Stok Gudang',
                subtitle:
                    'Produksi untuk menambah stok produk yang sudah terdaftar di inventaris',
                isRestock: true,
                onTap: () => setState(() => _spkType = 'RESTOCK'),
              ),
              const SizedBox(height: 12),

              // Option 2: Pesanan Produksi
              _buildTypeCard(
                colors: colors,
                icon: Icons.storefront_outlined,
                title: 'Pesanan Produksi',
                subtitle:
                    'Produksi untuk pesanan khusus (massal/borongan) yang tidak terdaftar di inventaris',
                isRestock: false,
                onTap: () => setState(() => _spkType = 'CUSTOM'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required ColorScheme colors,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isRestock,
    required VoidCallback onTap,
  }) {
    final cardColor = isRestock
        ? colors.primary.withValues(alpha: 0.06)
        : Colors.amber.shade50;
    final accentColor = isRestock ? colors.primary : Colors.amber.shade800;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: accentColor),
          ],
        ),
      ),
    );
  }

  // ── Step Indicator ──
  Widget _buildStepIndicator(ColorScheme colors) {
    final steps = ['Produk', 'Upah & Bahan'];
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i == _currentStep;
        final isDone = i < _currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDone
                  ? colors.primary.withValues(alpha: 0.15)
                  : isActive
                  ? colors.primary.withValues(alpha: 0.1)
                  : const Color(0xFFF2F4F4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                if (isDone)
                  Icon(Icons.check_circle, size: 16, color: colors.primary)
                else
                  Text(
                    '${i + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? colors.primary : Colors.grey.shade400,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  steps[i],
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isActive || isDone
                        ? colors.primary
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ══════════════════════════════════════
  // STEP 1 (RESTOCK): Product & Dates
  // ══════════════════════════════════════
  Widget _buildRestockStep1(
    AsyncValue<List<Product>> productsAsync,
    ColorScheme colors,
  ) {
    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (products) {
        // Group products by name+type+school level
        final grouped = <String, List<Product>>{};
        for (final p in products) {
          final key = '${p.name}_${p.schoolLevels.join('_')}_${p.type}';
          grouped.putIfAbsent(key, () => []).add(p);
        }

        // Available sizes for selected group
        final availableSizes = <Product>[];
        if (_selectedProductGroup != null &&
            grouped.containsKey(_selectedProductGroup)) {
          availableSizes.addAll(grouped[_selectedProductGroup]!);
        }

        // Display name for selected product
        String? selectedDisplayName;
        if (_selectedProductGroup != null &&
            grouped.containsKey(_selectedProductGroup)) {
          final first = grouped[_selectedProductGroup]!.first;
          selectedDisplayName =
              '${first.name} ${first.schoolLevels.join('/')} - ${first.type}';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _titleController,
              label: 'Judul SPK',
              hint: 'SPK Baju OSIS SMP Pertama',
              icon: Icons.assignment_outlined,
              showLabelOutside: true,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Judul SPK wajib diisi'
                  : null,
            ),
            const SizedBox(height: 20),

            _buildLabel('Pilih Produk'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showProductPicker(context, grouped, colors),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F4),
                  borderRadius: BorderRadius.circular(12),
                  border: _selectedProductGroup != null
                      ? Border.all(
                          color: colors.primary.withValues(alpha: 0.3),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedProductGroup != null
                          ? Icons.checkroom
                          : Icons.search,
                      size: 18,
                      color: _selectedProductGroup != null
                          ? colors.primary
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedDisplayName ?? 'Ketuk untuk pilih produk...',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _selectedProductGroup != null
                              ? Colors.black87
                              : Colors.grey.shade400,
                          fontWeight: _selectedProductGroup != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Show auto-included sizes (read-only info)
            if (_selectedProductGroup != null && availableSizes.isNotEmpty) ...[
              _buildLabel('Ukuran Otomatis Tercatat'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableSizes.map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      p.size,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'Semua ukuran akan otomatis dimasukkan. Jumlah dicatat saat produksi harian.',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Dates
            _buildDatesRow(colors),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════
  // STEP 1 (CUSTOM): Manual Product Info
  // ══════════════════════════════════════
  Widget _buildCustomStep1(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _titleController,
          label: 'Judul SPK',
          hint: 'Tambah stok Baju Osis',
          icon: Icons.assignment_outlined,
          showLabelOutside: true,
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Judul SPK wajib diisi' : null,
        ),
        const SizedBox(height: 20),

        CustomTextField(
          controller: _customProductNameController,
          label: 'Nama Produk',
          hint: 'Baju Osis smp',
          icon: Icons.checkroom_outlined,
          showLabelOutside: true,
          textCapitalization: TextCapitalization.words,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Nama produk wajib diisi'
              : null,
        ),
        const SizedBox(height: 20),

        CustomTextField(
          controller: _customProductTypeController,
          label: 'Tipe / Keterangan',
          hint: 'Lengan Panjang',
          icon: Icons.label_outline,
          showLabelOutside: true,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        Text(
          'Jumlah produksi akan dicatat secara dinamis saat produksi harian.',
          style: GoogleFonts.inter(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 20),

        // Dates
        _buildDatesRow(colors),
      ],
    );
  }

  // ── Shared Dates Row ──
  Widget _buildDatesRow(ColorScheme colors) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Tanggal Mulai'),
              const SizedBox(height: 8),
              _buildDatePicker(
                date: _startDate,
                onPick: (d) => setState(() => _startDate = d),
                colors: colors,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Estimasi Selesai'),
              const SizedBox(height: 8),
              _buildDatePicker(
                date: _estimatedEndDate,
                onPick: (d) => setState(() => _estimatedEndDate = d),
                colors: colors,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required DateTime date,
    required ValueChanged<DateTime> onPick,
    required ColorScheme colors,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2WageMaterials(
    AsyncValue<List<RawMaterial>> materialsAsync,
    AsyncValue<List<WageCategory>> wageCategoriesAsync,
    ColorScheme colors,
  ) {
    return materialsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (materials) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Tipe Upah Tetap (Opsional)'),
            const SizedBox(height: 8),
            wageCategoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return Text(
                    'Belum ada pengaturan upah. Silakan atur di menu Settings.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  );
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _isManualWage
                          ? 'MANUAL'
                          : _selectedWageCategory?.id,
                      isExpanded: true,
                      hint: Text(
                        'Pilih Tipe Upah...',
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: [
                        DropdownMenuItem(
                          value: 'MANUAL',
                          child: Text(
                            'Input Manual',
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        ),
                        ...categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat.id,
                            child: Text(
                              '${cat.name} (${formatCurrency(cat.amount)})',
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          if (val == 'MANUAL') {
                            _isManualWage = true;
                            _selectedWageCategory = null;
                            _wageController.clear();
                          } else {
                            _isManualWage = false;
                            _selectedWageCategory = categories.firstWhere(
                              (c) => c.id == val,
                            );
                            _wageController.text = formatCurrency(
                              _selectedWageCategory!.amount,
                            );
                          }
                        });
                      },
                    ),
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading wages: $e'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _wageController,
              label: 'Upah per pcs',
              hint: 'Rp 0',
              icon: Icons.payments_outlined,
              showLabelOutside: true,
              keyboardType: TextInputType.number,
              readOnly: !_isManualWage,
              fillColor: !_isManualWage ? const Color(0xFFF5F5F5) : null,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                RupiahInputFormatter(),
              ],
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: !_isManualWage ? Colors.grey.shade700 : Colors.black,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Upah wajib diisi';
                final raw = v.replaceAll(RegExp(r'[^\d]'), '');
                final amount = double.tryParse(raw) ?? 0;
                if (amount <= 0) return 'Upah harus lebih dari 0';
                return null;
              },
            ),
            const SizedBox(height: 24),

            _buildLabel('Bahan Mentah yang Digunakan'),
            const SizedBox(height: 4),
            Text(
              'Opsional — pilih bahan yang akan dipakai',
              style: GoogleFonts.inter(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),

            if (_selectedMaterialsList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Belum ada bahan mentah ditambahkan',
                    style: GoogleFonts.inter(color: Colors.grey.shade400),
                  ),
                ),
              )
            else
              ..._selectedMaterialsList.map((mat) {
                _materialQtyControllers.putIfAbsent(
                  mat.id,
                  () => TextEditingController(),
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mat.name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Stok tersisa: ${mat.selectedStock.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} ${mat.unit}',
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 75,
                        child: CustomTextField(
                          controller: _materialQtyControllers[mat.id]!,
                          label: '',
                          hint: '0',
                          suffixText: mat.unit,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          fillColor: Colors.white,
                          validator: (v) {
                            if (v != null && v.isNotEmpty) {
                              final doubleVal = double.tryParse(
                                v.replaceAll(',', '.'),
                              );
                              if (doubleVal == null || doubleVal <= 0) {
                                return 'Invalid';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedMaterialsList.removeWhere(
                              (m) => m.id == mat.id,
                            );
                            _materialQtyControllers.remove(mat.id);
                          });
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddMaterialModal(context, materials),
                icon: const Icon(Icons.add),
                label: Text(
                  'Tambah Bahan Mentah',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddMaterialModal(
    BuildContext context,
    List<RawMaterial> materials,
  ) {
    if (materials.isEmpty) {
      _showSnackBar('Gudang bahan mentah kosong', isError: true);
      return;
    }

    final unusedMaterials = materials
        .where((m) => !_selectedMaterialsList.any((u) => u.id == m.id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Pilih Bahan Mentah',
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
                            'Semua bahan sudah ditambahkan.',
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                'Stok tersisa: ${mat.selectedStock.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')} ${mat.unit}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedMaterialsList.add(mat);
                                  });
                                  Navigator.pop(ctx);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF004D4C),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Tambah',
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
  }

  // ── Helpers ──
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    SnackBarUtils.show(context, msg, isError: isError, showAboveBar: true);
  }

  // ── Navigation ──
  void _onNext() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      if (_spkType == 'RESTOCK') {
        if (_selectedProductGroup == null) {
          _showSnackBar('Pilih produk terlebih dahulu', isError: true);
          return;
        }
      }

      setState(() => _currentStep = 1);
      _autoDetectWage();
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final wageRaw = _wageController.text.replaceAll(RegExp(r'[^\d]'), '');
    final wage = double.tryParse(wageRaw) ?? 0;

    setState(() => _isLoading = true);

    try {
      final tailors = ref.read(tailorsStreamProvider).value ?? [];

      // Build variants/items based on type
      final variants = <SpkVariant>[];
      String productName;
      String productType;

      if (_spkType == 'CUSTOM') {
        // Custom: no variants, no target qty
        productName = _customProductNameController.text.trim();
        productType = _customProductTypeController.text.trim();
      } else {
        // Restock: auto-include ALL sizes with targetQuantity = 0
        final products = ref.read(productsStreamProvider).value ?? [];
        final grouped = <String, List<Product>>{};
        for (final p in products) {
          final key = '${p.name}_${p.schoolLevels.join('_')}_${p.type}';
          grouped.putIfAbsent(key, () => []).add(p);
        }
        final selectedProducts = grouped[_selectedProductGroup] ?? [];
        for (final product in selectedProducts) {
          variants.add(
            SpkVariant(
              productId: product.id,
              size: product.size,
              targetQuantity: 0,
            ),
          );
        }
        if (selectedProducts.isEmpty) {
          throw 'Produk tidak ditemukan';
        }
        productName = selectedProducts.first.name;
        productType = selectedProducts.first.type;
      }

      // Auto-assign ALL tailors
      final assignments = tailors
          .map((t) => TailorAssignment(userId: t.id, userName: t.name))
          .toList();

      // Build materials used
      final materialsUsed = <MaterialUsed>[];
      for (final mat in _selectedMaterialsList) {
        final qtyStr = _materialQtyControllers[mat.id]?.text ?? '';
        final qty = double.tryParse(qtyStr.replaceAll(',', '.')) ?? 0;
        if (qty > 0) {
          materialsUsed.add(
            MaterialUsed(
              materialId: mat.id,
              materialName: mat.name,
              quantity: qty,
              unit: mat.unit,
            ),
          );
        }
      }

      final order = ProductionOrder(
        id: '',
        title: _titleController.text.trim(),
        spkType: _spkType!,
        productName: productName,
        productType: productType,
        items: variants,
        targetQuantity: 0,
        status: 'PENDING',
        completedQuantity: 0,
        tailorAssignments: assignments,
        wagePerPiece: wage,
        reports: [],
        materialsUsed: materialsUsed,
        startDate: _startDate,
        estimatedCompletionDate: _estimatedEndDate,
        createdAt: DateTime.now(),
      );

      await ref.read(productionOrderRepositoryProvider).add(order);

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('SPK "${_titleController.text.trim()}" berhasil dibuat');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal menyimpan: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _autoDetectWage() {
    if (_hasAutoDetectedWage) return;

    final categories = ref.read(wageCategoriesStreamProvider).value ?? [];
    if (categories.isEmpty) return;

    String? productName;
    if (_spkType == 'CUSTOM') {
      productName = _customProductNameController.text;
    } else {
      final products = ref.read(productsStreamProvider).value ?? [];
      if (_selectedProductGroup != null) {
        for (var p in products) {
          final key = '${p.name}_${p.schoolLevels.join('_')}_${p.type}';
          if (key == _selectedProductGroup) {
            productName = p.name;
            break;
          }
        }
      }
    }

    if (productName != null && productName.isNotEmpty) {
      final nameLower = productName.toLowerCase();
      for (final cat in categories) {
        if (nameLower.contains(cat.name.toLowerCase())) {
          _selectedWageCategory = cat;
          _isManualWage = false;
          _wageController.text = formatCurrency(cat.amount);
          break;
        }
      }
    }
    _hasAutoDetectedWage = true;
    setState(() {});
  }

  // ── Product Picker Bottom Sheet ──
  void _showProductPicker(
    BuildContext context,
    Map<String, List<Product>> grouped,
    ColorScheme colors,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ProductPickerSheet(
          grouped: grouped,
          selectedKey: _selectedProductGroup,
          colors: colors,
          title: 'Pilih Produk',
          subtitle: 'Cari dan pilih produk untuk SPK ini',
          onSelected: (key) {
            setState(() => _selectedProductGroup = key);
            Navigator.pop(ctx);
          },
        );
      },
    );
  }
}
