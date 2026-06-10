import 'package:coin_nest/models/loan.dart';
import 'package:coin_nest/models/loan_payment.dart';
import 'package:coin_nest/models/transaction_model.dart';
import 'package:coin_nest/utils/loan_interest_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Kiểm tra các thuộc tính suy diễn từ dữ liệu khoản vay, vì màn hình và
  // báo cáo dùng trực tiếp các giá trị này để hiển thị trạng thái.
  group('Tiện ích khoản vay', () {
    // Tạo khoản vay tối thiểu để mỗi case chỉ thay đổi dữ kiện cần kiểm tra.
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

    // Phần trăm tiến độ phải nằm trong miền hiển thị hợp lệ kể cả dữ liệu biên.
    test('phần trăm đã trả được giới hạn hợp lệ và xử lý số tiền bằng 0', () {
      expect(loan(amount: 1000, remainingAmount: 750).paidPercentage, 25);
      expect(loan(amount: 1000, remainingAmount: -100).paidPercentage, 100);
      expect(loan(amount: 0, remainingAmount: 0).paidPercentage, 0);
    });

    // Một khoản được xem là tất toán theo trạng thái lưu hoặc khi dư nợ về 0.
    test('trạng thái đã trả dựa trên trạng thái hoặc dư nợ còn lại', () {
      expect(loan(status: 'paid', remainingAmount: 10).isPaid, isTrue);
      expect(loan(status: 'active', remainingAmount: 0).isPaid, isTrue);
      expect(loan(status: 'active', remainingAmount: 1).isPaid, isFalse);
    });

    // Cảnh báo quá hạn không được xuất hiện cho khoản đã tất toán hoặc không có hạn.
    test('quá hạn chỉ áp dụng cho khoản đang hoạt động sau hạn trả', () {
      expect(
        loan(
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        ).isOverdue,
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

  // Kiểm tra semantic của giao dịch debt để sign và liên kết loan nhất quán.
  group('Tính lãi đơn khoản vay', () {
    Loan loan() {
      final now = DateTime(2026, 1, 1);
      return Loan(
        userId: 1,
        type: 'borrow',
        personName: 'Alice',
        amount: 365000,
        remainingAmount: 365000,
        interestRate: 10,
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('lãi phát sinh theo ngày trên gốc còn lại', () {
      final breakdown = LoanInterestCalculator.calculate(
        loan: loan(),
        payments: const [],
        asOf: DateTime(2026, 1, 11),
      );

      expect(breakdown.interestAccrued, closeTo(1000, 0.01));
      expect(breakdown.interestOutstanding, closeTo(1000, 0.01));
      expect(breakdown.totalOutstanding, closeTo(366000, 0.01));
    });

    test('thanh toán ưu tiên trừ lãi trước rồi mới trừ gốc', () {
      final beforePayment = LoanInterestCalculator.calculate(
        loan: loan(),
        payments: const [],
        asOf: DateTime(2026, 1, 11),
      );
      final allocation = LoanInterestCalculator.allocatePayment(
        amount: 1200,
        breakdown: beforePayment,
      );
      final afterPayment = LoanInterestCalculator.calculate(
        loan: loan(),
        payments: [
          LoanPayment(
            loanId: 1,
            userId: 1,
            amount: 1200,
            principalAmount: allocation.principalAmount,
            interestAmount: allocation.interestAmount,
            paymentDate: DateTime(2026, 1, 11),
            createdAt: DateTime(2026, 1, 11, 8),
          ),
        ],
        asOf: DateTime(2026, 1, 21),
      );

      expect(allocation.interestAmount, closeTo(1000, 0.01));
      expect(allocation.principalAmount, closeTo(200, 0.01));
      expect(afterPayment.principalRemaining, closeTo(364800, 0.01));
      expect(afterPayment.interestPaid, closeTo(1000, 0.01));
      expect(afterPayment.interestOutstanding, closeTo(999.45, 0.01));
    });
  });

  group('Tiện ích giao dịch vay và cho vay', () {
    // Dựng giao dịch tối thiểu để cô lập logic phân loại khỏi dữ liệu DB.
    TransactionModel transaction({String type = 'income', int? loanId}) {
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

    // Transaction debt hoặc transaction có loanId đều phải mở được ngữ cảnh loan.
    test('nhận diện giao dịch liên kết với khoản vay', () {
      expect(transaction(type: 'loan').isLoanLinked, isTrue);
      expect(transaction(type: 'lend').isLoanLinked, isTrue);
      expect(transaction(type: 'income', loanId: 10).isLoanLinked, isTrue);
      expect(transaction(type: 'income').isLoanLinked, isFalse);
    });

    // Cho vay là tiền đi, còn nhận tiền vay là tiền vào trên số dư tài khoản.
    test('giao dịch cho vay được biểu diễn là dòng tiền đi', () {
      expect(transaction(type: 'expense').isNegative, isTrue);
      expect(transaction(type: 'lend').isNegative, isTrue);
      expect(transaction(type: 'loan').isNegative, isFalse);
      expect(transaction(type: 'lend').signedAmount, -100);
      expect(transaction(type: 'loan').signedAmount, 100);
    });
  });
}
