import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/inventory_providers.dart';
import '../../domain/raw_material.dart';

class AddRawMaterialDialog extends ConsumerStatefulWidget {
  /// Pass an existing material to open in Edit mode.
  final RawMaterial? existingMaterial;

  const AddRawMaterialDialog({super.key, this.existingMaterial});

  @override
  ConsumerState<AddRawMaterialDialog> createState() =>
      _AddRawMaterialDialogState();
}

class _AddRawMaterialDialogState extends ConsumerState<AddRawMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();
  final _thresholdController = TextEditingController();
  String _selectedUnit = 'meter';
  bool _isLoading = false;

  File? _pickedImage;
  String? _existingImageUrl;

  final List<String> _units = ['meter', 'roll', 'pcs', 'kg', 'lembar'];

  bool get _isEditMode => widget.existingMaterial != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final m = widget.existingMaterial!;
      _nameController.text = m.name;
      _stockController.text = _formatStock(m.selectedStock);
      _thresholdController.text = _formatStock(m.lowStockThreshold);
      _selectedUnit = m.unit;
      _existingImageUrl = m.imageUrl;
    }
  }

  String _formatStock(double val) {
    if (val == val.truncateToDouble()) return val.toInt().toString();
    return val
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<String?> _uploadImage(String materialId) async {
    if (_pickedImage == null) return _existingImageUrl;

    final storageRef = FirebaseStorage.instance.ref().child(
      'raw_materials/$materialId.jpg',
    );

    await storageRef.putFile(_pickedImage!);
    return await storageRef.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isEditMode
                              ? 'Edit Bahan Mentah'
                              : 'Tambah Bahan Mentah',
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
                  const SizedBox(height: 20),

                  // ── Image Picker ──
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid,
                        ),
                        image: _pickedImage != null
                            ? DecorationImage(
                                image: FileImage(_pickedImage!),
                                fit: BoxFit.cover,
                              )
                            : (_existingImageUrl != null &&
                                  _existingImageUrl!.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(_existingImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child:
                          (_pickedImage == null &&
                              (_existingImageUrl == null ||
                                  _existingImageUrl!.isEmpty))
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 36,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap untuk pilih gambar',
                                  style: GoogleFonts.inter(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Name ──
                  CustomTextField(
                    controller: _nameController,
                    label: 'Nama Bahan',
                    hint: 'Kain Seragam SD Merah',
                    icon: Icons.label_outline,
                    showLabelOutside: true,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Unit Dropdown ──
                  Text(
                    'Satuan',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedUnit,
                        isExpanded: true,
                        items: _units
                            .map(
                              (u) => DropdownMenuItem(
                                value: u,
                                child: Text(u, style: GoogleFonts.inter()),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedUnit = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Stock & Threshold ──
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _stockController,
                          label: _isEditMode ? 'Stok Saat Ini' : 'Stok Awal',
                          hint: '0',
                          icon: Icons.inventory_2_outlined,
                          showLabelOutside: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          controller: _thresholdController,
                          label: 'Batas Minimum',
                          hint: '10',
                          icon: Icons.warning_amber_outlined,
                          showLabelOutside: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Submit Button ──
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                              _isEditMode ? 'Update' : 'Simpan',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(rawMaterialRepositoryProvider);
      final stock =
          double.tryParse(_stockController.text.replaceAll(',', '.')) ?? 0;
      final threshold =
          double.tryParse(_thresholdController.text.replaceAll(',', '.')) ?? 0;

      if (_isEditMode) {
        // ── UPDATE ──
        final id = widget.existingMaterial!.id;
        final imageUrl = await _uploadImage(id);

        final updated = widget.existingMaterial!.copyWith(
          name: _nameController.text.trim(),
          unit: _selectedUnit,
          selectedStock: stock,
          lowStockThreshold: threshold,
          imageUrl: imageUrl,
        );

        await repo.update(updated);

        if (mounted) {
          Navigator.of(context).pop();
          SnackBarUtils.show(
            context,
            'Bahan "${updated.name}" berhasil diperbarui',
            showAboveBar: true,
          );
        }
      } else {
        // ── CREATE ──
        // First save to Firestore to get auto-generated ID
        final tempMaterial = RawMaterial(
          id: '',
          name: _nameController.text.trim(),
          unit: _selectedUnit,
          selectedStock: stock,
          lowStockThreshold: threshold,
          updatedAt: DateTime.now(),
        );

        final docRef = await ref
            .read(rawMaterialRepositoryProvider)
            .addAndGetRef(tempMaterial);

        // Now upload image with the real document ID
        String? imageUrl;
        if (_pickedImage != null) {
          imageUrl = await _uploadImage(docRef.id);
          // Update the document with the image URL
          await docRef.update({'image_url': imageUrl});
        }

        if (mounted) {
          Navigator.of(context).pop();
          SnackBarUtils.show(
            context,
            'Bahan "${tempMaterial.name}" berhasil ditambahkan',
            showAboveBar: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.show(
          context,
          'Gagal menyimpan: $e',
          isError: true,
          showAboveBar: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
