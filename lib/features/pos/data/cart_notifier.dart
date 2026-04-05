import 'package:flutter_riverpod/legacy.dart';
import '../../../core/utils/currency_utils.dart';

import '../../inventory/domain/product.dart';

/// Represents a single product-based item in the cart
class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  double get totalPrice => product.price * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  String get formattedPrice => formatCurrency(product.price);
  String get formattedTotal => formatCurrency(totalPrice);
}

/// Represents a custom (manually entered) item in the cart
class CustomCartItem {
  final String id; // unique generated id
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String? productType;
  final String? baseProductId;

  const CustomCartItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    this.productType,
    this.baseProductId,
  });

  double get totalPrice => price * quantity;

  CustomCartItem copyWith({
    String? name,
    String? description,
    double? price,
    int? quantity,
    String? productType,
    String? baseProductId,
  }) {
    return CustomCartItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      productType: productType ?? this.productType,
      baseProductId: baseProductId ?? this.baseProductId,
    );
  }

  String get formattedPrice => formatCurrency(price);
  String get formattedTotal => formatCurrency(totalPrice);
}

/// State of the shopping cart
class CartState {
  final List<CartItem> items;
  final List<CustomCartItem> customItems;
  final double discount;

  const CartState({
    this.items = const [],
    this.customItems = const [],
    this.discount = 0,
  });

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice) +
      customItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get grandTotal => subtotal - discount;

  int get totalItems =>
      items.fold(0, (sum, item) => sum + item.quantity) +
      customItems.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty && customItems.isEmpty;

  String get formattedSubtotal => formatCurrency(subtotal);
  String get formattedDiscount => formatCurrency(discount);
  String get formattedGrandTotal => formatCurrency(grandTotal);

  CartState copyWith({
    List<CartItem>? items,
    List<CustomCartItem>? customItems,
    double? discount,
  }) {
    return CartState(
      items: items ?? this.items,
      customItems: customItems ?? this.customItems,
      discount: discount ?? this.discount,
    );
  }
}

/// Notifier to manage cart state mutations
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  /// Add a product to the cart (increment if exists)
  void addItem(Product product) {
    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      final updatedItems = [...state.items];
      final existing = updatedItems[existingIndex];
      updatedItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + 1,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(
        items: [
          ...state.items,
          CartItem(product: product, quantity: 1),
        ],
      );
    }
  }

  /// Remove a product from the cart entirely
  void removeItem(String productId) {
    state = state.copyWith(
      items:
          state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  /// Update the quantity of an item
  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  /// Add a custom item to the cart
  void addCustomItem(CustomCartItem item) {
    state = state.copyWith(
      customItems: [...state.customItems, item],
    );
  }

  /// Remove a custom item from the cart
  void removeCustomItem(String customItemId) {
    state = state.copyWith(
      customItems:
          state.customItems.where((item) => item.id != customItemId).toList(),
    );
  }

  /// Update quantity of a custom item
  void updateCustomQuantity(String customItemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeCustomItem(customItemId);
      return;
    }

    final updated = state.customItems.map((item) {
      if (item.id == customItemId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(customItems: updated);
  }

  /// Set global discount
  void setDiscount(double discount) {
    state = state.copyWith(discount: discount);
  }

  /// Clear the cart
  void clear() {
    state = const CartState();
  }
}

/// Provider for the cart notifier
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
