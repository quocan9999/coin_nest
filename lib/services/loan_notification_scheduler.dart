import 'package:flutter/foundation.dart';

import '../models/loan.dart';
import 'notification_service.dart';

class LoanNotificationScheduler {
  LoanNotificationScheduler._();

  static Future<void> rescheduleAll(
    List<Loan> loans,
    List<int> daysOffsets,
  ) async {
    try {
      await NotificationService.instance.cancelAllLoanReminders();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final earliestUsefulDueDate = today.subtract(const Duration(days: 1));

      for (final loan in loans) {
        final loanId = loan.id;
        final dueDate = loan.dueDate;

        if (loan.isPaid || loanId == null || dueDate == null) {
          continue;
        }

        final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
        if (dueDay.isBefore(earliestUsefulDueDate)) {
          continue;
        }

        await NotificationService.instance.scheduleLoanReminder(
          loanId: loanId,
          personName: loan.personName,
          remainingAmount: loan.remainingAmount,
          dueDate: dueDate,
          isBorrowed: loan.type == 'borrowed' || loan.type == 'borrow',
          daysOffsets: daysOffsets,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('LoanNotificationScheduler.rescheduleAll failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
