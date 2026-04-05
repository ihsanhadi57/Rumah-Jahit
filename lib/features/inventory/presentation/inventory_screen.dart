import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/spk_tab_view.dart';
import 'widgets/bahan_mentah_tab_view.dart';
import 'widgets/barang_jadi_tab_view.dart';
import 'widgets/add_raw_material_form.dart';
import 'widgets/add_product_form.dart';
import 'widgets/add_spk_form.dart';
import 'package:rumah_jahit/features/settings/presentation/settings_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _selectedTabIndex = 2;

  final List<String> _tabs = [
    'Bahan Mentah',
    'Barang Jadi',
    'SPK (Work Order)',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        scrolledUnderElevation: 0,
        title: Text(
          'Rumah Jahit',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: colors.primary,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const SettingsDialog(),
              );
            },
            icon: Icon(Icons.settings, color: colors.primary),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedTabIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary
                          : const Color(0xFFF2F4F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _tabs[index],
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: _selectedTabIndex == 0
                ? const BahanMentahTabView()
                : _selectedTabIndex == 1
                ? const BarangJadiTabView()
                : const SpkTabView(),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 110.0),
        child: FloatingActionButton(
          onPressed: () => _onFabPressed(context),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  void _onFabPressed(BuildContext context) {
    switch (_selectedTabIndex) {
      case 0:
        showDialog(
          context: context,
          builder: (context) => const AddRawMaterialDialog(),
        );
        break;
      case 1:
        showDialog(
          context: context,
          builder: (context) => const AddProductForm(),
        );
        break;
      case 2:
        showDialog(context: context, builder: (context) => const AddSpkForm());
        break;
    }
  }
}
