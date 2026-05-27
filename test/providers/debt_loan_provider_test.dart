import 'package:coin_nest/providers/loan_provider.dart';
import 'package:coin_nest/providers/transaction_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/debt_database_fixture.dart';
import '../helpers/debt_ffi_database.dart';

void main() {
  late DebtDatabaseFixture fixture;
  late LoanProvider loanProvider;
  late TransactionProvider transactionProvider;

  setUp(() async {
    fixture = await openFfiDebtDatabaseFixture(initialBalance: 1000);
    transactionProvider = TransactionProvider();
    loanProvider = LoanProvider()
      ..setTransactionProvider(transactionProvider);
  });

  tearDown(() async {
    await fixture.dispose();
  });

  test('thêm khoản vay từ chối số tiền không hợp lệ và hiển thị lỗi', () async {
    final success = await loanProvider.addLoan(
      userId: fixture.userId,
      type: 'borrow',
      personName: 'Alice',
      amount: 0,
      startDate: DateTime.now(),
      accountId: fixture.accountId,
    );

    expect(success, isFalse);
    expect(loanProvider.errorMessage, contains('Amount'));
    expect(loanProvider.loans, isEmpty);
  });

  test('thêm khoản vay gán danh mục mặc định và tải lại dữ liệu liên quan', () async {
    final success = await loanProvider.addLoan(
      userId: fixture.userId,
      type: 'borrow',
      personName: 'Alice',
      amount: 500,
      startDate: DateTime.now(),
      accountId: fixture.accountId,
    );

    expect(success, isTrue);
    expect(loanProvider.loans, hasLength(1));
    expect(loanProvider.summary['borrowed'], 500);
    expect(transactionProvider.transactions, hasLength(1));
    expect(
      transactionProvider.transactions.single.categoryId,
      fixture.borrowInitialCategoryId,
    );
    expect(await fixture.accountBalance(), 1500);
  });

  test('ghi nhận trả nợ gán danh mục thanh toán và tải lại dữ liệu', () async {
    await loanProvider.addLoan(
      userId: fixture.userId,
      type: 'borrow',
      personName: 'Alice',
      amount: 500,
      startDate: DateTime.now(),
      accountId: fixture.accountId,
    );
    final loanId = loanProvider.loans.single.id!;

    final success = await loanProvider.recordPayment(
      loanId,
      200,
      fixture.userId,
      paymentDate: DateTime.now(),
      accountId: fixture.accountId,
    );

    expect(success, isTrue);
    expect(loanProvider.loans.single.remainingAmount, 300);
    expect(transactionProvider.transactions, hasLength(2));
    expect(transactionProvider.transactions.first.type, 'expense');
    expect(
      transactionProvider.transactions.first.categoryId,
      fixture.borrowPaymentCategoryId,
    );
    expect(await fixture.accountBalance(), 1300);
  });

  test('ghi nhận trả nợ từ chối số tiền vượt dư nợ còn lại', () async {
    await loanProvider.addLoan(
      userId: fixture.userId,
      type: 'borrow',
      personName: 'Alice',
      amount: 500,
      startDate: DateTime.now(),
      accountId: fixture.accountId,
    );
    final loanId = loanProvider.loans.single.id!;

    final success = await loanProvider.recordPayment(
      loanId,
      600,
      fixture.userId,
      paymentDate: DateTime.now(),
      accountId: fixture.accountId,
    );

    expect(success, isFalse);
    expect(loanProvider.errorMessage, contains('exceeds remaining'));
    expect(loanProvider.loans.single.remainingAmount, 500);
    expect(await fixture.paymentCount(), 0);
    expect(await fixture.accountBalance(), 1500);
  });

  test('cập nhật khoản vay từ chối hạn trả trước ngày bắt đầu', () async {
    final startDate = DateTime.now();
    final success = await loanProvider.updateLoan(
      loanId: 999,
      userId: fixture.userId,
      type: 'borrow',
      personName: 'Alice',
      amount: 500,
      startDate: startDate,
      dueDate: startDate.subtract(const Duration(days: 1)),
      accountId: fixture.accountId!,
    );

    expect(success, isFalse);
    expect(loanProvider.errorMessage, contains('dueDate'));
    expect(await fixture.transactionCount(), 0);
  });

  test('xóa khoản vay hoàn tác giao dịch và tải lại dữ liệu', () async {
    await loanProvider.addLoan(
      userId: fixture.userId,
      type: 'borrow',
      personName: 'Alice',
      amount: 500,
      startDate: DateTime.now(),
      accountId: fixture.accountId,
    );
    final loanId = loanProvider.loans.single.id!;
    await loanProvider.recordPayment(
      loanId,
      200,
      fixture.userId,
      paymentDate: DateTime.now(),
      accountId: fixture.accountId,
    );

    final success = await loanProvider.deleteLoan(loanId, fixture.userId);

    expect(success, isTrue);
    expect(loanProvider.loans, isEmpty);
    expect(transactionProvider.transactions, isEmpty);
    expect(await fixture.accountBalance(), 1000);
  });
}
