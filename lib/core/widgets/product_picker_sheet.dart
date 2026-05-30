import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/inventory/domain/product.dart';

class ProductPickerSheet extends StatefulWidget {
  final Map<String, List<Product>> grouped;
  final String? selectedKey;
  final ColorScheme colors;
  final ValueChanged<String> onSelected;
  final String searchHint;
  final String title;
  final String subtitle;

  const ProductPickerSheet({
    super.key,
    required this.grouped,
    required this.selectedKey,
    required this.colors,
    required this.onSelected,
    this.searchHint = 'Cari produk...',
    this.title = 'Pilih Produk',
    this.subtitle = 'Cari dan pilih produk',
  });

  @override
  State<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<ProductPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedLevel;
  String? _selectedType;

  final List<String> _schoolLevels = ['SD', 'MIN', 'SMP', 'MTs', 'SMA', 'MA', 'SMK'];
  final List<String> _productTypes = [
    'Lengan Panjang',
    'Lengan Pendek',
    'Celana',
    'Rok',
    'Jas',
    'Perlengkapan Sekolah',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    // Filter and group entries locally
    final filteredEntries = <MapEntry<String, List<Product>>>[];

    for (final entry in widget.grouped.entries) {
      final first = entry.value.first;
      final displayLabel =
          '${first.name} ${first.schoolLevels.join('/')} - ${first.type}';

      // 1. Search Query Filter
      if (_query.isNotEmpty &&
          !displayLabel.toLowerCase().contains(_query.toLowerCase())) {
        continue;
      }

      // 2. School Level Filter
      if (_selectedLevel != null &&
          !first.schoolLevels.contains(_selectedLevel)) {
        continue;
      }

      // 3. Product Type Filter
      if (_selectedType != null && first.type != _selectedType) {
        continue;
      }

      filteredEntries.add(entry);
    }

    // Build active filters list for chip UI
    final activeFiltersList = ['Semua', ..._schoolLevels, ..._productTypes];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.title,
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 20, color: Colors.grey.shade400),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onChanged: (val) => setState(() => _query = val),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Filters Row
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: activeFiltersList.length,
              itemBuilder: (context, index) {
                final filter = activeFiltersList[index];
                final isSelected = filter == _selectedLevel ||
                    filter == _selectedType ||
                    (filter == 'Semua' && _selectedLevel == null && _selectedType == null);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (filter == 'Semua') {
                        _selectedLevel = null;
                        _selectedType = null;
                      } else if (_schoolLevels.contains(filter)) {
                        if (_selectedLevel == filter) {
                          _selectedLevel = null;
                        } else {
                          _selectedLevel = filter;
                        }
                      } else if (_productTypes.contains(filter)) {
                        if (_selectedType == filter) {
                          _selectedType = null;
                        } else {
                          _selectedType = filter;
                        }
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primary : const Color(0xFFF2F4F4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          filter,
                          style: GoogleFonts.inter(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        if (isSelected && filter != 'Semua') ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.close, size: 12, color: Colors.white),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Product List
          Expanded(
            child: filteredEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tidak ada produk ditemukan',
                          style: GoogleFonts.inter(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filteredEntries.length,
                    itemBuilder: (ctx, index) {
                      final entry = filteredEntries[index];
                      final first = entry.value.first;
                      final isSelected = entry.key == widget.selectedKey;
                      
                      final totalStock = entry.value.fold<int>(0, (sum, p) => sum + p.currentStock);
                      
                      const canonicalSizes = ['S', 'M', 'L', 'XL', 'XXL'];
                      final sortedVariants = List<Product>.from(entry.value)
                        ..sort((a, b) {
                          final ai = canonicalSizes.indexOf(a.size.toUpperCase());
                          final bi = canonicalSizes.indexOf(b.size.toUpperCase());
                          final aIdx = ai == -1 ? canonicalSizes.length : ai;
                          final bIdx = bi == -1 ? canonicalSizes.length : bi;
                          return aIdx.compareTo(bIdx);
                        });

                      return GestureDetector(
                        onTap: () => widget.onSelected(entry.key),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? colors.primary : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image
                                  Stack(
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: const Color(0xFFF2F4F4),
                                          image: first.imageUrl != null && first.imageUrl!.isNotEmpty
                                              ? DecorationImage(
                                                  image: NetworkImage(first.imageUrl!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: first.imageUrl == null || first.imageUrl!.isEmpty
                                            ? Icon(Icons.checkroom_outlined,
                                                size: 28, color: Colors.grey.shade400)
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.95),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            first.schoolLevels.join('/').toUpperCase(),
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF003D3D),
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  // Product Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${first.name} - ${first.type}',
                                                    style: GoogleFonts.manrope(
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 15,
                                                      color: const Color(0xFF001F1F),
                                                      height: 1.2,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    first.formattedPrice,
                                                    style: GoogleFonts.inter(
                                                      color: Colors.grey.shade500,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: colors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Total Stok: $totalStock pcs',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF004D4C),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Size Pills
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: sortedVariants.map((p) {
                                    return [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                p.size,
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${p.currentStock}',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFF003D3D),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ];
                                  }).expand((element) => element).toList()..removeLast(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
