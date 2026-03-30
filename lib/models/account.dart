/// Represents a financial account (Ví, Ngân hàng, Tiết kiệm, …).
class Account {
  final int? id;
  final int userId;
  final String name;
  final String type; // cash, bank, e_wallet, savings, credit_card, other
  final double balance;
  final String currency;
  final String? iconName;
  final String? color;
  final bool isIncludedInTotal;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Account({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.balance = 0,
    this.currency = 'VND',
    this.iconName,
    this.color,
    this.isIncludedInTotal = true,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      balance: (map['balance'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'VND',
      iconName: map['icon_name'] as String?,
      color: map['color'] as String?,
      isIncludedInTotal: (map['is_included_in_total'] as int?) == 1,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'icon_name': iconName,
      'color': color,
      'is_included_in_total': isIncludedInTotal ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Account copyWith({
    int? id,
    int? userId,
    String? name,
    String? type,
    double? balance,
    String? currency,
    String? iconName,
    String? color,
    bool? isIncludedInTotal,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      isIncludedInTotal: isIncludedInTotal ?? this.isIncludedInTotal,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Account(id: $id, name: $name, type: $type, balance: $balance)';
}
