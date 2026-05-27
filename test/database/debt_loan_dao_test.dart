import 'package:coin_nest/database/loan_dao.dart';
import 'package:coin_nest/models/loan.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/debt_database_fixture.dart';
import '../helpers/debt_ffi_database.dart';

void main() {
  late DebtDatabaseFixture fixture;
  late LoanDao loanDao;

  Loan newLoan({
    int? id,
    String type = 'borrow',
    String personName = 'Alice',
    double amount = 500,
    double remainingAmount = 500,
    DateTime? startDate,
  }) {
    final now = DateTime(2026, 5, 24, 8);
    return Loan(
      id: id,
      userId: fixture.userId,
      type: type,
      personName: personName,
      amount: amount,
      remainingAmount: remainingAmount,
      startDate: startDate ?? DateTime(2026, 5, 20),
      accountId: fixture.accountId,
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() async {
    fixture = await openFfiDebtDatabaseFixture(initialBalance: 1000);
    loanDao = LoanDao();
  });

  tearDown(() async {
    await fixture.dispose();
  });

  test('tạo khoản vay kèm giao dịch thu ban đầu', () async {
    final loanId = await loanDao.insertWithInitialTransaction(
      loan: newLoan(type: 'borrow', amount: 500, remainingAmount: 500),
      categoryId: fixture.borrowInitialCategoryId,
    );

    final saved = await loanDao.findByIdForUser(loanId, fixture.userId);
    final txns = await fixture.transactionsForLoan(loanId);

    expect(saved, isNotNull);
    expect(saved!.transactionId, isNotNull);
    expect(saved.remainingAmount, 500);
    expect(saved.accountName, 'Test Cash');
    expect(await fixture.accountBalance(), 1500);
    expect(txns, hasLength(1));
    expect(txns.single['type'], 'loan');
    expect(txns.single['category_id'], fixture.borrowInitialCategoryId);
    expect((await loanDao.getSummary(fixture.userId))['borrowed'], 500);
  });

  test('tạo khoản cho vay kèm giao dịch chi ban đầu', () async {
    final loanId = await loanDao.insertWithInitialTransaction(
      loan: newLoan(
        type: 'lend',
        personName: 'Bob',
        amount: 300,
        remainingAmount: 300,
      ),
      categoryId: fixture.lendInitialCategoryId,
    );

    final txns = await fixture.transactionsForLoan(loanId);

    expect(await fixture.accountBalance(), 700);
    expect(txns.single['type'], 'lend');
    expect(txns.single['category_id'], fixture.lendInitialCategoryId);
    expect((await loanDao.getSummary(fixture.userId))['lent'], 300);
  });

  test('ghi nhận trả nợ cập nhật dư nợ lịch sử và số dư tài khoản', () async {
    final loanId = await loanDao.insertWithInitialTransaction(
      loan: newLoan(amount: 500, remainingAmount: 500),
      categoryId: fixture.borrowInitialCategoryId,
    );

    await loanDao.recordPaymentWithTransaction(
      loanId: loanId,
      userId: fixture.userId,
      amount: 200,
      paymentDate: DateTime(2026, 5, 21),
      note: 'partial',
      accountId: fixture.accountId!,
      categoryId: fixture.borrowPaymentCategoryId,
    );

    final saved = await loanDao.findByIdForUser(loanId, fixture.userId);
    final history = await loanDao.getPaymentHistory(loanId, fixture.userId);
    final txns = await fixture.transactionsForLoan(loanId);

    expect(saved!.remainingAmount, 300);
    expect(saved.status, 'active');
    expect(history, hasLength(1));
    expect(history.single.amount, 200);
    expect(txns, hasLength(2));
    expect(txns.last['type'], 'expense');
    expect(txns.last['category_id'], fixture.borrowPaymentCategoryId);
    expect(await fixture.accountBalance(), 1300);
  });

  test('cập nhật khoản vay đồng bộ giao dịch ban đầu và thanh toán', () async {
    final loanId = await loanDao.insertWithInitialTransaction(
      loan: newLoan(amount: 500, remainingAmount: 500),
      categoryId: fixture.borrowInitialCategoryId,
    );
    await loanDao.recordPaymentWithTransaction(
      loanId: loanId,
      userId: fixture.userId,
      amount: 100,
      paymentDate: DateTime(2026, 5, 21),
      accountId: fixture.accountId!,
      categoryId: fixture.borrowPaymentCategoryId,
    );

    await loanDao.updateLoanWithTransactions(
      loan: newLoan(id: loanId, amount: 700, remainingAmount: 700),
      userId: fixture.userId,
      initialCategoryId: fixture.borrowInitialCategoryId,
      paymentCategoryId: fixture.borrowPaymentCategoryId,
    );

    final saved = await loanDao.findByIdForUser(loanId, fixture.userId);
    final txns = await fixture.transactionsForLoan(loanId);

    expect(saved!.amount, 700);
    expect(saved.remainingAmount, 600);
    expect(txns.first['amount'], 700);
    expect(txns.last['amount'], 100);
    expect(await fixture.accountBalance(), 1600);
  });

  test('xóa khoản vay hoàn tác lịch sử và khôi phục số dư tài khoản', () async {
    final loanId = await loanDao.insertWithInitialTransaction(
      loan: newLoan(amount: 500, remainingAmount: 500),
      categoryId: fixture.borrowInitialCategoryId,
    );
    await loanDao.recordPaymentWithTransaction(
      loanId: loanId,
      userId: fixture.userId,
      amount: 200,
      paymentDate: DateTime(2026, 5, 21),
      accountId: fixture.accountId!,
      categoryId: fixture.borrowPaymentCategoryId,
    );

    final deleted = await loanDao.deleteForUserWithRollback(
      loanId,
      fixture.userId,
    );

    expect(deleted, 1);
    expect(await loanDao.findByIdForUser(loanId, fixture.userId), isNull);
    expect(await fixture.transactionCount(), 0);
    expect(await fixture.paymentCount(), 0);
    expect(await fixture.accountBalance(), 1000);
  });

  test('tổng hợp dư nợ đang hoạt động của khoản vay và cho vay', () async {
    await loanDao.insertWithInitialTransaction(
      loan: newLoan(amount: 500, remainingAmount: 500),
      categoryId: fixture.borrowInitialCategoryId,
    );
    await loanDao.insertWithInitialTransaction(
      loan: newLoan(
        type: 'lend',
        personName: 'Bob',
        amount: 300,
        remainingAmount: 300,
      ),
      categoryId: fixture.lendInitialCategoryId,
    );

    final summary = await loanDao.getSummary(fixture.userId);

    expect(summary['borrowed'], 500);
    expect(summary['lent'], 300);
    expect(await fixture.accountBalance(), 1200);
  });
}
