import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/currency_utils.dart';

class PaymentMethodSelector extends StatefulWidget {
  final double grandTotal;
  final String selectedMethod;
  final double amountPaid;
  final ValueChanged<String> onMethodChanged;
  final ValueChanged<double> onAmountChanged;
  final bool hasCustom;

  const PaymentMethodSelector({
    super.key,
    required this.grandTotal,
    required this.selectedMethod,
    required this.amountPaid,
    required this.hasCustom,
    required this.onMethodChanged,
    required this.onAmountChanged,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  late TextEditingController _cashController;

  @override
  void initState() {
    super.initState();
    _cashController = TextEditingController(
      text: widget.amountPaid > 0
          ? formatCurrency(widget.amountPaid).replaceAll('Rp ', '').replaceAll('.', '')
          : '',
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    final change = widget.amountPaid - widget.grandTotal;

    return Column(
      children: [
        // Method Buttons
        Row(
          children: [
            Expanded(
              child: _buildMethodButton(
                label: 'TUNAI',
                icon: Icons.money,
                value: 'CASH',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMethodButton(
                label: 'TRANSFER',
                icon: Icons.account_balance,
                value: 'TRANSFER',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMethodButton(
                label: 'QRIS',
                icon: Icons.qr_code_2,
                value: 'QRIS',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Nominal input (for CASH or if custom order allows DP)
        if (widget.selectedMethod == 'CASH' || widget.hasCustom)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hasCustom ? 'NOMINAL BAYAR (DP / LUNAS)' : 'UANG TUNAI',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Rp',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF003D3D),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _cashController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            RupiahInputFormatter(),
                          ],
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF003D3D),
                            fontSize: 18,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: formatCurrency(
                                widget.grandTotal),
                            hintStyle: GoogleFonts.manrope(
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade300,
                              fontSize: 18,
                            ),
                          ),
                          onChanged: (value) {
                            final digits = value.replaceAll(
                                RegExp(r'[^\d]'), '');
                            final amount =
                                double.tryParse(digits) ?? 0;
                            widget.onAmountChanged(amount);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Quick amount buttons
                Row(
                  children: [
                    _quickAmountButton('Uang Pas', widget.grandTotal),
                    const SizedBox(width: 8),
                    _quickAmountButton(
                      _formatCurrency(
                          _roundUp(widget.grandTotal, 50000)),
                      _roundUp(widget.grandTotal, 50000),
                    ),
                    const SizedBox(width: 8),
                    _quickAmountButton(
                      _formatCurrency(
                          _roundUp(widget.grandTotal, 100000)),
                      _roundUp(widget.grandTotal, 100000),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Change / DP display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: change >= 0
                        ? Colors.grey.shade200
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        change >= 0 ? 'Kembalian' : 'Sisa Tagihan',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      Text(
                        widget.amountPaid > 0
                            ? _formatCurrency(change >= 0 ? change : -change)
                            : 'Rp 0',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          color: change >= 0
                              ? const Color(0xFF006766)
                              : Colors.orange.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.amountPaid > 0 && change < 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.hasCustom 
                        ? 'Sisa tagihan akan dilunasi saat pengambilan'
                        : 'Uang kurang ${_formatCurrency(-change)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: widget.hasCustom ? Colors.orange.shade800 : Colors.red.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          )
        else
          // Non-cash info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  widget.selectedMethod == 'TRANSFER'
                      ? Icons.account_balance
                      : Icons.qr_code_2,
                  color: const Color(0xFF003D3D),
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.selectedMethod == 'TRANSFER'
                            ? 'Pembayaran Transfer'
                            : 'Pembayaran QRIS',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF003D3D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: ${_formatCurrency(widget.grandTotal)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMethodButton({
    required String label,
    required IconData icon,
    required String value,
  }) {
    final isActive = widget.selectedMethod == value;
    return GestureDetector(
      onTap: () {
        widget.onMethodChanged(value);
        if (value != 'CASH' && !widget.hasCustom) {
          // Auto-set exact amount for non-cash if not custom
          widget.onAmountChanged(widget.grandTotal);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:
              isActive ? const Color(0xFF006766) : const Color(0xFFF2F4F4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.black87,
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? Colors.white : Colors.black87,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAmountButton(String label, double amount) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _cashController.text = formatCurrency(amount);
          widget.onAmountChanged(amount);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF003D3D),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _roundUp(double value, double step) {
    if (value <= 0) return step;
    return (value / step).ceil() * step;
  }
}
