import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UnpaidWageCard extends StatelessWidget {
  final String initials;
  final Color initialsBgColor;
  final String name;
  final String subtitle;
  final String status;
  final Color statusColor;
  final String amount;

  const UnpaidWageCard({
    super.key,
    required this.initials,
    required this.initialsBgColor,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: initialsBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              initials,
              style: GoogleFonts.manrope(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: const Color(0xFF003030),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status,
                style: GoogleFonts.inter(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: const Color(0xFF004D4C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
