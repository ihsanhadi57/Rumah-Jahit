import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/biometric_service.dart';
import '../data/auth_repository.dart';

class ActivationPendingScreen extends ConsumerWidget {
  const ActivationPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    // Listen to real-time user data changes
    final appUserAsync = ref.watch(currentAppUserProvider);
    appUserAsync.whenData((appUser) {
      if (appUser != null && appUser.isApproved) {
        // Auto-redirect to dashboard when admin approves
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/dashboard');
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 60 : 32,
            vertical: 40,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    size: 48,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Menunggu Aktivasi',
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF001F1F),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'Akun Anda telah berhasil didaftarkan!\nNamun, akun perlu diaktivasi oleh admin terlebih dahulu sebelum Anda dapat mengakses aplikasi.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Contact card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.mail_outline, size: 32, color: colors.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Hubungi Admin',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF001F1F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Untuk mempercepat proses aktivasi,\nhubungi admin melalui email:',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(
                          'ihsanhadi57@gmail.com',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Status indicator
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Status: Menunggu persetujuan admin. Halaman ini akan otomatis berpindah setelah akun diaktivasi.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Log out button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await BiometricService.clearCredentials();
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) context.go('/auth');
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: Text(
                      'Keluar & Ganti Akun',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
