class WageCategory {
  final String id;
  final String name;
  final double amount;

  const WageCategory({
    required this.id,
    required this.name,
    required this.amount,
  });

  factory WageCategory.fromFirestore(Map<String, dynamic> data, String id) {
    return WageCategory(
      id: id,
      name: data['name'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'amount': amount,
      'updatedAt': DateTime.now(),
    };
  }
  
  WageCategory copyWith({
    String? id,
    String? name,
    double? amount,
  }) {
    return WageCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WageCategory && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
