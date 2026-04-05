import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmployeeListTile extends StatelessWidget {
  final String name;
  final String role;
  final String? avatarUrl;
  final String unpaidAmount;
  final VoidCallback onTap;

  const EmployeeListTile({
    super.key,
    required this.name,
    required this.role,
    this.avatarUrl,
    required this.unpaidAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? Icon(Icons.person, color: Colors.grey.shade400)
                  : null,
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
                      color: const Color(0xFF004D4C),
                    ),
                  ),
                  Text(
                    role,
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              unpaidAmount,
              style: GoogleFonts.manrope(
                color: unpaidAmount == 'Rp 0' ? Colors.grey.shade500 : const Color(0xFF004D4C),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
