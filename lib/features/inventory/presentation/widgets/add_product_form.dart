import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/snackbar_utils.dart';

import '../../../../core/services/image_upload_service.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/inventory_providers.dart';
import '../../domain/product.dart';

/// Custom TextInputFormatter for Rupiah formatting
class _RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final number = int.parse(digitsOnly);
    final formatted = _formatNumber(number);
    final prefixed = 'Rp $formatted';

    return TextEditingValue(
      text: prefixed,
      selection: TextSelection.collapsed(offset: prefixed.length),
    );
  }

  static String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

class AddProductForm extends ConsumerStatefulWidget {
  const AddProductForm({super.key});

  @override
  ConsumerState<AddProductForm> createState() => _AddProductFormState();
}

class _SizeEntry {
  String selectedSize;
  final TextEditingController priceController;
  final TextEditingController stockController;

  _SizeEntry()
    : selectedSize = 'S',
      priceController = TextEditingController(),
      stockController = TextEditingController();

  void dispose() {
    priceController.dispose();
    stockController.dispose();
  }

  double get priceValue {
    final raw = priceController.text.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(raw) ?? 0;
  }

  int get stockValue => int.tryParse(stockController.text) ?? 0;
}

class _AddProductFormState extends ConsumerState<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedType = 'Lengan Panjang';
  final List<String> _selectedLevels = [];
  final List<_SizeEntry> _sizeEntries = [_SizeEntry()];
  bool _isLoading = false;

  // Image state
  XFile? _selectedImage;

  static const List<String> _availableSizes = ['S', 'M', 'L', 'XL', 'XXL'];

  static const List<String> _types = [
    'Lengan Panjang',
    'Lengan Pendek',
    'Celana',
    'Rok',
    'Jas',
    'Lainnya',
  ];

  static const List<String> _levels = [
    'SD',
    'MIN',
    'SMP',
    'MTs',
    'SMA',
    'MA',
    'SMK',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    for (final entry in _sizeEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  List<String> _getAvailableSizes(int currentIndex) {
    final usedSizes = <String>{};
    for (int i = 0; i < _sizeEntries.length; i++) {
      if (i != currentIndex) usedSizes.add(_sizeEntries[i].selectedSize);
    }
    return _availableSizes.where((s) => !usedSizes.contains(s)).toList();
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
                  Text(
                    'Tambah Produk Baru',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Foto Produk ──
                  _buildLabel('Foto Produk'),
                  const SizedBox(height: 8),
                  _buildImagePicker(colors),
                  const SizedBox(height: 20),

                  // ── Nama Produk ──
                  CustomTextField(
                    controller: _nameController,
                    label: 'Nama Produk',
                    hint: 'Baju OSIS',
                    icon: Icons.checkroom_outlined,
                    showLabelOutside: true,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nama produk wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Jenjang Sekolah ──
                  _buildLabel('Jenjang Sekolah'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _levels.map((level) {
                      final isSelected = _selectedLevels.contains(level);
                      return FilterChip(
                        label: Text(
                          level,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isSelected
                                ? colors.primary
                                : Colors.grey.shade700,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedLevels.add(level);
                            } else {
                              _selectedLevels.remove(level);
                            }
                          });
                        },
                        selectedColor: colors.primary.withValues(alpha: 0.15),
                        checkmarkColor: colors.primary,
                        backgroundColor: const Color(0xFFF2F4F4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? colors.primary.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── Tipe Potongan ──
                  _buildLabel('Tipe Potongan'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: _types
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t, style: GoogleFonts.inter()),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedType = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Varian Ukuran & Harga ──
                  _buildLabel('Varian Ukuran & Harga'),
                  const SizedBox(height: 12),

                  ..._sizeEntries.asMap().entries.map((e) {
                    final idx = e.key;
                    final entry = e.value;
                    final availableSizes = _getAvailableSizes(idx);

                    if (!availableSizes.contains(entry.selectedSize) &&
                        availableSizes.isNotEmpty) {
                      entry.selectedSize = availableSizes.first;
                    }

                    return _buildVariantCard(
                      idx,
                      entry,
                      availableSizes,
                      colors,
                    );
                  }),

                  if (_sizeEntries.length < _availableSizes.length)
                    TextButton.icon(
                      onPressed: () {
                        final available = _getAvailableSizes(
                          _sizeEntries.length,
                        );
                        if (available.isNotEmpty) {
                          final entry = _SizeEntry();
                          entry.selectedSize = available.first;
                          setState(() => _sizeEntries.add(entry));
                        }
                      },
                      icon: Icon(
                        Icons.add_circle_outline,
                        size: 18,
                        color: colors.primary,
                      ),
                      label: Text(
                        'Tambah Ukuran',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Submit ──
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: colors.primary.withValues(
                          alpha: 0.5,
                        ),
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
                              'Simpan ${_sizeEntries.length} Varian',
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

  // ── Image Picker Widget ──
  Widget _buildImagePicker(ColorScheme colors) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          image: _selectedImage != null
              ? DecorationImage(
                  image: FileImage(File(_selectedImage!.path)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _selectedImage != null
            ? Stack(
                children: [
                  // Dark overlay for readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  // Change photo button
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 18,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ganti Foto',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Remove button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap untuk pilih foto produk',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dari galeri atau kamera',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Sumber Foto',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text('Galeri', style: GoogleFonts.inter()),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text('Kamera', style: GoogleFonts.inter()),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final XFile? file;
    if (source == ImageSource.gallery) {
      file = await ImageUploadService.pickFromGallery();
    } else {
      file = await ImageUploadService.pickFromCamera();
    }

    if (file != null) {
      setState(() => _selectedImage = file);
    }
  }

  // ── Variant Card ──
  Widget _buildVariantCard(
    int idx,
    _SizeEntry entry,
    List<String> availableSizes,
    ColorScheme colors,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Varian ${idx + 1}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
              if (_sizeEntries.length > 1)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _sizeEntries[idx].dispose();
                      _sizeEntries.removeAt(idx);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.red.shade400,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Size Dropdown
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ukuran',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: entry.selectedSize,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          items: availableSizes
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => entry.selectedSize = v!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Price
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Harga',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: entry.priceController,
                      label: '',
                      hint: 'Rp 0',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _RupiahInputFormatter(),
                      ],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Wajib diisi';
                        final raw = v.replaceAll(RegExp(r'[^\d]'), '');
                        if (raw.isEmpty || int.tryParse(raw) == 0) {
                          return 'Tidak valid';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Stock
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stok Awal',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: entry.stockController,
                      label: '',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Wajib diisi';
                        if (int.tryParse(v) == null) return 'Angka saja';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLevels.isEmpty) {
      SnackBarUtils.show(
        context,
        'Pilih minimal satu jenjang sekolah',
        isError: true,
        showAboveBar: true,
      );
      return;
    }

    // Check duplicate sizes
    final sizes = _sizeEntries.map((e) => e.selectedSize).toList();
    if (sizes.toSet().length != sizes.length) {
      SnackBarUtils.show(
        context,
        'Ukuran tidak boleh duplikat',
        isError: true,
        showAboveBar: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Periksa apakah nama produk dan jenjang sekolah sudah ada
      final existingProducts = await ref.read(productsStreamProvider.future);
      final newNameLower = _nameController.text.trim().toLowerCase();

      final duplicate = existingProducts.any((p) {
        final isSameName = p.name.toLowerCase() == newNameLower;
        final isSameType = p.type == _selectedType;
        final hasSameLevel = p.schoolLevels.any(
          (level) => _selectedLevels.contains(level),
        );
        return isSameName && isSameType && hasSameLevel;
      });

      if (duplicate) {
        if (mounted) {
          SnackBarUtils.show(
            context,
            'Produk tersebut sudah terdaftar',
            isError: true,
            showAboveBar: true,
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await ImageUploadService.uploadProductImage(
          _selectedImage!,
          _nameController.text.trim(),
        );
      }

      final products = _sizeEntries.map((entry) {
        return Product(
          id: '',
          name: _nameController.text.trim(),
          schoolLevels: List<String>.from(_selectedLevels),
          type: _selectedType,
          size: entry.selectedSize,
          price: entry.priceValue,
          currentStock: entry.stockValue,
          imageUrl: imageUrl,
          updatedAt: DateTime.now(),
        );
      }).toList();

      await ref.read(productRepositoryProvider).addBatch(products);

      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.show(
          context,
          '${products.length} varian "${_nameController.text.trim()}" berhasil ditambahkan',
          showAboveBar: true,
        );
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
