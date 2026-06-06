class LoanPayment {
  final int? id;
  final int loanId;
  final int userId;
  final int? transactionId;
  final double amount;
  final double principalAmount;
  final double interestAmount;
  final DateTime paymentDate;
  final String? note;
  final DateTime createdAt;

  const LoanPayment({
    this.id,
    required this.loanId,
    required this.userId,
    this.transactionId,
    required this.amount,
    this.principalAmount = 0,
    this.interestAmount = 0,
    required this.paymentDate,
    this.note,
    required this.createdAt,
  });

  factory LoanPayment.fromMap(Map<String, dynamic> map) {
    return LoanPayment(
      id: map['id'] as int?,
      loanId: map['loan_id'] as int,
      userId: map['user_id'] as int,
      transactionId: map['transaction_id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      principalAmount:
          (map['principal_amount'] as num?)?.toDouble() ??
          (map['amount'] as num).toDouble(),
      interestAmount: (map['interest_amount'] as num?)?.toDouble() ?? 0,
      paymentDate: DateTime.parse(map['payment_date'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'loan_id': loanId,
      'user_id': userId,
      'transaction_id': transactionId,
      'amount': amount,
      'principal_amount': principalAmount == 0 && interestAmount == 0
          ? amount
          : principalAmount,
      'interest_amount': interestAmount,
      'payment_date': paymentDate.toIso8601String().split('T').first,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LoanPayment copyWith({
    int? id,
    int? loanId,
    int? userId,
    int? transactionId,
    double? amount,
    double? principalAmount,
    double? interestAmount,
    DateTime? paymentDate,
    String? note,
    DateTime? createdAt,
  }) {
    return LoanPayment(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      userId: userId ?? this.userId,
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      principalAmount: principalAmount ?? this.principalAmount,
      interestAmount: interestAmount ?? this.interestAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
