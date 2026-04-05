import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:rumah_jahit/core/utils/currency_utils.dart';
import 'package:rumah_jahit/core/utils/snackbar_utils.dart';
import 'package:rumah_jahit/core/widgets/custom_text_field.dart';
import 'package:rumah_jahit/features/settings/data/settings_providers.dart';
import 'package:rumah_jahit/features/settings/domain/wage_category.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final categoriesAsync = ref.watch(wageCategoriesStreamProvider);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pengaturan Upah',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: Colors.grey.shade400),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Atur nominal upah tetap yang akan otomatis terpilih saat membuat SPK',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _showFormDialog(context, null),
                icon: const Icon(Icons.add),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: const Text('Tambah Kategori Upah'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: categoriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (categories) {
                    if (categories.isEmpty) {
                      return Center(
                        child: Text(
                          'Belum ada pengaturan upah',
                          style: GoogleFonts.inter(color: Colors.grey.shade500),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: categories.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                          title: Text(
                            cat.name,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            formatCurrency(cat.amount),
                            style: GoogleFonts.inter(color: Colors.green.shade700, fontWeight: FontWeight.w700),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                onPressed: () => _showFormDialog(context, cat),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteCategory(cat),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFormDialog(BuildContext context, WageCategory? existing) {
    if (existing != null) {
      _nameController.text = existing.name;
      _amountController.text = formatCurrency(existing.amount);
    } else {
      _nameController.clear();
      _amountController.clear();
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  existing == null ? 'Tambah Kategori' : 'Edit Kategori',
                  style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _nameController,
                  label: 'Nama Kategori',
                  hint: 'Baju / Celana / Rok',
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _amountController,
                  label: 'Nominal Upah',
                  hint: 'Rp 0',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    RupiahInputFormatter(),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                     final numOnly = v.replaceAll(RegExp(r'[^\d]'), '');
                    final amount = double.tryParse(numOnly) ?? 0;
                    if (amount <= 0) return 'Harus lebih dari 0';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final numOnly = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
                          final amount = double.parse(numOnly);
                          final cat = WageCategory(
                            id: existing?.id ?? '',
                            name: _nameController.text.trim(),
                            amount: amount,
                          );
                          await ref.read(settingsRepositoryProvider).saveWageCategory(cat);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!context.mounted) return;
                          SnackBarUtils.show(context, 'Berhasil disimpan', showAboveBar: true);
                        }
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCategory(WageCategory cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Anda yakin ingin menghapus kategori "${cat.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(settingsRepositoryProvider).deleteWageCategory(cat.id);
      if (!mounted) return;
      SnackBarUtils.show(context, 'Berhasil dihapus', showAboveBar: true);
    }
  }
}
