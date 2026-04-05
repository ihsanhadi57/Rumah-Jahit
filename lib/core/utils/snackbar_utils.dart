import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SnackBarUtils {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool showAboveBar = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.fixed,
        backgroundColor: isError
            ? Colors.red.shade800
            : const Color(0xFF004D4C),
        duration: duration,
        elevation: 0,
      ),
    );
  }
}
