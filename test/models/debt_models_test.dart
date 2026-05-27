import 'package:coin_nest/models/loan.dart';
import 'package:coin_nest/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tiện ích khoản vay', () {
    Loan loan({
      double amount = 1000,
      double remainingAmount = 1000,
      String status = 'active',
      DateTime? dueDate,
    }) {
      final now = DateTime(2026, 5, 24);
      return Loan(
        userId: 1,
        type: 'borrow',
        personName: 'Alice',
        amount: amount,
        remainingAmount: remainingAmount,
        startDate: DateTime(2026, 5, 1),
        dueDate: dueDate,
        status: status,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('phần trăm đã trả được giới hạn hợp lệ và xử lý số tiền bằng 0', () {
      expect(loan(amount: 1000, remainingAmount: 750).paidPercentage, 25);
      expect(loan(amount: 1000, remainingAmount: -100).paidPercentage, 100);
      expect(loan(amount: 0, remainingAmount: 0).paidPercentage, 0);
    });

    test('trạng thái đã trả dựa trên trạng thái hoặc dư nợ còn lại', () {
      expect(loan(status: 'paid', remainingAmount: 10).isPaid, isTrue);
      expect(loan(status: 'active', remainingAmount: 0).isPaid, isTrue);
      expect(loan(status: 'active', remainingAmount: 1).isPaid, isFalse);
    });

    test('quá hạn chỉ áp dụng cho khoản đang hoạt động sau hạn trả', () {
      expect(
        loan(dueDate: DateTime.now().subtract(const Duration(days: 1))).isOverdue,
        isTrue,
      );
      expect(
        loan(
          status: 'paid',
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        ).isOverdue,
        isFalse,
      );
      expect(loan(dueDate: null).isOverdue, isFalse);
    });
  });

  group('Tiện ích giao dịch vay và cho vay', () {
    TransactionModel transaction({
      String type = 'income',
      int? loanId,
    }) {
      final now = DateTime(2026, 5, 24);
      return TransactionModel(
        userId: 1,
        accountId: 1,
        type: type,
        amount: 100,
        loanId: loanId,
        date: now,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('nhận diện giao dịch liên kết với khoản vay', () {
      expect(transaction(type: 'loan').isLoanLinked, isTrue);
      expect(transaction(type: 'lend').isLoanLinked, isTrue);
      expect(transaction(type: 'income', loanId: 10).isLoanLinked, isTrue);
      expect(transaction(type: 'income').isLoanLinked, isFalse);
    });

    test('giao dịch cho vay được biểu diễn là dòng tiền đi', () {
      expect(transaction(type: 'expense').isNegative, isTrue);
      expect(transaction(type: 'lend').isNegative, isTrue);
      expect(transaction(type: 'loan').isNegative, isFalse);
      expect(transaction(type: 'lend').signedAmount, -100);
      expect(transaction(type: 'loan').signedAmount, 100);
    });
  });
}
