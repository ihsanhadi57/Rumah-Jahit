import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/data/auth_repository.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key, required this.navigationShell});

  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    // Get user role safely, handle loading/error states by defaulting to false
    final appUser = ref.watch(currentAppUserProvider).value;
    final isAdmin = appUser?.role.toLowerCase().trim() == 'admin';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 768;

        if (isTablet) {
          // Navigation Rail untuk Tablet
          return Scaffold(
            backgroundColor: colors.surface,
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: colors.surface,
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (int index) => _onTap(context, index),
                  labelType: NavigationRailLabelType.all,
                  selectedLabelTextStyle: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                  unselectedLabelTextStyle: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                  selectedIconTheme: const IconThemeData(color: Colors.white),
                  unselectedIconTheme: IconThemeData(
                    color: Colors.grey.shade600,
                  ),
                  useIndicator: true,
                  indicatorColor: colors.primary,
                  destinations: [
                    _buildNavRailItem(
                      Icons.dashboard_outlined,
                      Icons.dashboard,
                      'DASHBOARD',
                    ),
                    _buildNavRailItem(
                      Icons.point_of_sale_outlined,
                      Icons.point_of_sale,
                      'KASIR',
                    ),
                    if (isAdmin)
                      _buildNavRailItem(
                        Icons.inventory_2_outlined,
                        Icons.inventory_2,
                        'GUDANG',
                      ),
                    if (isAdmin)
                      _buildNavRailItem(
                        Icons.people_outline,
                        Icons.people,
                        'KARYAWAN',
                      ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        // Bottom Navigation Bar untuk Mobile
        return Scaffold(
          extendBody:
              true, // Memastikan body (ListView) bisa scroll ke balik Floating Bottom Nav
          body: navigationShell,
          bottomNavigationBar: SafeArea(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                // Ambient shadow recommendation dari DESIGN.md
                boxShadow: [
                  BoxShadow(
                    color: colors.onSurface.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                borderRadius: BorderRadius.circular(40),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.9), // Glassmorphism white
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: BottomNavigationBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      type: BottomNavigationBarType.fixed,
                      showSelectedLabels: true,
                      showUnselectedLabels: true,
                      selectedItemColor: colors.primary,
                      unselectedItemColor: Colors.grey.shade500,
                      selectedLabelStyle: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      currentIndex: navigationShell.currentIndex,
                      onTap: (int index) => _onTap(context, index),
                      items: [
                        _buildNavItem(
                          Icons.dashboard_outlined,
                          Icons.dashboard,
                          'DASHBOARD',
                          0,
                          colors,
                        ),
                        _buildNavItem(
                          Icons.point_of_sale_outlined,
                          Icons.point_of_sale,
                          'KASIR',
                          1,
                          colors,
                        ),
                        if (isAdmin)
                          _buildNavItem(
                            Icons.inventory_2_outlined,
                            Icons.inventory_2,
                            'GUDANG',
                            2,
                            colors,
                          ),
                        if (isAdmin)
                          _buildNavItem(
                            Icons.people_outline,
                            Icons.people,
                            'KARYAWAN',
                            3,
                            colors,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  NavigationRailDestination _buildNavRailItem(
    IconData outlineIcon,
    IconData solidIcon,
    String label,
  ) {
    return NavigationRailDestination(
      icon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Icon(outlineIcon, size: 28),
      ),
      selectedIcon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Icon(solidIcon, size: 28),
      ),
      label: Text(label),
      padding: const EdgeInsets.symmetric(vertical: 8),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData outlineIcon,
    IconData solidIcon,
    String label,
    int index,
    ColorScheme colors,
  ) {
    bool isSelected = navigationShell.currentIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          isSelected ? solidIcon : outlineIcon,
          color: isSelected ? Colors.white : Colors.grey.shade600,
          size: 24,
        ),
      ),
      label: label,
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
