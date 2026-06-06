import '../models/loan.dart';

class LoanSummaryBuilder {
  const LoanSummaryBuilder._();

  static Map<String, dynamic> build(List<Loan> loans) {
    final activeLoans = loans.where((loan) => !loan.isPaid).toList();
    final borrowed = activeLoans.where((loan) => loan.type == 'borrow');
    final lent = activeLoans.where((loan) => loan.type == 'lend');

    final borrowedPrincipalRemaining = borrowed.fold<double>(
      0,
      (sum, loan) => sum + loan.principalRemaining,
    );
    final borrowedInterestOutstanding = borrowed.fold<double>(
      0,
      (sum, loan) => sum + loan.interestOutstanding,
    );
    final lentPrincipalRemaining = lent.fold<double>(
      0,
      (sum, loan) => sum + loan.principalRemaining,
    );
    final lentInterestOutstanding = lent.fold<double>(
      0,
      (sum, loan) => sum + loan.interestOutstanding,
    );

    return {
      'borrowedRemaining':
          borrowedPrincipalRemaining + borrowedInterestOutstanding,
      'lentRemaining': lentPrincipalRemaining + lentInterestOutstanding,
      'borrowedPrincipalRemaining': borrowedPrincipalRemaining,
      'borrowedInterestOutstanding': borrowedInterestOutstanding,
      'borrowedTotalOutstanding':
          borrowedPrincipalRemaining + borrowedInterestOutstanding,
      'lentPrincipalRemaining': lentPrincipalRemaining,
      'lentInterestOutstanding': lentInterestOutstanding,
      'lentTotalOutstanding': lentPrincipalRemaining + lentInterestOutstanding,
      'overdueCount': activeLoans.where((loan) => loan.isOverdue).length,
    };
  }
}
