/// Represents a single financial transaction.
///
/// Covers income, expense, transfer, loan, lending and balance adjustments.
class TransactionModel {
  final int? id;
  final int userId;
  final int accountId;
  final int? toAccountId; // for transfers
  final int? categoryId;
  final String type; // income, expense, transfer, loan, lend, balance_adjust
  final double amount;
  final String? note;
  final DateTime date;
  final String? time;
  final int? loanId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields (not stored, populated by DAO queries)
  final String? accountName;
  final String? toAccountName;
  final String? categoryName;
  final String? categoryIconName;

  const TransactionModel({
    this.id,
    required this.userId,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    required this.type,
    required this.amount,
    this.note,
    required this.date,
    this.time,
    this.loanId,
    required this.createdAt,
    required this.updatedAt,
    this.accountName,
    this.toAccountName,
    this.categoryName,
    this.categoryIconName,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      accountId: map['account_id'] as int,
      toAccountId: map['to_account_id'] as int?,
      categoryId: map['category_id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      time: map['time'] as String?,
      loanId: map['loan_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      // Joined fields
      accountName: map['account_name'] as String?,
      toAccountName: map['to_account_name'] as String?,
      categoryName: map['category_name'] as String?,
      categoryIconName: map['category_icon_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'account_id': accountId,
      'to_account_id': toAccountId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String().split('T').first,
      'time': time,
      'loan_id': loanId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    int? id,
    int? userId,
    int? accountId,
    int? toAccountId,
    int? categoryId,
    String? type,
    double? amount,
    String? note,
    DateTime? date,
    String? time,
    int? loanId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      time: time ?? this.time,
      loanId: loanId ?? this.loanId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Whether the amount should be shown as negative.
  bool get isNegative => type == 'expense' || type == 'loan';

  /// Display amount with correct sign.
  double get signedAmount => isNegative ? -amount : amount;

  @override
  String toString() =>
      'Transaction(id: $id, type: $type, amount: $amount, date: $date)';
}
