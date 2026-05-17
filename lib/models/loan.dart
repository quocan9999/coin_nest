/// Represents a loan / lending record (vay / cho vay).
class Loan {
  final int? id;
  final int userId;
  final String type; // 'borrow' or 'lend'
  final String personName;
  final double amount;
  final double remainingAmount;
  final double interestRate;
  final String? note;
  final DateTime startDate;
  final DateTime? dueDate;
  final String status; // 'active', 'paid', 'overdue'
  final int? accountId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined field
  final String? accountName;

  const Loan({
    this.id,
    required this.userId,
    required this.type,
    required this.personName,
    required this.amount,
    required this.remainingAmount,
    this.interestRate = 0,
    this.note,
    required this.startDate,
    this.dueDate,
    this.status = 'active',
    this.accountId,
    required this.createdAt,
    required this.updatedAt,
    this.accountName,
  });

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      type: map['type'] as String,
      personName: map['person_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      remainingAmount: (map['remaining_amount'] as num).toDouble(),
      interestRate: (map['interest_rate'] as num?)?.toDouble() ?? 0,
      note: map['note'] as String?,
      startDate: DateTime.parse(map['start_date'] as String),
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      status: map['status'] as String? ?? 'active',
      accountId: map['account_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      accountName: map['account_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'type': type,
      'person_name': personName,
      'amount': amount,
      'remaining_amount': remainingAmount,
      'interest_rate': interestRate,
      'note': note,
      'start_date': startDate.toIso8601String().split('T').first,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'status': status,
      'account_id': accountId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Loan copyWith({
    int? id,
    int? userId,
    String? type,
    String? personName,
    double? amount,
    double? remainingAmount,
    double? interestRate,
    String? note,
    DateTime? startDate,
    DateTime? dueDate,
    String? status,
    int? accountId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Loan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      interestRate: interestRate ?? this.interestRate,
      note: note ?? this.note,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      accountId: accountId ?? this.accountId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Percentage of the loan that has been repaid.
  double get paidPercentage {
    if (amount == 0) return 0;
    return ((amount - remainingAmount) / amount * 100).clamp(0, 100);
  }

  bool get isOverdue =>
      status == 'active' &&
      dueDate != null &&
      DateTime.now().isAfter(dueDate!);

  bool get isPaid => status == 'paid' || remainingAmount <= 0;

  @override
  String toString() =>
      'Loan(id: $id, type: $type, person: $personName, amount: $amount)';
}
