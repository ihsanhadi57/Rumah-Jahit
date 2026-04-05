import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BahanMentahCard extends StatelessWidget {
  final String category;
  final String title;
  final String subtitle;
  final String stockLevel;
  final String unit;
  final String status;
  final String? imageUrl;
  final VoidCallback? onTap;

  const BahanMentahCard({
    super.key,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.stockLevel,
    required this.unit,
    required this.status,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLow = status.toUpperCase() == 'LOW';
    final isOut = status.toUpperCase() == 'HABIS';
    final Color statusColor;
    final IconData statusIcon;

    if (isOut) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else if (isLow) {
      statusColor = Colors.orange.shade700;
      statusIcon = Icons.error;
    } else {
      statusColor = const Color(0xFF00897B);
      statusIcon = Icons.check_circle;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image or placeholder
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF2F4F4),
                    image: (imageUrl != null && imageUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (imageUrl == null || imageUrl!.isEmpty)
                      ? Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 28,
                            color: Colors.grey.shade400,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA4F0E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              category.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: const Color(0xFF004D4C),
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(statusIcon, color: statusColor, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                status.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: const Color(0xFF001F1F),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STOCK LEVEL',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          stockLevel,
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF003D3D),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF003D3D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF004D4C).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFF004D4C),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
