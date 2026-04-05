import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum StatusType {
  pending,
  inProgress,
  completed,
  successful,
  failed,
  paid,
  unpaid,
  adjustment,
  warning,
}

class AppStatusBadge extends StatelessWidget {
  final String status;
  final StatusType? type;

  const AppStatusBadge({
    super.key,
    required this.status,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    final statusLower = status.toLowerCase();
    
    // Auto-detect type if not provided
    final effectiveType = type ?? _detectType(statusLower);
    
    final colors = _getStatusColors(effectiveType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.foreground.withValues(alpha: 0.1)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          color: colors.foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  StatusType _detectType(String status) {
    if (status.contains('pending')) return StatusType.pending;
    if (status.contains('progress')) return StatusType.inProgress;
    if (status.contains('complete')) return StatusType.completed;
    if (status.contains('success') || status.contains('berhasil')) return StatusType.successful;
    if (status.contains('fail') || status.contains('gagal') || status.contains('habis') || status.contains('out of stock')) return StatusType.failed;
    if (status.contains('paid') || status.contains('terbayar')) return StatusType.paid;
    if (status.contains('unpaid') || status.contains('belum bayar')) return StatusType.unpaid;
    if (status.contains('adjustment')) return StatusType.adjustment;
    if (status.contains('low') || status.contains('rendah') || status.contains('warning')) return StatusType.warning;
    return StatusType.pending;
  }

  _StatusColor _getStatusColors(StatusType type) {
    switch (type) {
      case StatusType.pending:
        return _StatusColor(
          background: const Color(0xFFE3F2FD),
          foreground: const Color(0xFF1976D2),
        );
      case StatusType.inProgress:
        return _StatusColor(
          background: const Color(0xFFFFF3E0),
          foreground: const Color(0xFFE65100),
        );
      case StatusType.completed:
      case StatusType.successful:
      case StatusType.paid:
        return _StatusColor(
          background: const Color(0xFFE0F2F1),
          foreground: const Color(0xFF004D40),
        );
      case StatusType.failed:
      case StatusType.unpaid:
        return _StatusColor(
          background: const Color(0xFFFFEBEE),
          foreground: const Color(0xFFC62828),
        );
      case StatusType.adjustment:
        return _StatusColor(
          background: const Color(0xFFF3E5F5),
          foreground: const Color(0xFF7B1FA2),
        );
      case StatusType.warning:
        return _StatusColor(
          background: const Color(0xFFFFF8E1),
          foreground: const Color(0xFFFFA000),
        );
    }
  }
}

class _StatusColor {
  final Color background;
  final Color foreground;

  _StatusColor({required this.background, required this.foreground});
}
