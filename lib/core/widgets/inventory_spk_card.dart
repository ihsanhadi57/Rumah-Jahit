import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InventorySpkCard extends StatelessWidget {
  final String id;
  final String date;
  final String title;
  final String status;
  final Color statusColor;
  final Color statusTextColor;
  final bool isPriority;
  final double progress;
  final Widget bottomLeftWidget;
  final Color progressBarColor;

  const InventorySpkCard({
    super.key,
    required this.id,
    required this.date,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.statusTextColor,
    this.isPriority = false,
    required this.progress,
    required this.bottomLeftWidget,
    required this.progressBarColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Red indicator line for priority
            if (isPriority)
              Container(
                width: 4,
                color: Colors.red.shade700,
              ),
            
            // Main card content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: SPK ID/Priority • Date | Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (isPriority) ...[
                              Text(
                                'PRIORITAS TINGGI',
                                style: GoogleFonts.inter(
                                  color: Colors.red.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '  •  ',
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade400,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                            Text(
                              date,
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (isPriority)
                              Text(
                                '  •  $date',
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade400,
                                  fontSize: 10,
                                ),
                              ), // Sembunyikan date jika prioritas agar tidak terlalu panjang, atau tampilkan kecil
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.inter(
                              color: statusTextColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: const Color(0xFF003030), // Darker text
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Footer Row: Bottom Left Widget | Progress Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 1,
                          child: bottomLeftWidget,
                        ),
                        // Wrap the right-hand part in another row/column to control size
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Progress: ${(progress * 100).toInt()}%',
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 50,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(progressBarColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
