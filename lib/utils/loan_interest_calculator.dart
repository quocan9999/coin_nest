import '../models/loan.dart';
import '../models/loan_payment.dart';

class LoanInterestBreakdown {
  const LoanInterestBreakdown({
    required this.principalAmount,
    required this.principalRemaining,
    required this.interestAccrued,
    required this.interestPaid,
    required this.interestOutstanding,
  });

  final double principalAmount;
  final double principalRemaining;
  final double interestAccrued;
  final double interestPaid;
  final double interestOutstanding;

  double get principalPaid => principalAmount - principalRemaining;
  double get totalPaid => principalPaid + interestPaid;
  double get totalOutstanding => principalRemaining + interestOutstanding;
}

class LoanPaymentAllocation {
  const LoanPaymentAllocation({
    required this.amount,
    required this.principalAmount,
    required this.interestAmount,
  });

  final double amount;
  final double principalAmount;
  final double interestAmount;
}

class LoanInterestCalculator {
  const LoanInterestCalculator._();

  static LoanInterestBreakdown calculate({
    required Loan loan,
    required List<LoanPayment> payments,
    DateTime? asOf,
  }) {
    final targetDate = _dateOnly(asOf ?? DateTime.now());
    final sortedPayments = payments.toList()
      ..sort((a, b) {
        final byDate = a.paymentDate.compareTo(b.paymentDate);
        if (byDate != 0) return byDate;
        return a.createdAt.compareTo(b.createdAt);
      });

    var principalRemaining = loan.amount;
    var interestAccrued = 0.0;
    var interestPaid = 0.0;
    var interestOutstanding = 0.0;
    var cursor = _dateOnly(loan.startDate);

    for (final payment in sortedPayments) {
      final paymentDate = _dateOnly(payment.paymentDate);
      if (paymentDate.isAfter(targetDate)) break;

      final accrued = _interestForPeriod(
        principalRemaining,
        loan.interestRate,
        cursor,
        paymentDate,
      );
      interestAccrued += accrued;
      interestOutstanding += accrued;

      final interestAmount = payment.interestAmount > 0
          ? payment.interestAmount
          : payment.amount - payment.principalAmount;
      final principalAmount = payment.principalAmount;

      interestPaid += interestAmount;
      interestOutstanding = (interestOutstanding - interestAmount)
          .clamp(0, double.infinity)
          .toDouble();
      principalRemaining = (principalRemaining - principalAmount)
          .clamp(0, double.infinity)
          .toDouble();
      cursor = paymentDate;
    }

    final trailingInterest = _interestForPeriod(
      principalRemaining,
      loan.interestRate,
      cursor,
      targetDate,
    );
    interestAccrued += trailingInterest;
    interestOutstanding += trailingInterest;

    return LoanInterestBreakdown(
      principalAmount: loan.amount,
      principalRemaining: principalRemaining,
      interestAccrued: interestAccrued,
      interestPaid: interestPaid,
      interestOutstanding: interestOutstanding,
    );
  }

  static LoanPaymentAllocation allocatePayment({
    required double amount,
    required LoanInterestBreakdown breakdown,
  }) {
    final interestAmount = amount <= 0
        ? 0.0
        : amount.clamp(0, breakdown.interestOutstanding).toDouble();
    final principalAmount = (amount - interestAmount)
        .clamp(0, breakdown.principalRemaining)
        .toDouble();

    return LoanPaymentAllocation(
      amount: amount,
      principalAmount: principalAmount,
      interestAmount: interestAmount,
    );
  }

  static double _interestForPeriod(
    double principal,
    double annualRate,
    DateTime start,
    DateTime end,
  ) {
    if (principal <= 0 || annualRate <= 0 || !end.isAfter(start)) return 0;

    final days = end.difference(start).inDays;
    return principal * annualRate / 100 * days / 365;
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
