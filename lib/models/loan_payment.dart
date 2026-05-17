class LoanPayment {
  final int? id;
  final int loanId;
  final int userId;
  final int? transactionId;
  final double amount;
  final DateTime paymentDate;
  final String? note;
  final DateTime createdAt;

  const LoanPayment({
    this.id,
    required this.loanId,
    required this.userId,
    this.transactionId,
    required this.amount,
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
      paymentDate: paymentDate ?? this.paymentDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
