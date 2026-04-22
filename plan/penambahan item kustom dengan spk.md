# Walkthrough: Custom Order Flow (POS → SPK → Gaji)

## Summary

Implemented a complete custom order flow that connects POS checkout to production tracking (SPK) and tailor wages. When a customer orders items that aren't in stock, the system now automatically creates production orders and tracks them through completion.

## What Changed

### 1. Data Models

#### [transaction_model.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/pos/domain/transaction_model.dart)

- Added `customerName`, `customerPhone`, `pickupDate`, `hasCustomItems` to `TransactionModel`
- Added `isCustom` flag to `TransactionItem` (replaces `productId.startsWith('custom_')` checks)
- Added `stockItems` and `customOrderItems` getters for easy separation

#### [production_order.dart](file:///e:/Code/Flutter/rumah_jahit/lib/features/inventory/domain/production_order.dart)

- Added `transactionId`, `customerName`, `customerPhone`, `pickupDate` to `ProductionOrder`
- Links SPKs back to their originating POS transaction

---

### 2. Checkout Screen

```diff:checkout_screen.dart
===
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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

  // Customer info controllers (for custom orders)
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  DateTime? _pickupDate;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final hasCustomItems = cart.customItems.isNotEmpty;

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
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
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
                        ref
                            .read(cartProvider.notifier)
                            .removeItem(item.product.id);
                      },
                      child: OrderItemCard(
                        icon: Icons.checkroom_outlined,
                        title: '${item.product.name} (${item.product.size})',
                        subtitle: '${item.product.formattedPrice} / pcs',
                        price: _formatCurrency(item.totalPrice),
                        quantity: item.quantity,
                        onIncrement: () {
                          ref
                              .read(cartProvider.notifier)
                              .updateQuantity(
                                item.product.id,
                                item.quantity + 1,
                              );
                        },
                        onDecrement: () {
                          ref
                              .read(cartProvider.notifier)
                              .updateQuantity(
                                item.product.id,
                                item.quantity - 1,
                              );
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
                        ref
                            .read(cartProvider.notifier)
                            .removeCustomItem(item.id);
                      },
                      child: OrderItemCard(
                        icon: Icons.edit_note_outlined,
                        title: item.name,
                        subtitle: item.description.isNotEmpty
                            ? '${item.formattedPrice} / pcs • ${item.description}'
                            : '${item.formattedPrice} / pcs',
                        price: _formatCurrency(item.totalPrice),
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
                    'Wajib diisi untuk pesanan kustom',
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
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
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
                                      ? DateFormat('dd MMMM yyyy')
                                          .format(_pickupDate!)
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
                  grandTotal: cart.grandTotal,
                  selectedMethod: _selectedPaymentMethod,
                  amountPaid: _amountPaid,
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
                      _summaryRow('Subtotal', _formatCurrency(cart.subtotal)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Diskon',
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
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF004D4C,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Ubah',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF004D4C),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatCurrency(cart.discount),
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF001F1F),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _summaryRow(
                        'Grand Total',
                        _formatCurrency(cart.grandTotal),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: cart.isEmpty
          ? null
          : Container(
              color: const Color(0xFFF9FAFA),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SizedBox(
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
                    _RupiahFormatter(),
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
            content: Text('Nama pelanggan wajib diisi untuk item kustom!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_customerPhoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No. WhatsApp wajib diisi untuk item kustom!'),
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

    if (_selectedPaymentMethod == 'CASH' && _amountPaid < cart.grandTotal) {
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
        cashierId: '', // TODO: Wire to current auth user
        subtotal: cart.subtotal,
        discount: cart.discount,
        grandTotal: cart.grandTotal,
        paymentMethod: _selectedPaymentMethod,
        amountPaid: _selectedPaymentMethod == 'CASH'
            ? _amountPaid
            : cart.grandTotal,
        status: hasCustom ? 'PENDING' : 'SUCCESSFUL',
        createdAt: DateTime.now(),
        customerName:
            hasCustom ? _customerNameController.text.trim() : null,
        customerPhone:
            hasCustom ? _customerPhoneController.text.trim() : null,
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
          ),
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
      text: cart.discount > 0 ? cart.discount.toInt().toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Input Diskon',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: discountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _RupiahFormatter(),
          ],
          decoration: InputDecoration(
            labelText: 'Diskon (Rp)',
            prefixIcon: const Icon(Icons.discount_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
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
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }
}

/// Rupiah formatter for the price input
class _RupiahFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final number = int.parse(digitsOnly);
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    final prefixed = 'Rp ${buffer.toString()}';
    return TextEditingValue(
      text: prefixed,
      selection: TextSelection.collapsed(offset: prefixed.length),
    );
  }
}

```

**Key changes:**

- **Customer Info Section** — Only appears when cart has custom items
  - Nama Pelanggan (required)
  - No. WhatsApp (required, phone keyboard)
  - Tanggal Pengambilan (date picker)
- **Validation** — Prevents payment if customer info is empty for custom orders
- **`_processPayment()`** — Now passes `isCustom: true` flag on custom items

---

### 3. Transaction Repository (Auto-SPK)

```diff:transaction_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/transaction_model.dart';

class TransactionRepository {
  final _collection = FirebaseFirestore.instance.collection('transactions');

  TransactionRepository();

  /// Create a transaction with atomic stock deduction via WriteBatch
  Future<void> createTransaction(
    TransactionModel transaction,
    List<TransactionItem> items,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. Create the transaction document
    final txRef = _collection.doc();
    batch.set(txRef, transaction.toFirestore());

    // 2. Add each item to the sub-collection
    for (final item in items) {
      final itemRef = txRef.collection('items').doc();
      batch.set(itemRef, item.toFirestore());
    }

    // 3. Deduct stock for each product (skip custom items)
    final productsCol = FirebaseFirestore.instance.collection('products');
    for (final item in items) {
      if (item.productId.startsWith('custom_')) continue;
      batch.update(productsCol.doc(item.productId), {
        'current_stock': FieldValue.increment(-item.quantity),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    // Commit the batch atomically
    await batch.commit();
  }

  /// Stream of today's transactions
  Stream<List<TransactionModel>> watchToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _collection
        .where('created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('created_at', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  /// Stream of all transactions (for history)
  Stream<List<TransactionModel>> watchAll() {
    return _collection
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap((snapshot) async {
      final txs = <TransactionModel>[];
      for (final doc in snapshot.docs) {
        final itemsSnapshot = await doc.reference.collection('items').get();
        final items = itemsSnapshot.docs
            .map((itemDoc) => TransactionItem.fromFirestore(itemDoc))
            .toList();
        txs.add(TransactionModel.fromFirestore(doc, items: items));
      }
      return txs;
    });
  }

  /// Update transaction status
  Future<void> updateStatus(String transactionId, String newStatus) async {
    await _collection.doc(transactionId).update({
      'status': newStatus,
    });
  }

  /// Cancel a transaction (sets status to CANCELLED, restores stock)
  Future<void> cancel(String transactionId) async {
    // Fetch the transaction items first
    final itemsSnapshot =
        await _collection.doc(transactionId).collection('items').get();

    final batch = FirebaseFirestore.instance.batch();

    // Restore stock for each item
    final productsCol = FirebaseFirestore.instance.collection('products');
    for (final itemDoc in itemsSnapshot.docs) {
      final data = itemDoc.data();
      final productId = data['product_id'] as String;
      final quantity = (data['quantity'] as num).toInt();
      batch.update(productsCol.doc(productId), {
        'current_stock': FieldValue.increment(quantity),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    // Update transaction status
    batch.update(_collection.doc(transactionId), {
      'status': 'CANCELLED',
    });

    await batch.commit();
  }
}
===
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/transaction_model.dart';
import '../../inventory/domain/production_order.dart';

class TransactionRepository {
  final _collection = FirebaseFirestore.instance.collection('transactions');
  final _spkCollection = FirebaseFirestore.instance.collection(
    'production_orders',
  );

  TransactionRepository();

  /// Create a transaction with atomic stock deduction via WriteBatch.
  /// If there are custom items, auto-create 1 SPK per custom item.
  Future<void> createTransaction(
    TransactionModel transaction,
    List<TransactionItem> items,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. Create the transaction document
    final txRef = _collection.doc();
    batch.set(txRef, transaction.toFirestore());

    // 2. Add each item to the sub-collection
    for (final item in items) {
      final itemRef = txRef.collection('items').doc();
      batch.set(itemRef, item.toFirestore());
    }

    // 3. Deduct stock for each product-based item (skip custom items)
    final productsCol = FirebaseFirestore.instance.collection('products');
    for (final item in items) {
      if (item.isCustom) continue;
      batch.update(productsCol.doc(item.productId), {
        'current_stock': FieldValue.increment(-item.quantity),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    // 4. Auto-create 1 SPK per custom item
    final customItems = items.where((i) => i.isCustom).toList();
    for (final customItem in customItems) {
      final spkRef = _spkCollection.doc();
      final spk = ProductionOrder(
        id: spkRef.id,
        title: '${customItem.productName} - ${transaction.customerName ?? "Pelanggan"}',
        spkType: 'CUSTOM',
        productName: customItem.productName,
        productType: 'custom',
        items: [
          SpkVariant(
            productId: '',
            size: customItem.size,
            targetQuantity: customItem.quantity,
          ),
        ],
        targetQuantity: customItem.quantity,
        status: 'PENDING',
        completedQuantity: 0,
        tailorAssignments: [],
        wagePerPiece: 0,
        materialsUsed: [],
        startDate: DateTime.now(),
        estimatedCompletionDate: transaction.pickupDate ?? DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
        transactionId: txRef.id,
        customerName: transaction.customerName,
        customerPhone: transaction.customerPhone,
        pickupDate: transaction.pickupDate,
      );
      batch.set(spkRef, spk.toFirestore());
    }

    // Commit the batch atomically
    await batch.commit();
  }

  /// Stream of today's transactions
  Stream<List<TransactionModel>> watchToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _collection
        .where('created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('created_at', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  /// Stream of all transactions (for history)
  Stream<List<TransactionModel>> watchAll() {
    return _collection
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap((snapshot) async {
      final txs = <TransactionModel>[];
      for (final doc in snapshot.docs) {
        final itemsSnapshot = await doc.reference.collection('items').get();
        final items = itemsSnapshot.docs
            .map((itemDoc) => TransactionItem.fromFirestore(itemDoc))
            .toList();
        txs.add(TransactionModel.fromFirestore(doc, items: items));
      }
      return txs;
    });
  }

  /// Update transaction status
  Future<void> updateStatus(String transactionId, String newStatus) async {
    await _collection.doc(transactionId).update({
      'status': newStatus,
    });
  }

  /// Cancel a transaction (sets status to CANCELLED, restores stock)
  Future<void> cancel(String transactionId) async {
    // Fetch the transaction items first
    final itemsSnapshot =
        await _collection.doc(transactionId).collection('items').get();

    final batch = FirebaseFirestore.instance.batch();

    // Restore stock for each non-custom item
    final productsCol = FirebaseFirestore.instance.collection('products');
    for (final itemDoc in itemsSnapshot.docs) {
      final data = itemDoc.data();
      final isCustom = data['is_custom'] ?? false;
      if (isCustom) continue;

      final productId = data['product_id'] as String;
      final quantity = (data['quantity'] as num).toInt();
      batch.update(productsCol.doc(productId), {
        'current_stock': FieldValue.increment(quantity),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    // Update transaction status
    batch.update(_collection.doc(transactionId), {
      'status': 'CANCELLED',
    });

    await batch.commit();
  }
}

```

**Key change:** After creating the transaction, loops through each custom item and creates **1 SPK per item** in the same atomic batch:

- SPK title: `"[Item Name] - [Customer Name]"`
- Type: `CUSTOM`
- Status: `PENDING` (no tailor assigned yet)
- Links to transaction via `transactionId`

---

### 4. Receipt Screen (Split Sections + WhatsApp)

```diff:receipt_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:rumah_jahit/features/pos/data/pos_providers.dart';
import 'package:rumah_jahit/features/pos/domain/transaction_model.dart';
import 'package:rumah_jahit/core/utils/snackbar_utils.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  final TransactionModel transaction;

  const ReceiptScreen({super.key, required this.transaction});

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  bool _isProcessingStatus = false;

  void _markAsDone() async {
    setState(() => _isProcessingStatus = true);
    try {
      final repo = ref.read(transactionRepositoryProvider);
      await repo.updateStatus(widget.transaction.id, 'SUCCESSFUL');

      if (mounted) {
        SnackBarUtils.show(context, 'Pesanan ditandai selesai!');
        Navigator.pop(context); // Go back to history
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.show(context, 'Gagal mengupdate status: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessingStatus = false);
    }
  }

  void _simulateAction(String actionName) {
    SnackBarUtils.show(context, '$actionName ditekan (Fitur menyusul)');
  }

  @override
  Widget build(BuildContext context) {
    final bool isPending = widget.transaction.status == 'PENDING';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFA),
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Receipt',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF003D3D),
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF003D3D)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isPending)
            _isProcessingStatus
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(
                    icon: const Icon(Icons.check_circle_outline,
                        color: Color(0xFF004D4C)),
                    onPressed: _markAsDone,
                    tooltip: 'Tandai Selesai',
                  ),
          if (!isPending)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.check, color: Colors.grey),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // -- LOGO & HEADER --
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF004D4C),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.checkroom, // Or straighten
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Rumah Jahit',
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF003D3D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'THE MODERN ATELIER',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // -- DOTTED DIVIDER --
                        _buildDottedLine(),
                        const SizedBox(height: 24),

                        // -- TXN ID & DATE --
                        Text(
                          widget.transaction.formattedId,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF001F1F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • HH:mm')
                              .format(widget.transaction.createdAt)
                              .toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // -- ITEMS --
                        ...widget.transaction.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: const Color(0xFF001F1F),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.quantity} x ${_formatPrice(item.unitPrice)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatPrice(item.totalPrice),
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: const Color(0xFF001F1F),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),

                        // -- TOTALS --
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              _formatPrice(widget.transaction.subtotal),
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: const Color(0xFF001F1F),
                              ),
                            ),
                          ],
                        ),
                        if (widget.transaction.discount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Diskon',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '-${_formatPrice(widget.transaction.discount)}',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL AMOUNT',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF004D4C),
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              widget.transaction.formattedGrandTotal,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: const Color(0xFF004D4C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // -- PAYMENT INFO BOX --
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F4F4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _infoRow(
                                'Payment Method',
                                widget.transaction.paymentMethod == 'CASH'
                                    ? 'Tunai'
                                    : widget.transaction.paymentMethod,
                              ),
                              const SizedBox(height: 12),
                              _infoRow(
                                'Paid',
                                _formatPrice(widget.transaction.amountPaid),
                              ),
                              const SizedBox(height: 12),
                              _infoRow(
                                'Change',
                                _formatPrice(widget.transaction.change),
                                isGreen: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // -- SLOGAN --
                        Text(
                          '"Precision in every stitch. Thank you for choosing Rumah Jahit."',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Zigzag bottom decoration effect (Optional, omitted for clean look)
                ],
              ),
            ),
          ),

          // Added space so it doesn't collide with bottom bar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // -- BOTTOM ACTION BAR --
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFA),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _simulateAction('Print Thermal'),
                  icon: const Icon(Icons.print, size: 20),
                  label: Text('Print\nReceipt',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFF004D4C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _simulateAction('Share via WhatsApp'),
                  icon: const Icon(Icons.share, size: 20),
                  label: Text('Share',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18), // taller a bit or same
                    backgroundColor: const Color(0xFFA4F0E9),
                    foregroundColor: const Color(0xFF003D3D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: isGreen ? const Color(0xFF006766) : const Color(0xFF001F1F),
          ),
        ),
      ],
    );
  }

  Widget _buildDottedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade300),
              ),
            );
          }),
        );
      },
    );
  }

  String _formatPrice(double amount) {
    if (amount <= 0) return 'Rp 0';
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }
}
===
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:rumah_jahit/features/pos/domain/transaction_model.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  final TransactionModel transaction;

  const ReceiptScreen({super.key, required this.transaction});

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  void _simulateAction(String actionName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$actionName (Fitur menyusul)'),
        backgroundColor: const Color(0xFF004D4C),
      ),
    );
  }

  Future<void> _shareViaWhatsApp() async {
    final tx = widget.transaction;
    final phone = tx.customerPhone;

    if (phone == null || phone.isEmpty) {
      _simulateAction('Share Receipt');
      return;
    }

    // Format phone: remove leading 0, add 62
    String formattedPhone = phone;
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('62')) {
      formattedPhone = '62$formattedPhone';
    }

    // Build receipt text
    final buffer = StringBuffer();
    buffer.writeln('*RUMAH JAHIT* - Receipt');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('ID: ${tx.formattedId}');
    buffer.writeln(
      'Tanggal: ${DateFormat('dd MMM yyyy, HH:mm').format(tx.createdAt)}',
    );
    buffer.writeln('');

    final stockItems = tx.stockItems;
    final customItems = tx.customOrderItems;

    if (stockItems.isNotEmpty) {
      buffer.writeln('📦 *Barang Stok*');
      for (final item in stockItems) {
        buffer.writeln(
          '  ${item.quantity}x ${item.productName} — ${_formatPrice(item.totalPrice)}',
        );
      }
      buffer.writeln('');
    }

    if (customItems.isNotEmpty) {
      buffer.writeln('✂️ *Pesanan Kustom*');
      for (final item in customItems) {
        buffer.writeln(
          '  ${item.quantity}x ${item.productName} — ${_formatPrice(item.totalPrice)}',
        );
        if (item.size.isNotEmpty) {
          buffer.writeln('    _${item.size}_');
        }
      }
      if (tx.pickupDate != null) {
        buffer.writeln(
          '  📅 Est. Pengambilan: ${DateFormat('dd MMM yyyy').format(tx.pickupDate!)}',
        );
      }
      buffer.writeln('');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    if (tx.discount > 0) {
      buffer.writeln('Subtotal: ${_formatPrice(tx.subtotal)}');
      buffer.writeln('Diskon: -${_formatPrice(tx.discount)}');
    }
    buffer.writeln('*TOTAL: ${tx.formattedGrandTotal}*');
    buffer.writeln('');
    buffer.writeln(
      '_"Precision in every stitch. Thank you for choosing Rumah Jahit."_',
    );

    final uri = Uri.parse(
      'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(buffer.toString())}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final bool isPending = tx.status == 'PENDING';
    final stockItems = tx.stockItems;
    final customItems = tx.customOrderItems;
    final hasCustom = customItems.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFA),
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Receipt',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF003D3D),
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF003D3D)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Pending banner
                  if (isPending)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Colors.amber.shade800,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Menunggu Pengerjaan',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pesanan personal sedang dalam antrian produksi',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Main receipt card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // -- LOGO & HEADER --
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF004D4C),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.checkroom,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Rumah Jahit',
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF003D3D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'THE MODERN ATELIER',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildDottedLine(),
                        const SizedBox(height: 24),

                        // -- TXN ID & DATE --
                        Text(
                          tx.formattedId,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF001F1F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • HH:mm')
                              .format(tx.createdAt)
                              .toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),

                        // -- Customer name if exists --
                        if (tx.customerName != null &&
                            tx.customerName!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'a/n ${tx.customerName}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),

                        // -- STOCK ITEMS SECTION --
                        if (stockItems.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'BARANG STOK',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...stockItems.map(
                            (item) => _buildItemRow(item),
                          ),
                          if (hasCustom)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: _buildDottedLine(),
                            ),
                        ],

                        // -- CUSTOM ITEMS SECTION --
                        if (hasCustom) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.content_cut,
                                size: 14,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'PESANAN KUSTOM${tx.customerName != null ? " (${tx.customerName})" : ""}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.amber.shade700,
                                    letterSpacing: 1.0,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...customItems.map(
                            (item) => _buildItemRow(item, isCustom: true),
                          ),
                          if (tx.pickupDate != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F4F4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Est. Pengambilan: ${DateFormat('dd MMMM yyyy').format(tx.pickupDate!)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],

                        // -- Items fallback (no custom/stock separation for old data) --
                        if (stockItems.isEmpty && customItems.isEmpty)
                          ...tx.items.map(
                            (item) => _buildItemRow(item),
                          ),

                        const SizedBox(height: 24),

                        // -- TOTALS --
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              _formatPrice(tx.subtotal),
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: const Color(0xFF001F1F),
                              ),
                            ),
                          ],
                        ),
                        if (tx.discount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Diskon',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '-${_formatPrice(tx.discount)}',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL AMOUNT',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF004D4C),
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              tx.formattedGrandTotal,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: const Color(0xFF004D4C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // -- PAYMENT INFO BOX --
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F4F4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _infoRow(
                                'Payment Method',
                                tx.paymentMethod == 'CASH'
                                    ? 'Tunai'
                                    : tx.paymentMethod,
                              ),
                              const SizedBox(height: 12),
                              _infoRow(
                                'Paid',
                                _formatPrice(tx.amountPaid),
                              ),
                              const SizedBox(height: 12),
                              _infoRow(
                                'Change',
                                _formatPrice(tx.change),
                                isGreen: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // -- SLOGAN --
                        Text(
                          '"Precision in every stitch. Thank you for choosing Rumah Jahit."',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // -- BOTTOM ACTION BAR --
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFA),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _simulateAction('Print Thermal'),
                  icon: const Icon(Icons.print, size: 20),
                  label: Text(
                    'Print\nReceipt',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFF004D4C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasCustom
                      ? _shareViaWhatsApp
                      : () => _simulateAction('Share'),
                  icon: Icon(
                    hasCustom ? Icons.send : Icons.share,
                    size: 20,
                  ),
                  label: Text(
                    hasCustom ? 'WhatsApp' : 'Share',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: hasCustom
                        ? const Color(0xFF25D366)
                        : const Color(0xFFA4F0E9),
                    foregroundColor: hasCustom
                        ? Colors.white
                        : const Color(0xFF003D3D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(TransactionItem item, {bool isCustom = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF001F1F),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${item.quantity} x ${_formatPrice(item.unitPrice)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (isCustom && item.size.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.size,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            _formatPrice(item.totalPrice),
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: const Color(0xFF001F1F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: isGreen ? const Color(0xFF006766) : const Color(0xFF001F1F),
          ),
        ),
      ],
    );
  }

  Widget _buildDottedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade300),
              ),
            );
          }),
        );
      },
    );
  }

  String _formatPrice(double amount) {
    if (amount <= 0) return 'Rp 0';
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }
}

```

**Key changes:**

- **Pending banner** — Yellow alert showing "Menunggu Pengerjaan" for pending orders
- **Split items** — "📦 BARANG STOK" and "✂️ PESANAN KUSTOM" sections
- **Customer badge** — Shows "a/n [Name]" under transaction ID
- **Pickup date** — Displayed in custom section
- **WhatsApp Share** — Green button opens `wa.me/` deep link with formatted receipt text

---

### 5. Transaction History

```diff:transaction_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:rumah_jahit/features/pos/data/pos_providers.dart';
import 'package:rumah_jahit/features/pos/domain/transaction_model.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  DateTimeRange? _selectedDateRange;

  final List<String> _filters = ['Semua', 'Hari Ini', 'Minggu Ini', 'Selesai'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.toLowerCase());
  }

  bool _passesFilter(TransactionModel tx) {
    // 1. Search Query
    if (_searchQuery.isNotEmpty) {
      if (!tx.formattedId.toLowerCase().contains(_searchQuery)) {
        return false;
      }
    }

    // 2. Date Range Filter
    if (_selectedDateRange != null) {
      final start = _selectedDateRange!.start;
      final end = _selectedDateRange!.end;
      final txDate = DateTime(
        tx.createdAt.year,
        tx.createdAt.month,
        tx.createdAt.day,
      );
      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day);

      if (txDate.isBefore(startDate) || txDate.isAfter(endDate)) {
        return false;
      }
    }

    // 3. Chip Filter
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Hari Ini':
        if (tx.createdAt.year != now.year ||
            tx.createdAt.month != now.month ||
            tx.createdAt.day != now.day) {
          return false;
        }
        break;
      case 'Minggu Ini':
        final lastWeek = now.subtract(const Duration(days: 7));
        if (tx.createdAt.isBefore(lastWeek)) {
          return false;
        }
        break;
      case 'Selesai':
        if (tx.status != 'SUCCESS' && tx.status != 'SUCCESSFUL') {
          return false;
        }
        break;
      case 'Semua':
      default:
        break;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFA),
        scrolledUnderElevation: 0,
        title: Text(
          'Riwayat Transaksi',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF003D3D),
          ),
        ),
        leading: ActionChip(
          onPressed: () => Navigator.of(context).pop(),
          backgroundColor: Colors.transparent,
          side: BorderSide.none,
          label: const Icon(Icons.arrow_back, color: Color(0xFF003D3D)),
        ),
        actions: [
          if (_selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              onPressed: () => setState(() => _selectedDateRange = null),
              tooltip: 'Hapus Filter Tanggal',
            ),
          IconButton(
            icon: Icon(
              Icons.date_range,
              color: _selectedDateRange != null
                  ? const Color(0xFF006766)
                  : const Color(0xFF003D3D),
            ),
            tooltip: 'Filter Tanggal',
            onPressed: () async {
              final result = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _selectedDateRange,
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
              if (result != null) {
                setState(() {
                  _selectedDateRange = result;
                  if (_selectedFilter == 'Hari Ini' ||
                      _selectedFilter == 'Minggu Ini') {
                    _selectedFilter = 'Semua';
                  }
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF003D3D)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari ID Pesanan...',
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF004D4C)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        filter,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // List List
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (allData) {
                final data = allData.where(_passesFilter).toList();

                if (data.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada riwayat transaksi.',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: data.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final tx = data[index];
                    return _buildTransactionCard(tx, colors.primary);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx, Color primaryColor) {
    final bool isSuccess = tx.status == 'SUCCESS' || tx.status == 'SUCCESSFUL';
    final formatter = DateFormat('dd MMM yyyy • HH:mm');

    return GestureDetector(
      onTap: () {
        context.push('/pos/receipt', extra: tx);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID PESANAN',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF006766),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx.formattedId,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF003D3D),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? const Color(0xFFA4F0E9)
                        : Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSuccess ? Icons.check_circle : Icons.schedule,
                        size: 12,
                        color: isSuccess
                            ? const Color(0xFF004D4C)
                            : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSuccess ? 'SUCCESSFUL' : 'PENDING',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isSuccess
                              ? const Color(0xFF004D4C)
                              : Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  formatter.format(tx.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Items Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (tx.items.isEmpty)
                    Text(
                      'Tidak ada data item',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ...tx.items.take(2).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item.productId.startsWith('custom_')
                                  ? Icons.edit_note
                                  : Icons.checkroom,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity}x ${item.productName}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: const Color(0xFF001F1F),
                                  ),
                                ),
                                if (item.size.isNotEmpty)
                                  Text(
                                    item.size,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (tx.items.length > 2)
                    Text(
                      '+ ${tx.items.length - 2} item lainnya',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF006766),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Footer: Payment & Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            tx.paymentMethod == 'CASH'
                                ? Icons.money
                                : tx.paymentMethod == 'TRANSFER'
                                ? Icons.account_balance
                                : Icons.qr_code_2,
                            size: 14,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tx.paymentMethod == 'CASH'
                                ? 'Tunai'
                                : tx.paymentMethod == 'TRANSFER'
                                ? 'Transfer'
                                : 'QRIS',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PELANGGAN: UMUM',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TOTAL TAGIHAN',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.formattedGrandTotal,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF003D3D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
===
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:rumah_jahit/features/pos/data/pos_providers.dart';
import 'package:rumah_jahit/features/pos/domain/transaction_model.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  DateTimeRange? _selectedDateRange;

  final List<String> _filters = ['Semua', 'Hari Ini', 'Minggu Ini', 'Pending', 'Selesai'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.toLowerCase());
  }

  bool _passesFilter(TransactionModel tx) {
    // 1. Search Query
    if (_searchQuery.isNotEmpty) {
      if (!tx.formattedId.toLowerCase().contains(_searchQuery)) {
        return false;
      }
    }

    // 2. Date Range Filter
    if (_selectedDateRange != null) {
      final start = _selectedDateRange!.start;
      final end = _selectedDateRange!.end;
      final txDate = DateTime(
        tx.createdAt.year,
        tx.createdAt.month,
        tx.createdAt.day,
      );
      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day);

      if (txDate.isBefore(startDate) || txDate.isAfter(endDate)) {
        return false;
      }
    }

    // 3. Chip Filter
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Hari Ini':
        if (tx.createdAt.year != now.year ||
            tx.createdAt.month != now.month ||
            tx.createdAt.day != now.day) {
          return false;
        }
        break;
      case 'Minggu Ini':
        final lastWeek = now.subtract(const Duration(days: 7));
        if (tx.createdAt.isBefore(lastWeek)) {
          return false;
        }
        break;
      case 'Selesai':
        if (tx.status != 'SUCCESS' && tx.status != 'SUCCESSFUL') {
          return false;
        }
        break;
      case 'Pending':
        if (tx.status != 'PENDING') {
          return false;
        }
        break;
      case 'Semua':
      default:
        break;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFA),
        scrolledUnderElevation: 0,
        title: Text(
          'Riwayat Transaksi',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF003D3D),
          ),
        ),
        leading: ActionChip(
          onPressed: () => Navigator.of(context).pop(),
          backgroundColor: Colors.transparent,
          side: BorderSide.none,
          label: const Icon(Icons.arrow_back, color: Color(0xFF003D3D)),
        ),
        actions: [
          if (_selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              onPressed: () => setState(() => _selectedDateRange = null),
              tooltip: 'Hapus Filter Tanggal',
            ),
          IconButton(
            icon: Icon(
              Icons.date_range,
              color: _selectedDateRange != null
                  ? const Color(0xFF006766)
                  : const Color(0xFF003D3D),
            ),
            tooltip: 'Filter Tanggal',
            onPressed: () async {
              final result = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _selectedDateRange,
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
              if (result != null) {
                setState(() {
                  _selectedDateRange = result;
                  if (_selectedFilter == 'Hari Ini' ||
                      _selectedFilter == 'Minggu Ini') {
                    _selectedFilter = 'Semua';
                  }
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF003D3D)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari ID Pesanan...',
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF004D4C)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        filter,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // List List
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (allData) {
                final data = allData.where(_passesFilter).toList();

                if (data.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada riwayat transaksi.',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: data.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final tx = data[index];
                    return _buildTransactionCard(tx, colors.primary);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx, Color primaryColor) {
    final bool isSuccess = tx.status == 'SUCCESS' || tx.status == 'SUCCESSFUL';
    final formatter = DateFormat('dd MMM yyyy • HH:mm');

    return GestureDetector(
      onTap: () {
        context.push('/pos/receipt', extra: tx);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID PESANAN',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF006766),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx.formattedId,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF003D3D),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? const Color(0xFFA4F0E9)
                        : Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSuccess ? Icons.check_circle : Icons.schedule,
                        size: 12,
                        color: isSuccess
                            ? const Color(0xFF004D4C)
                            : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSuccess ? 'SUCCESSFUL' : 'PENDING',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isSuccess
                              ? const Color(0xFF004D4C)
                              : Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  formatter.format(tx.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Items Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (tx.items.isEmpty)
                    Text(
                      'Tidak ada data item',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ...tx.items.take(2).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item.productId.startsWith('custom_')
                                  ? Icons.edit_note
                                  : Icons.checkroom,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity}x ${item.productName}',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: const Color(0xFF001F1F),
                                  ),
                                ),
                                if (item.size.isNotEmpty)
                                  Text(
                                    item.size,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (tx.items.length > 2)
                    Text(
                      '+ ${tx.items.length - 2} item lainnya',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF006766),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Footer: Payment & Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            tx.paymentMethod == 'CASH'
                                ? Icons.money
                                : tx.paymentMethod == 'TRANSFER'
                                ? Icons.account_balance
                                : Icons.qr_code_2,
                            size: 14,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tx.paymentMethod == 'CASH'
                                ? 'Tunai'
                                : tx.paymentMethod == 'TRANSFER'
                                ? 'Transfer'
                                : 'QRIS',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx.customerName != null && tx.customerName!.isNotEmpty
                            ? 'PELANGGAN: ${tx.customerName!.toUpperCase()}'
                            : 'PELANGGAN: UMUM',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TOTAL TAGIHAN',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.formattedGrandTotal,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF003D3D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- Added **"Pending"** filter chip
- Shows customer name instead of "PELANGGAN: UMUM" when available

---

### 6. SPK Tab View (Sub-tabs)

```diff:spk_tab_view.dart
===
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/inventory_spk_card.dart';
import '../../data/inventory_providers.dart';
import '../../domain/production_order.dart';
import 'inventory_metric_card.dart';

class SpkTabView extends ConsumerStatefulWidget {
  const SpkTabView({super.key});

  @override
  ConsumerState<SpkTabView> createState() => _SpkTabViewState();
}

class _SpkTabViewState extends ConsumerState<SpkTabView> {
  // 0 = Pesanan (CUSTOM), 1 = Produksi (RESTOCK)
  int _selectedSubTab = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ordersAsync = ref.watch(productionOrdersStreamProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        final isIndexError = error.toString().contains('index');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  isIndexError
                      ? 'Indeks Firestore Diperlukan'
                      : 'Terjadi Kesalahan',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isIndexError
                      ? 'Silakan klik link di log debug atau hubungi pengembang untuk mengaktifkan fitur ini.'
                      : '$error',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.red.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      data: (orders) => _buildContent(context, colors, orders),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colors,
    List<ProductionOrder> orders,
  ) {
    // Filter by sub-tab
    final filteredOrders = _selectedSubTab == 0
        ? orders.where((o) => o.isCustom).toList()
        : orders.where((o) => o.isRestock).toList();

    // Calculate metrics from ALL orders
    final activeOrders = orders.where((o) => o.status != 'COMPLETED').toList();
    final inProgressOrders =
        orders.where((o) => o.status == 'IN_PROGRESS').toList();
    final pendingOrders = orders.where((o) => o.status == 'PENDING').toList();
    final completedOrders =
        orders.where((o) => o.status == 'COMPLETED').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
      children: [
        // Grid 2x2 Metrics
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InventoryMetricCard(
                    label: 'TOTAL AKTIF',
                    value: activeOrders.length.toString(),
                    valueColor: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InventoryMetricCard(
                    label: 'PROSES',
                    value: inProgressOrders.length.toString(),
                    valueColor: colors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InventoryMetricCard(
                    label: 'PENDING',
                    value: pendingOrders.length.toString(),
                    valueColor: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InventoryMetricCard(
                    label: 'SELESAI',
                    value: completedOrders.length.toString(),
                    valueColor: const Color(0xFF003D3D),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Sub-tab Toggle: Pesanan vs Produksi ──
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F4),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _buildSubTab(
                index: 0,
                icon: Icons.content_cut,
                label: 'Pesanan',
                count: orders.where((o) => o.isCustom).length,
              ),
              const SizedBox(width: 4),
              _buildSubTab(
                index: 1,
                icon: Icons.factory_outlined,
                label: 'Produksi',
                count: orders.where((o) => o.isRestock).length,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Search Bar
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: _selectedSubTab == 0
                        ? 'Cari nama pelanggan...'
                        : 'Cari SPK produksi...',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF2F4F4),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.filter_list, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // SPK Cards
        if (filteredOrders.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    _selectedSubTab == 0
                        ? Icons.content_cut
                        : Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedSubTab == 0
                        ? 'Belum ada pesanan kustom'
                        : 'Belum ada SPK produksi',
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade500,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...filteredOrders.map((order) {
            Color statusColor;
            Color statusTextColor;
            String statusLabel;

            switch (order.status) {
              case 'COMPLETED':
                statusColor = const Color(0xFFA4F0E9);
                statusTextColor = const Color(0xFF004D4C);
                statusLabel = 'SELESAI';
                break;
              case 'IN_PROGRESS':
                statusColor = const Color.fromARGB(255, 205, 234, 129);
                statusTextColor = const Color(0xFF004D4C);
                statusLabel = 'PROSES';
                break;
              default:
                statusColor = const Color(0xFFCBE7F5);
                statusTextColor = const Color(0xFF1E40AF);
                statusLabel = 'TERJADWAL';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () {
                  context.go('/inventory/spk-detail', extra: order.id);
                },
                child: InventorySpkCard(
                  id: order.id,
                  date: _formatDate(order.createdAt),
                  title: order.title,
                  status: statusLabel,
                  statusColor: statusColor,
                  statusTextColor: statusTextColor,
                  progress: order.progressPercent,
                  progressBarColor: order.isCompleted
                      ? const Color(0xFF004D4C)
                      : order.progressPercent > 0.8
                          ? Colors.red.shade700
                          : const Color(0xFF004D4C),
                  bottomLeftWidget: Row(
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: order.isCustom
                              ? Colors.amber.shade50
                              : const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order.isCustom ? 'Pesanan' : 'Stok',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: order.isCustom
                                ? Colors.amber.shade800
                                : const Color(0xFF004D4C),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Customer name or tailor info
                      if (order.isCustom &&
                          order.customerName != null &&
                          order.customerName!.isNotEmpty) ...[
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            order.customerName!,
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (order.pickupDate != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• ${DateFormat('dd MMM').format(order.pickupDate!)}',
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade500,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ] else ...[
                        Icon(
                          order.isCompleted
                              ? Icons.check_circle
                              : Icons.people_outline,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order.isCompleted
                              ? 'QC PASSED'
                              : '${order.tailorAssignments.length} Penjahit',
                          style: GoogleFonts.inter(
                            color: order.isCompleted
                                ? const Color(0xFF004D4C)
                                : Colors.grey.shade600,
                            fontSize: 10,
                            fontWeight: order.isCompleted
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSubTab({
    required int index,
    required IconData icon,
    required String label,
    required int count,
  }) {
    final isSelected = _selectedSubTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSubTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? const Color(0xFF004D4C)
                    : Colors.grey.shade500,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  color: isSelected
                      ? const Color(0xFF004D4C)
                      : Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFA4F0E9)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? const Color(0xFF004D4C)
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
      'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

```

- Added **toggle sub-tabs**: `✂️ Pesanan` (CUSTOM) | `🏭 Produksi` (RESTOCK)
- Customer name + pickup date shown on custom order cards
- Badge count per tab for quick overview
- Simple UX designed for parent-friendly operation

---

### 7. Auto-Complete Transaction

```diff:production_order_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/production_order.dart';

class ProductionOrderRepository {
  final _collection = FirebaseFirestore.instance.collection(
    'production_orders',
  );
  final _productsCollection = FirebaseFirestore.instance.collection('products');
  final _materialsCollection = FirebaseFirestore.instance.collection(
    'raw_materials',
  );
  final _payrollCollection = FirebaseFirestore.instance.collection(
    'payroll_records',
  );

  /// Real-time stream of all production orders
  Stream<List<ProductionOrder>> watchAll() {
    return _collection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductionOrder.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream of active orders (PENDING + IN_PROGRESS)
  Stream<List<ProductionOrder>> watchActive() {
    return _collection
        .where('status', whereIn: ['PENDING', 'IN_PROGRESS'])
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductionOrder.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream of completed orders
  Stream<List<ProductionOrder>> watchCompleted() {
    return _collection
        .where('status', isEqualTo: 'COMPLETED')
        .orderBy('completed_at', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductionOrder.fromFirestore(doc))
              .toList(),
        );
  }

  /// Add a new production order
  Future<void> add(ProductionOrder order) async {
    final batch = FirebaseFirestore.instance.batch();
    final docRef = _collection.doc();

    final newOrder = order.copyWith(id: docRef.id);
    batch.set(docRef, newOrder.toFirestore());

    // Deduct raw materials immediately on creation
    for (final material in newOrder.materialsUsed) {
      if (material.materialId.isNotEmpty) {
        batch.update(_materialsCollection.doc(material.materialId), {
          'selected_stock': FieldValue.increment(-material.quantity),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  /// Update an existing order
  Future<void> update(ProductionOrder order) async {
    await _collection.doc(order.id).update(order.toFirestore());
  }

  /// Start production (PENDING → IN_PROGRESS)
  Future<void> startProduction(String id) async {
    await _collection.doc(id).update({'status': 'IN_PROGRESS'});
  }

  /// Update production progress
  Future<void> updateProgress(String id, List<SpkVariant> items, {int? completedQty}) async {
    if (completedQty != null) {
      // Custom SPK: update completed_quantity directly
      await _collection.doc(id).update({
        'completed_quantity': completedQty,
      });
    } else {
      // Restock SPK: calculate from items
      final totalCompleted = items.fold(
        0,
        (sum, item) => sum + item.completedQuantity,
      );
      await _collection.doc(id).update({
        'items': items.map((e) => e.toMap()).toList(),
        'completed_quantity': totalCompleted,
      });
    }
  }

  Future<void> completeWithEffects(ProductionOrder order) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. Update SPK → COMPLETED
    batch.update(_collection.doc(order.id), {
      'status': 'COMPLETED',
      'completed_quantity': order.targetQuantity,
      'completed_at': FieldValue.serverTimestamp(),
    });

    // 2. Increment finished goods stock for all variants (RESTOCK only)
    if (order.isRestock) {
      for (final item in order.items) {
        if (item.productId.isNotEmpty) {
          batch.update(_productsCollection.doc(item.productId), {
            'current_stock': FieldValue.increment(item.targetQuantity),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    // (Pemotongan bahan mentah sudah dilakukan saat add/pembuatan SPK)

    // 4. Create payroll records per tailor
    for (final assignment in order.tailorAssignments) {
      final payrollDoc = _payrollCollection.doc();
      batch.set(payrollDoc, {
        'user_id': assignment.userId,
        'user_name': assignment.userName,
        'type': 'spk',
        'spk_id': order.id,
        'spk_title': order.title,
        'note': null,
        'pieces_count': assignment.piecesCount,
        'wage_per_piece': order.wagePerPiece,
        'total_wage': assignment.piecesCount * order.wagePerPiece,
        'status': 'UNPAID',
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Edit material usage quantity midway
  Future<void> updateMaterialUsage(
    String spkId,
    ProductionOrder order,
    String materialId,
    double difference,
  ) async {
    // difference = newQty - oldQty
    final batch = FirebaseFirestore.instance.batch();

    // 1. Calculate new materials list
    final newMaterials = order.materialsUsed.map((m) {
      if (m.materialId == materialId) {
        return m.copyWith(quantity: m.quantity + difference);
      }
      return m;
    }).toList();

    // 2. Update SPK document
    batch.update(_collection.doc(spkId), {
      'materials_used': newMaterials.map((e) => e.toMap()).toList(),
    });

    // 3. Adjust material stock
    // If we use MORE material (difference > 0), we DEDUCT stock (increment -difference)
    // If we use LESS material (difference < 0), we RESTORE stock (increment -difference becomes positive)
    batch.update(_materialsCollection.doc(materialId), {
      'selected_stock': FieldValue.increment(-difference),
      'updated_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Add new material midway
  Future<void> addMaterialUsage(
    String spkId,
    ProductionOrder order,
    MaterialUsed newMaterial,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    final updatedMaterials = [...order.materialsUsed, newMaterial];

    batch.update(_collection.doc(spkId), {
      'materials_used': updatedMaterials.map((e) => e.toMap()).toList(),
    });

    batch.update(_materialsCollection.doc(newMaterial.materialId), {
      'selected_stock': FieldValue.increment(-newMaterial.quantity),
      'updated_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Delete an order (only if PENDING/IN_PROGRESS) and restore stock
  Future<void> delete(ProductionOrder order) async {
    final batch = FirebaseFirestore.instance.batch();

    batch.delete(_collection.doc(order.id));

    // Restore materials
    for (final material in order.materialsUsed) {
      if (material.materialId.isNotEmpty) {
        batch.update(_materialsCollection.doc(material.materialId), {
          'selected_stock': FieldValue.increment(material.quantity),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }
}
===
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/production_order.dart';

class ProductionOrderRepository {
  final _collection = FirebaseFirestore.instance.collection(
    'production_orders',
  );
  final _productsCollection = FirebaseFirestore.instance.collection('products');
  final _materialsCollection = FirebaseFirestore.instance.collection(
    'raw_materials',
  );
  final _payrollCollection = FirebaseFirestore.instance.collection(
    'payroll_records',
  );

  /// Real-time stream of all production orders
  Stream<List<ProductionOrder>> watchAll() {
    return _collection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductionOrder.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream of active orders (PENDING + IN_PROGRESS)
  Stream<List<ProductionOrder>> watchActive() {
    return _collection
        .where('status', whereIn: ['PENDING', 'IN_PROGRESS'])
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductionOrder.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream of completed orders
  Stream<List<ProductionOrder>> watchCompleted() {
    return _collection
        .where('status', isEqualTo: 'COMPLETED')
        .orderBy('completed_at', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductionOrder.fromFirestore(doc))
              .toList(),
        );
  }

  /// Add a new production order
  Future<void> add(ProductionOrder order) async {
    final batch = FirebaseFirestore.instance.batch();
    final docRef = _collection.doc();

    final newOrder = order.copyWith(id: docRef.id);
    batch.set(docRef, newOrder.toFirestore());

    // Deduct raw materials immediately on creation
    for (final material in newOrder.materialsUsed) {
      if (material.materialId.isNotEmpty) {
        batch.update(_materialsCollection.doc(material.materialId), {
          'selected_stock': FieldValue.increment(-material.quantity),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  /// Update an existing order
  Future<void> update(ProductionOrder order) async {
    await _collection.doc(order.id).update(order.toFirestore());
  }

  /// Start production (PENDING → IN_PROGRESS)
  Future<void> startProduction(String id) async {
    await _collection.doc(id).update({'status': 'IN_PROGRESS'});
  }

  /// Update production progress
  Future<void> updateProgress(String id, List<SpkVariant> items, {int? completedQty}) async {
    if (completedQty != null) {
      // Custom SPK: update completed_quantity directly
      await _collection.doc(id).update({
        'completed_quantity': completedQty,
      });
    } else {
      // Restock SPK: calculate from items
      final totalCompleted = items.fold(
        0,
        (sum, item) => sum + item.completedQuantity,
      );
      await _collection.doc(id).update({
        'items': items.map((e) => e.toMap()).toList(),
        'completed_quantity': totalCompleted,
      });
    }
  }

  Future<void> completeWithEffects(ProductionOrder order) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. Update SPK → COMPLETED
    batch.update(_collection.doc(order.id), {
      'status': 'COMPLETED',
      'completed_quantity': order.targetQuantity,
      'completed_at': FieldValue.serverTimestamp(),
    });

    // 2. Increment finished goods stock for all variants (RESTOCK only)
    if (order.isRestock) {
      for (final item in order.items) {
        if (item.productId.isNotEmpty) {
          batch.update(_productsCollection.doc(item.productId), {
            'current_stock': FieldValue.increment(item.targetQuantity),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    // (Pemotongan bahan mentah sudah dilakukan saat add/pembuatan SPK)

    // 4. Create payroll records per tailor
    for (final assignment in order.tailorAssignments) {
      final payrollDoc = _payrollCollection.doc();
      batch.set(payrollDoc, {
        'user_id': assignment.userId,
        'user_name': assignment.userName,
        'type': 'spk',
        'spk_id': order.id,
        'spk_title': order.title,
        'note': null,
        'pieces_count': assignment.piecesCount,
        'wage_per_piece': order.wagePerPiece,
        'total_wage': assignment.piecesCount * order.wagePerPiece,
        'status': 'UNPAID',
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    // 5. Auto-complete linked transaction if all SPKs for it are done
    if (order.isCustom && order.transactionId != null) {
      await _autoCompleteTransaction(order.transactionId!);
    }
  }

  /// Check if all SPKs linked to a transaction are COMPLETED.
  /// If yes, auto-update the transaction status to SUCCESSFUL.
  Future<void> _autoCompleteTransaction(String transactionId) async {
    final linkedSpks = await _collection
        .where('transaction_id', isEqualTo: transactionId)
        .get();

    final allCompleted = linkedSpks.docs.every((doc) {
      final data = doc.data();
      return data['status'] == 'COMPLETED';
    });

    if (allCompleted && linkedSpks.docs.isNotEmpty) {
      final txCollection =
          FirebaseFirestore.instance.collection('transactions');
      await txCollection.doc(transactionId).update({
        'status': 'SUCCESSFUL',
      });
    }
  }

  /// Edit material usage quantity midway
  Future<void> updateMaterialUsage(
    String spkId,
    ProductionOrder order,
    String materialId,
    double difference,
  ) async {
    // difference = newQty - oldQty
    final batch = FirebaseFirestore.instance.batch();

    // 1. Calculate new materials list
    final newMaterials = order.materialsUsed.map((m) {
      if (m.materialId == materialId) {
        return m.copyWith(quantity: m.quantity + difference);
      }
      return m;
    }).toList();

    // 2. Update SPK document
    batch.update(_collection.doc(spkId), {
      'materials_used': newMaterials.map((e) => e.toMap()).toList(),
    });

    // 3. Adjust material stock
    // If we use MORE material (difference > 0), we DEDUCT stock (increment -difference)
    // If we use LESS material (difference < 0), we RESTORE stock (increment -difference becomes positive)
    batch.update(_materialsCollection.doc(materialId), {
      'selected_stock': FieldValue.increment(-difference),
      'updated_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Add new material midway
  Future<void> addMaterialUsage(
    String spkId,
    ProductionOrder order,
    MaterialUsed newMaterial,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    final updatedMaterials = [...order.materialsUsed, newMaterial];

    batch.update(_collection.doc(spkId), {
      'materials_used': updatedMaterials.map((e) => e.toMap()).toList(),
    });

    batch.update(_materialsCollection.doc(newMaterial.materialId), {
      'selected_stock': FieldValue.increment(-newMaterial.quantity),
      'updated_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Delete an order (only if PENDING/IN_PROGRESS) and restore stock
  Future<void> delete(ProductionOrder order) async {
    final batch = FirebaseFirestore.instance.batch();

    batch.delete(_collection.doc(order.id));

    // Restore materials
    for (final material in order.materialsUsed) {
      if (material.materialId.isNotEmpty) {
        batch.update(_materialsCollection.doc(material.materialId), {
          'selected_stock': FieldValue.increment(material.quantity),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }
}
```

After marking a CUSTOM SPK as `COMPLETED`:

1. Queries all SPKs with the same `transactionId`
2. If **all** are `COMPLETED` → auto-updates transaction status to `SUCCESSFUL`

---

## Flow Diagram

```
Customer → Checkout (stok + kustom)
              │
              ├── Stok items → potong stok → SUCCESSFUL
              │
              └── Custom items → PENDING → auto-create 1 SPK per item
                                              │
                                  Admin buka tab "Pesanan" di SPK
                                              │
                                  Assign penjahit + set upah per SPK
                                              │
                                  Complete SPK → payroll record dibuat
                                              │
                                  Semua SPK selesai? → Transaksi → SUCCESSFUL
                                              │
                                  Admin kirim receipt via WhatsApp
```

## Verification

- `flutter analyze` — **0 errors** ✅ (20 info-level warnings only)
