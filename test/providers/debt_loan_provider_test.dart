import 'package:coin_nest/providers/loan_provider.dart';
import 'package:coin_nest/providers/transaction_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/debt_database_fixture.dart';
import '../helpers/debt_ffi_database.dart';

void main() {
  late DebtDatabaseFixture fixture;
  late LoanProvider loanProvider;
  late TransactionProvider transactionProvider;

  // Fixture và provider mới cho từng case giúp kiểm tra orchestration không rò state.
  setUp(() async {
    fixture = await openFfiDebtDatabaseFixture(initialBalance: 1000);
    transactionProvider = TransactionProvider();
    loanProvider = LoanProvider()
      ..setTransactionProvider(transactionProvider);
  });

  tearDown(() async {
    await fixture.dispose();
  });

  // Provider phải chặn dữ liệu đầu vào trước khi DAO tạo loan hoặc transaction.
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

  // Tạo khoản vay hợp lệ phải gán category khởi tạo và reload cả loan/transaction.
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

  // Trả nợ qua provider phải dùng category chi tiền và phản ánh dư nợ mới.
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

  // Khoản trả vượt remaining không được tạo payment hay làm thay đổi balance.
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

  // Provider chặn khoảng thời gian vô hiệu trước khi chạm tới dữ liệu lưu trữ.
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

  // Xóa thành công phải reload state quan sát được và khôi phục balance ban đầu.
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

  // Thu đủ tiền cho vay phải chọn category tiền vào và tất toán state provider.
  test('thu hết khoản cho vay tải lại trạng thái danh mục và số dư', () async {
    await loanProvider.addLoan(
      userId: fixture.userId,
      type: 'lend',
      personName: 'Bob',
      amount: 300,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      accountId: fixture.accountId,
    );
    final loanId = loanProvider.loans.single.id!;

    final success = await loanProvider.recordPayment(
      loanId,
      300,
      fixture.userId,
      paymentDate: DateTime.now(),
      accountId: fixture.accountId,
    );

    expect(success, isTrue);
    expect(loanProvider.loans.single.status, 'paid');
    expect(loanProvider.loans.single.remainingAmount, 0);
    expect(loanProvider.summary['lent'], 0);
    expect(transactionProvider.transactions.first.type, 'income');
    expect(
      transactionProvider.transactions.first.categoryId,
      fixture.lendPaymentCategoryId,
    );
    expect(await fixture.accountBalance(), 1000);
  });

  // Các điều kiện thanh toán sai tài khoản/thời gian đều không được tạo lịch sử.
  test('thanh toán từ chối tài khoản không hợp lệ và ngày ngoài phạm vi', () async {
    final startDate = DateTime.now().subtract(const Duration(days: 2));
    await loanProvider.addLoan(
      userId: fixture.userId,
      type: 'borrow',
      personName: 'Alice',
      amount: 500,
      startDate: startDate,
      accountId: fixture.accountId,
    );
    final loanId = loanProvider.loans.single.id!;

    expect(
      await loanProvider.recordPayment(
        loanId,
        100,
        fixture.userId,
        paymentDate: DateTime.now(),
        accountId: -1,
      ),
      isFalse,
    );
    expect(loanProvider.errorMessage, contains('Invalid account'));

    expect(
      await loanProvider.recordPayment(
        loanId,
        100,
        fixture.userId,
        paymentDate: startDate.subtract(const Duration(days: 1)),
        accountId: fixture.accountId,
      ),
      isFalse,
    );
    expect(loanProvider.errorMessage, contains('before loan start'));

    expect(
      await loanProvider.recordPayment(
        loanId,
        100,
        fixture.userId,
        paymentDate: DateTime.now().add(const Duration(days: 1)),
        accountId: fixture.accountId,
      ),
      isFalse,
    );
    expect(loanProvider.errorMessage, contains('future'));
    expect(await fixture.paymentCount(), 0);
  });

  // Khoản đã paid không được nhận thêm payment dù số tiền rất nhỏ.
  test('thanh toán từ chối khoản đã được trả hết', () async {
    await loanProvider.addLoan(
      userId: fixture.userId,
      type: 'borrow',
      personName: 'Alice',
      amount: 500,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      accountId: fixture.accountId,
    );
    final loanId = loanProvider.loans.single.id!;
    await loanProvider.recordPayment(
      loanId,
      500,
      fixture.userId,
      paymentDate: DateTime.now(),
      accountId: fixture.accountId,
    );

    final success = await loanProvider.recordPayment(
      loanId,
      1,
      fixture.userId,
      paymentDate: DateTime.now(),
      accountId: fixture.accountId,
    );

    expect(success, isFalse);
    expect(loanProvider.errorMessage, contains('already been paid'));
    expect(await fixture.paymentCount(), 1);
  });

  // Không cho sửa principal thấp hơn số đã thanh toán để tránh remaining âm.
  test('cập nhật từ chối giảm số tiền thấp hơn tổng tiền đã trả', () async {
    final startDate = DateTime.now().subtract(const Duration(days: 2));
    await loanProvider.addLoan(
      userId: fixture.userId,
      type: 'borrow',
      personName: 'Alice',
      amount: 500,
      startDate: startDate,
      accountId: fixture.accountId,
    );
    final loanId = loanProvider.loans.single.id!;
    await loanProvider.recordPayment(
      loanId,
      200,
      fixture.userId,
      paymentDate: DateTime.now().subtract(const Duration(days: 1)),
      accountId: fixture.accountId,
    );

    final success = await loanProvider.updateLoan(
      loanId: loanId,
      userId: fixture.userId,
      type: 'borrow',
      personName: 'Alice',
      amount: 100,
      startDate: startDate,
      accountId: fixture.accountId!,
    );

    expect(success, isFalse);
    expect(loanProvider.errorMessage, contains('thấp hơn tổng số tiền'));
    expect(loanProvider.loans.single.amount, 500);
  });

  // Màn giao dịch có thể tra loan bằng khóa trực tiếp hoặc transaction ban đầu.
  test('tìm khoản vay liên kết theo loan id và transaction id', () async {
    await loanProvider.addLoan(
      userId: fixture.userId,
      type: 'borrow',
      personName: 'Alice',
      amount: 500,
      startDate: DateTime.now(),
      accountId: fixture.accountId,
    );
    final loan = loanProvider.loans.single;
    final transactionId = loan.transactionId!;

    expect(
      (await loanProvider.findLoanForTransaction(
        userId: fixture.userId,
        loanId: loan.id,
      ))
          ?.id,
      loan.id,
    );
    expect(
      (await loanProvider.findLoanForTransaction(
        userId: fixture.userId,
        transactionId: transactionId,
      ))
          ?.id,
      loan.id,
    );
    expect(
      await loanProvider.findLoanForTransaction(userId: fixture.userId),
      isNull,
    );
  });

  // Provider phải giữ cách ly dữ liệu: user khác không thao tác được loan đã seed.
  test('user khác không thể thanh toán hoặc cập nhật khoản vay', () async {
    await loanProvider.addLoan(
      userId: fixture.userId,
      type: 'borrow',
      personName: 'Alice',
      amount: 500,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      accountId: fixture.accountId,
    );
    final loanId = loanProvider.loans.single.id!;
    final otherUserId = await fixture.insertOtherUser();

    expect(
      await loanProvider.recordPayment(
        loanId,
        100,
        otherUserId,
        paymentDate: DateTime.now(),
        accountId: fixture.accountId,
      ),
      isFalse,
    );
    expect(loanProvider.errorMessage, contains('Loan not found'));

    expect(
      await loanProvider.updateLoan(
        loanId: loanId,
        userId: otherUserId,
        type: 'borrow',
        personName: 'Alice',
        amount: 700,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        accountId: fixture.accountId!,
      ),
      isFalse,
    );
    expect(loanProvider.errorMessage, contains('Loan not found'));

    await loanProvider.loadLoans(fixture.userId);
    expect(loanProvider.loans.single.amount, 500);
    expect(await fixture.paymentCount(), 0);
  });
}
