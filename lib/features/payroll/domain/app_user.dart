import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // admin, cashier, tailor
  final String phone;
  final double cashAdvanceBalance;
  final String? imageUrl;
  final bool isApproved;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.cashAdvanceBalance,
    this.imageUrl,
    this.isApproved = false,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'pending',
      phone: data['phone'] ?? '',
      cashAdvanceBalance: (data['cash_advance_balance'] ?? 0).toDouble(),
      imageUrl: data['image_url'],
      isApproved: data['is_approved'] ?? false,
      createdAt:
          (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'cash_advance_balance': cashAdvanceBalance,
      'image_url': imageUrl,
      'is_approved': isApproved,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  bool get isTailor => role == 'tailor';
  bool get isCashier => role == 'cashier';
  bool get isAdmin => role == 'admin';

  String get roleDisplay {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'cashier':
        return 'Kasir';
      case 'tailor':
        return 'Penjahit';
      default:
        return role;
    }
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    double? cashAdvanceBalance,
    String? imageUrl,
    bool? isApproved,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      cashAdvanceBalance: cashAdvanceBalance ?? this.cashAdvanceBalance,
      imageUrl: imageUrl ?? this.imageUrl,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
