import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? suffixText;
  final IconData? icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool showLabelOutside;
  final bool readOnly;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final void Function(String)? onChanged;
  final TextStyle? style;
  final Color? fillColor;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.suffixText,
    this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.showLabelOutside = false,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.onChanged,
    this.style,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget field = TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textAlign: textAlign,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      style: style ?? GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        labelText: showLabelOutside ? null : label,
        labelStyle: showLabelOutside
            ? null
            : GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: Colors.grey.shade500)
            : null,
        suffixText: suffixText,
        suffixStyle: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
        filled: true,
        fillColor: fillColor ?? const Color(0xFFF2F4F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF004D4C)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );

    if (showLabelOutside) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF001F1F),
            ),
          ),
          const SizedBox(height: 8),
          field,
        ],
      );
    }

    return field;
  }
}
