/// Represents a spending budget / limit (hạn mức chi).
class Budget {
  final int? id;
  final int userId;
  final int? categoryId;
  final int? accountId; // ĐÃ THÊM: Lưu ID tài khoản
  final String name;
  final double amount;
  final String period; // daily, weekly, monthly, yearly, custom
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed (populated by DAO)
  final double? spentAmount;
  final String? categoryName;
  final String? categoryIconName;
  final String? accountName; // ĐÃ THÊM: Lưu tên tài khoản khi query

  const Budget({
    this.id,
    required this.userId,
    this.categoryId,
    this.accountId, // ĐÃ THÊM
    required this.name,
    required this.amount,
    this.period = 'monthly',
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.spentAmount,
    this.categoryName,
    this.categoryIconName,
    this.accountName, // ĐÃ THÊM
  });

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      categoryId: map['category_id'] as int?,
      accountId: map['account_id'] as int?, // ĐÃ THÊM: Lấy dữ liệu từ DB
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      period: map['period'] as String? ?? 'monthly',
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      spentAmount: (map['spent_amount'] as num?)?.toDouble(),
      categoryName: map['category_name'] as String?,
      categoryIconName: map['category_icon_name'] as String?,
      accountName: map['account_name'] as String?, // ĐÃ THÊM
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'account_id': accountId, // ĐÃ THÊM: Đẩy dữ liệu vào DB
      'name': name,
      'amount': amount,
      'period': period,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Budget copyWith({
    int? id,
    int? userId,
    int? categoryId,
    int? accountId, // ĐÃ THÊM
    String? name,
    double? amount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? spentAmount,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId, // ĐÃ THÊM
      name: name ?? this.name,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      spentAmount: spentAmount ?? this.spentAmount,
    );
  }

  /// Remaining budget.
  double get remainingAmount => amount - (spentAmount ?? 0);

  /// Usage percentage (0–100+). Can exceed 100 if overspent.
  double get usagePercent {
    if (amount == 0) return 0;
    return ((spentAmount ?? 0) / amount * 100);
  }

  /// Whether the budget has been exceeded.
  bool get isExceeded => (spentAmount ?? 0) >= amount;

  @override
  String toString() =>
      'Budget(id: $id, name: $name, amount: $amount, accountId: $accountId)';
}
