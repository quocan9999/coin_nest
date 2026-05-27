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
    int? accountId,
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
      accountId: accountId ?? fixture.accountId,
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

  test('trả hết khoản vay chuyển trạng thái đã trả và loại khỏi tổng dư nợ', () async {
    final loanId = await loanDao.insertWithInitialTransaction(
      loan: newLoan(amount: 500, remainingAmount: 500),
      categoryId: fixture.borrowInitialCategoryId,
    );

    await loanDao.recordPaymentWithTransaction(
      loanId: loanId,
      userId: fixture.userId,
      amount: 500,
      paymentDate: DateTime(2026, 5, 21),
      accountId: fixture.accountId!,
      categoryId: fixture.borrowPaymentCategoryId,
    );

    final saved = await loanDao.findByIdForUser(loanId, fixture.userId);
    final summary = await loanDao.getSummary(fixture.userId);

    expect(saved!.status, 'paid');
    expect(saved.remainingAmount, 0);
    expect(summary['borrowed'], 0);
    expect(await fixture.accountBalance(), 1000);
  });

  test('thu hết khoản cho vay tạo giao dịch thu nợ và khôi phục số dư', () async {
    final loanId = await loanDao.insertWithInitialTransaction(
      loan: newLoan(
        type: 'lend',
        personName: 'Bob',
        amount: 300,
        remainingAmount: 300,
      ),
      categoryId: fixture.lendInitialCategoryId,
    );

    await loanDao.recordPaymentWithTransaction(
      loanId: loanId,
      userId: fixture.userId,
      amount: 300,
      paymentDate: DateTime(2026, 5, 21),
      accountId: fixture.accountId!,
      categoryId: fixture.lendPaymentCategoryId,
    );

    final saved = await loanDao.findByIdForUser(loanId, fixture.userId);
    final txns = await fixture.transactionsForLoan(loanId);

    expect(saved!.status, 'paid');
    expect((await loanDao.getSummary(fixture.userId))['lent'], 0);
    expect(txns.last['type'], 'income');
    expect(txns.last['category_id'], fixture.lendPaymentCategoryId);
    expect(await fixture.accountBalance(), 1000);
  });

  test('từ chối thanh toán sai ngày khoản đã trả và user không sở hữu', () async {
    final loanId = await loanDao.insertWithInitialTransaction(
      loan: newLoan(amount: 500, remainingAmount: 500),
      categoryId: fixture.borrowInitialCategoryId,
    );
    final otherUserId = await fixture.insertOtherUser();

    Future<void> pay({
      required int userId,
      required double amount,
      required DateTime date,
    }) {
      return loanDao.recordPaymentWithTransaction(
        loanId: loanId,
        userId: userId,
        amount: amount,
        paymentDate: date,
        accountId: fixture.accountId!,
        categoryId: fixture.borrowPaymentCategoryId,
      );
    }

    await expectLater(
      pay(userId: fixture.userId, amount: 100, date: DateTime(2026, 5, 19)),
      throwsArgumentError,
    );
    await expectLater(
      pay(
        userId: fixture.userId,
        amount: 100,
        date: DateTime.now().add(const Duration(days: 1)),
      ),
      throwsArgumentError,
    );
    await expectLater(
      pay(userId: otherUserId, amount: 100, date: DateTime(2026, 5, 21)),
      throwsStateError,
    );

    await pay(
      userId: fixture.userId,
      amount: 500,
      date: DateTime(2026, 5, 21),
    );
    await expectLater(
      pay(userId: fixture.userId, amount: 1, date: DateTime(2026, 5, 22)),
      throwsStateError,
    );
  });

  test('cập nhật sau thanh toán từ chối số tiền thấp và ngày bắt đầu trễ', () async {
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

    await expectLater(
      loanDao.updateLoanWithTransactions(
        loan: newLoan(id: loanId, amount: 100, remainingAmount: 100),
        userId: fixture.userId,
        initialCategoryId: fixture.borrowInitialCategoryId,
        paymentCategoryId: fixture.borrowPaymentCategoryId,
      ),
      throwsArgumentError,
    );
    await expectLater(
      loanDao.updateLoanWithTransactions(
        loan: newLoan(
          id: loanId,
          amount: 500,
          remainingAmount: 500,
          startDate: DateTime(2026, 5, 22),
        ),
        userId: fixture.userId,
        initialCategoryId: fixture.borrowInitialCategoryId,
        paymentCategoryId: fixture.borrowPaymentCategoryId,
      ),
      throwsArgumentError,
    );
  });

  test('đổi khoản vay thành cho vay ở tài khoản khác đồng bộ toàn bộ dòng tiền', () async {
    final secondAccountId = await fixture.insertAccount(
      name: 'Test Bank',
      balance: 2000,
    );
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
      loan: newLoan(
        id: loanId,
        type: 'lend',
        personName: 'Bob',
        amount: 700,
        remainingAmount: 700,
        accountId: secondAccountId,
      ),
      userId: fixture.userId,
      initialCategoryId: fixture.lendInitialCategoryId,
      paymentCategoryId: fixture.lendPaymentCategoryId,
    );

    final saved = await loanDao.findByIdForUser(loanId, fixture.userId);
    final txns = await fixture.transactionsForLoan(loanId);

    expect(saved!.type, 'lend');
    expect(saved.accountId, secondAccountId);
    expect(saved.remainingAmount, 600);
    expect(txns.map((txn) => txn['type']), ['lend', 'income']);
    expect(await fixture.accountBalance(), 1000);
    expect(await fixture.accountBalanceFor(secondAccountId), 1400);
  });

  test('xóa khoản cho vay đã thu nợ hoàn tác số dư ban đầu', () async {
    final loanId = await loanDao.insertWithInitialTransaction(
      loan: newLoan(
        type: 'lend',
        personName: 'Bob',
        amount: 300,
        remainingAmount: 300,
      ),
      categoryId: fixture.lendInitialCategoryId,
    );
    await loanDao.recordPaymentWithTransaction(
      loanId: loanId,
      userId: fixture.userId,
      amount: 100,
      paymentDate: DateTime(2026, 5, 21),
      accountId: fixture.accountId!,
      categoryId: fixture.lendPaymentCategoryId,
    );

    final deleted = await loanDao.deleteForUserWithRollback(
      loanId,
      fixture.userId,
    );

    expect(deleted, 1);
    expect(await fixture.accountBalance(), 1000);
    expect(await fixture.transactionCount(), 0);
    expect(await fixture.paymentCount(), 0);
  });
}
