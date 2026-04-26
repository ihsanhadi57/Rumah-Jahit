import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/inventory_providers.dart';
import '../../domain/raw_material.dart';
import 'bahan_mentah_card.dart';

class BahanMentahTabView extends ConsumerWidget {
  const BahanMentahTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(rawMaterialsStreamProvider);

    return materialsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Error: $error',
          style: GoogleFonts.inter(color: Colors.red),
        ),
      ),
      data: (materials) => _buildContent(context, ref, materials),
    );
  }

  String _formatStock(double val) {
    return val == val.truncateToDouble()
        ? val.toInt().toString()
        : val.toStringAsFixed(2)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<RawMaterial> materials,
  ) {
    final isTablet = MediaQuery.of(context).size.width > 768;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
      children: [
        // Search & Category
        if (isTablet)
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildSearchBar(),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildCategorySelector(),
              ),
            ],
          )
        else
          Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildCategorySelector(),
            ],
          ),
        const SizedBox(height: 24),

        // Cards from Firestore
        if (materials.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada bahan mentah',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap tombol + untuk menambahkan',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (isTablet)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 180,
            ),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final material = materials[index];
              return _buildCard(context, material);
            },
          )
        else
          ...materials.map((material) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildCard(context, material),
              )),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      height: 48,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari bahan...',
          prefixIcon: const Icon(Icons.search, size: 20),
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

  Widget _buildCategorySelector() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.filter_list,
            size: 18,
            color: Colors.black87,
          ),
          const SizedBox(width: 8),
          Text(
            'Category',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, RawMaterial material) {
    return BahanMentahCard(
      category: material.unit.toUpperCase(),
      title: material.name,
      subtitle: 'Threshold: ${_formatStock(material.lowStockThreshold)} ${material.unit}',
      stockLevel: _formatStock(material.selectedStock),
      unit: material.unit,
      status: material.stockStatus,
      imageUrl: material.imageUrl,
      onTap: () {
        context.push(
          '/inventory/raw-material-detail',
          extra: material.id,
        );
      },
    );
  }

}
