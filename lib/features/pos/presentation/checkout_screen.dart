import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_utils.dart';
import 'package:rumah_jahit/features/pos/data/pos_providers.dart';
import 'package:rumah_jahit/features/pos/domain/transaction_model.dart';

import 'widgets/order_item_card.dart';
import 'widgets/payment_method_selector.dart';
import 'package:rumah_jahit/core/widgets/custom_text_field.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _selectedPaymentMethod = 'CASH';
  double _amountPaid = 0;
  bool _isProcessing = false;
  bool _hasLogo = false;
  final _logoPriceController = TextEditingController();

  // Customer info controllers (for custom orders)
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  DateTime? _pickupDate;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _logoPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final hasCustomItems = cart.customItems.isNotEmpty;
    final isTablet = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFA),
        scrolledUnderElevation: 0,
        title: Text(
          'Checkout',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF003D3D),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF003D3D)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFF003D3D)),
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Keranjang kosong',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _showAddCustomItemDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Item Kustom'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF004D4C),
                      side: const BorderSide(color: Color(0xFF004D4C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : _buildResponsiveLayout(cart, hasCustomItems, isTablet),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: (cart.isEmpty || isTablet)
          ? null
          : Container(
              color: const Color(0xFFF9FAFA),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: _buildCheckoutButton(),
            ),
    );
  }

  Widget _buildResponsiveLayout(
      CartState cart, bool hasCustomItems, bool isTablet) {
    if (isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: _buildLeftColumn(cart, hasCustomItems),
            ),
          ),
          Container(
            width: 1,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(vertical: 24),
          ),
          Expanded(
            flex: 4,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ..._buildRightColumn(cart, hasCustomItems),
                const SizedBox(height: 32),
                _buildCheckoutButton(),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ..._buildLeftColumn(cart, hasCustomItems),
        const SizedBox(height: 32),
        ..._buildRightColumn(cart, hasCustomItems),
        const SizedBox(height: 100),
      ],
    );
  }

  List<Widget> _buildLeftColumn(CartState cart, bool hasCustomItems) {
    return [
      // Order Details Section
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Order Details',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF001F1F),
            ),
          ),
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
              '${cart.totalItems} ITEMS',
              style: GoogleFonts.inter(
                color: const Color(0xFF004D4C),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Product-based cart items
      ...cart.items.map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key(item.product.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              ref.read(cartProvider.notifier).removeItem(item.product.id);
            },
            child: OrderItemCard(
              icon: Icons.checkroom_outlined,
              title: '${item.product.name} (${item.product.size})',
              subtitle: '${item.product.formattedPrice} / pcs',
              price: formatCurrency(item.totalPrice),
              quantity: item.quantity,
              onIncrement: () {
                ref
                    .read(cartProvider.notifier)
                    .updateQuantity(item.product.id, item.quantity + 1);
              },
              onDecrement: () {
                ref
                    .read(cartProvider.notifier)
                    .updateQuantity(item.product.id, item.quantity - 1);
              },
            ),
          ),
        ),
      ),

      // Custom cart items
      ...cart.customItems.map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key(item.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              ref.read(cartProvider.notifier).removeCustomItem(item.id);
            },
            child: OrderItemCard(
              icon: Icons.edit_note_outlined,
              title: item.name,
              subtitle: item.description.isNotEmpty
                  ? '${item.formattedPrice} / pcs • ${item.description}'
                  : '${item.formattedPrice} / pcs',
              price: formatCurrency(item.totalPrice),
              quantity: item.quantity,
              isSpecial: true,
              onIncrement: () {
                ref
                    .read(cartProvider.notifier)
                    .updateCustomQuantity(item.id, item.quantity + 1);
              },
              onDecrement: () {
                ref
                    .read(cartProvider.notifier)
                    .updateCustomQuantity(item.id, item.quantity - 1);
              },
            ),
          ),
        ),
      ),

      // Add Custom Item Button
      const SizedBox(height: 4),
      GestureDetector(
        onTap: () => _showAddCustomItemDialog(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF004D4C),
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFF004D4C).withValues(alpha: 0.04),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                size: 18,
                color: Color(0xFF004D4C),
              ),
              const SizedBox(width: 8),
              Text(
                'Tambah Item Kustom',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: const Color(0xFF004D4C),
                ),
              ),
            ],
          ),
        ),
      ),

      // ── Customer Info Section (only when custom items exist) ──
      if (hasCustomItems) ...[
        const SizedBox(height: 32),
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person_outline,
                color: Colors.amber.shade800,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Info Pelanggan',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF001F1F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Wajib diisi untuk pesanan personal',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _customerNameController,
          label: 'Nama Pelanggan',
          hint: 'Budi',
          icon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _customerPhoneController,
          label: 'No. WhatsApp',
          hint: '08123456789',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 14),
        // Pickup Date Picker
        GestureDetector(
          onTap: () => _selectPickupDate(),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal Pengambilan',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _pickupDate != null
                            ? DateFormat('dd MMMM yyyy').format(_pickupDate!)
                            : 'Pilih tanggal',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _pickupDate != null
                              ? const Color(0xFF001F1F)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    ];
  }

  double get _logoPrice {
    if (!_hasLogo) return 0;
    final text = _logoPriceController.text.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(text) ?? 0;
  }

  List<Widget> _buildRightColumn(CartState cart, bool hasCustomItems) {
    return [
      // Logo Section
      _buildLogoSection(),
      const SizedBox(height: 32),
      // Payment Method Section
      Text(
        'Payment Method',
        style: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF001F1F),
        ),
      ),
      const SizedBox(height: 16),
      PaymentMethodSelector(
        grandTotal: cart.grandTotal + _logoPrice,
        selectedMethod: _selectedPaymentMethod,
        amountPaid: _amountPaid,
        hasCustom: hasCustomItems,
        onMethodChanged: (method) {
          setState(() => _selectedPaymentMethod = method);
        },
        onAmountChanged: (amount) {
          setState(() => _amountPaid = amount);
        },
      ),
      const SizedBox(height: 32),

      // Order Summary
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _summaryRow('Subtotal', formatCurrency(cart.subtotal)),
            const SizedBox(height: 8),
            if (cart.discount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Potongan Harga',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showDiscountDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.orange.shade200,
                            ),
                          ),
                          child: Text(
                            'Ubah Diskon',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '- ${formatCurrency(cart.discount)}',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Diskon',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showDiscountDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF004D4C).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add_circle_outline,
                            size: 14,
                            color: Color(0xFF004D4C),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tambah Diskon',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF004D4C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            if (_logoPrice > 0) ...[
              _summaryRow('Biaya Lambang', formatCurrency(_logoPrice)),
              const SizedBox(height: 8),
            ],
            const Divider(height: 24),
            _summaryRow(
              'Grand Total',
              formatCurrency(cart.grandTotal + _logoPrice),
              isBold: true,
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildCheckoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : () => _processPayment(),
        icon: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.receipt_long, color: Colors.white),
        label: Text(
          _isProcessing ? 'Memproses...' : 'Bayar Sekarang',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF004D4C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Future<void> _selectPickupDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF003D3D),
              onPrimary: Colors.white,
              onSurface: Color(0xFF003D3D),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _pickupDate = picked);
    }
  }

  // ── Add Custom Item Dialog ──
  void _showAddCustomItemDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.edit_note_outlined,
                color: Colors.amber.shade800,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Item Kustom',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: const Color(0xFF003D3D),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tambahkan item yang tidak ada di stok gudang',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: nameController,
                  label: 'Nama Item*',
                  hint: 'Baju Pramuka SMA',
                  icon: Icons.label_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: descController,
                  label: 'Deskripsi',
                  hint: 'Ukuran Jumbo Panjang 60',
                  icon: Icons.description_outlined,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: priceController,
                  label: 'Harga per pcs*',
                  hint: '0',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    RupiahInputFormatter(),
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    final digits = v.replaceAll(RegExp(r'[^\d]'), '');
                    if (int.tryParse(digits) == null ||
                        int.parse(digits) <= 0) {
                      return 'Harga harus lebih dari 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: qtyController,
                  label: 'Kuantitas *',
                  hint: '1',
                  icon: Icons.tag,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (int.tryParse(v) == null || int.parse(v) <= 0) {
                      return 'Min. 1';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;

              final priceDigits = priceController.text.replaceAll(
                RegExp(r'[^\d]'),
                '',
              );
              final item = CustomCartItem(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text.trim(),
                description: descController.text.trim(),
                price: double.parse(priceDigits),
                quantity: int.parse(qtyController.text),
              );

              ref.read(cartProvider.notifier).addCustomItem(item);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D4C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Tambahkan',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.school, color: Colors.blue.shade700, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Lambang Baju',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF001F1F),
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: _hasLogo,
                activeTrackColor: const Color(0xFF004D4C),
                onChanged: (val) => setState(() => _hasLogo = val),
              ),
            ],
          ),
          if (_hasLogo) ...[
            const SizedBox(height: 16),
            CustomTextField(
              controller: _logoPriceController,
              label: 'Harga Lambang (Opsional)',
              hint: '0',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                RupiahInputFormatter(),
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              '* Kosongkan jika sudah termasuk harga baju',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: isBold ? const Color(0xFF001F1F) : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF001F1F),
          ),
        ),
      ],
    );
  }

  Future<void> _processPayment() async {
    final cart = ref.read(cartProvider);
    final hasCustom = cart.customItems.isNotEmpty;

    // Validate customer info if custom items exist
    if (hasCustom) {
      if (_customerNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nama pelanggan wajib diisi untuk pesanan personal!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_customerPhoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No. WhatsApp wajib diisi untuk pesanan personal!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_pickupDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tanggal pengambilan wajib diisi!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final finalGrandTotal = cart.grandTotal + _logoPrice;
    final finalSubtotal = cart.subtotal + _logoPrice;

    if (!hasCustom && _selectedPaymentMethod == 'CASH' && _amountPaid < finalGrandTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uang tunai tidak cukup!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final transactionRepo = ref.read(transactionRepositoryProvider);

      final transaction = TransactionModel(
        id: '',
        cashierId: '',
        subtotal: finalSubtotal,
        discount: cart.discount,
        grandTotal: finalGrandTotal,
        paymentMethod: _selectedPaymentMethod,
        amountPaid: (_selectedPaymentMethod == 'CASH' || hasCustom)
            ? _amountPaid
            : finalGrandTotal,
        status: hasCustom ? 'PENDING' : 'SUCCESS',
        createdAt: DateTime.now(),
        customerName: hasCustom ? _customerNameController.text.trim() : null,
        customerPhone: hasCustom ? _customerPhoneController.text.trim() : null,
        pickupDate: hasCustom ? _pickupDate : null,
        hasCustomItems: hasCustom,
      );

      // Combine product-based and custom items into TransactionItems
      final items = <TransactionItem>[
        ...cart.items.map(
          (item) => TransactionItem(
            productId: item.product.id,
            productName: item.product.name,
            size: item.product.size,
            quantity: item.quantity,
            unitPrice: item.product.price,
            totalPrice: item.totalPrice,
            isCustom: false,
          ),
        ),
        ...cart.customItems.map(
          (item) => TransactionItem(
            productId: 'custom_${item.id}',
            productName: item.name,
            size: item.description,
            quantity: item.quantity,
            unitPrice: item.price,
            totalPrice: item.totalPrice,
            isCustom: true,
            productType: item.productType,
          ),
        ),
        if (_hasLogo)
          TransactionItem(
            productId: 'logo_service',
            productName: 'Lambang Sekolah',
            size: _logoPrice > 0 ? '' : 'Gratis/Termasuk',
            quantity: 1,
            unitPrice: _logoPrice,
            totalPrice: _logoPrice,
            isCustom: false,
          ),
      ];

      await transactionRepo.createTransaction(transaction, items);

      ref.read(cartProvider.notifier).clear();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasCustom
                  ? 'Transaksi berhasil! SPK pesanan otomatis dibuat.'
                  : 'Transaksi berhasil!',
            ),
            backgroundColor: const Color(0xFF004D4C),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── Discount Dialog ──
  void _showDiscountDialog() {
    final cart = ref.read(cartProvider);
    final discountController = TextEditingController(
      text: cart.discount > 0
          ? formatCurrency(
              cart.discount,
            ).replaceAll('Rp ', '').replaceAll('.', '')
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.discount_outlined, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Text(
              'Berikan Diskon',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan nominal potongan harga (Rupiah) yang ingin diberikan secara manual.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: discountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                RupiahInputFormatter(),
              ],
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'Nominal Potongan',
                prefixText: 'Rp ',
                prefixStyle: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF003D3D),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tutup',
              style: GoogleFonts.inter(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final digits = discountController.text.replaceAll(
                RegExp(r'[^\d]'),
                '',
              );
              final discount = double.tryParse(digits) ?? 0;
              ref.read(cartProvider.notifier).setDiscount(discount);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D4C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              'Terapkan Diskon',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
