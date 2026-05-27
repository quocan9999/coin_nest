import 'package:coin_nest/database/loan_dao.dart';
import 'package:coin_nest/models/loan.dart';
import 'package:coin_nest/screens/loans/add_edit_loan_screen.dart';
import 'package:coin_nest/screens/loans/loan_detail_screen.dart';
import 'package:coin_nest/screens/loans/payment_screen.dart';
import 'package:coin_nest/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/debt_database_fixture.dart';
import '../../helpers/debt_ffi_database.dart';
import '../../helpers/debt_ffi_widget_harness.dart';
import '../../helpers/debt_widget_harness.dart';

void main() {
  // Kiểm tra form thêm khoản vay thực sự gọi submit và ghi tác động tài chính.
  testWidgets('Màn thêm khoản vay hiển thị biểu mẫu và lưu khoản vay hợp lệ', (
    tester,
  ) async {
    final harness = await pumpDebtWidget(
      tester,
      child: const AddEditLoanScreen(),
      initialBalance: 1000,
    );

    expect(find.text('Vay'), findsOneWidget);
    expect(find.text('Cho vay'), findsOneWidget);
    expect(find.text('Test Cash'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));

    debugDebtStep('thêm khoản vay: nhập người vay và số tiền');
    await tester.enterText(find.byType(TextFormField).at(0), 'Alice');
    await tester.enterText(find.byType(TextFormField).at(1), '500');
    await tester.ensureVisible(find.byType(ElevatedButton));
    final saveButton = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    await runDebtStep(
      tester,
      'thêm khoản vay: nhấn lưu và thực thi submit bất đồng bộ',
      () async {
        saveButton.onPressed!();
        await waitForDebtCondition(
          'provider chứa khoản vay vừa lưu',
          () => harness.loanProvider.loans.length == 1,
        );
      },
    );
    await pumpDebtFrames(tester);

    expect(harness.loanProvider.loans, hasLength(1));
    expect(harness.loanProvider.loans.single.personName, 'Alice');
    expect(
      await runDebtValue(
        tester,
        'thêm khoản vay: đọc số giao dịch',
        harness.fixture.transactionCount,
      ),
      1,
    );
    expect(
      await runDebtValue(
        tester,
        'thêm khoản vay: đọc số dư tài khoản',
        harness.fixture.accountBalance,
      ),
      1500,
    );
  });

  // Không có tài khoản nguồn thì UI phải từ chối lưu và không sinh transaction.
  testWidgets('Màn thêm khoản vay yêu cầu chọn tài khoản trước khi lưu', (
    tester,
  ) async {
    final harness = await pumpDebtWidget(
      tester,
      child: const AddEditLoanScreen(),
      seedAccount: false,
    );

    expect(find.byType(DropdownButton<int>), findsOneWidget);
    expect(find.text('Test Cash'), findsNothing);

    debugDebtStep('thêm khoản vay chưa chọn tài khoản: nhập dữ liệu');
    await tester.enterText(find.byType(TextFormField).at(0), 'Alice');
    await tester.enterText(find.byType(TextFormField).at(1), '500');
    await tester.ensureVisible(find.byType(ElevatedButton));
    final saveButton = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    await runDebtStep(
      tester,
      'thêm khoản vay chưa chọn tài khoản: nhấn lưu',
      () async {
        saveButton.onPressed!();
      },
    );
    await pumpDebtFrames(tester);

    expect(find.byType(SnackBar), findsOneWidget);
    expect(harness.loanProvider.loans, isEmpty);
    expect(
      await runDebtValue(
        tester,
        'thêm khoản vay chưa chọn tài khoản: đọc số giao dịch',
        harness.fixture.transactionCount,
      ),
      0,
    );
  });

  // Form trả nợ phải chặn khoản trả vượt remaining để bảo toàn balance/lịch sử.
  testWidgets('Màn thanh toán hiển thị dư nợ và từ chối trả quá số tiền', (
    tester,
  ) async {
    late final DebtDatabaseFixture fixture;
    await runDebtStep(
      tester,
      'fixture thanh toán: mở cơ sở dữ liệu FFI và tạo dữ liệu vay mẫu',
      () async {
        fixture = await openFfiDebtDatabaseFixture(initialBalance: 1000);
      },
    );
    addTearDown(fixture.dispose);

    late final Loan loan;
    await runDebtStep(
      tester,
      'fixture thanh toán: tạo khoản vay ban đầu',
      () async {
        loan = await _insertLoan(fixture, amount: 500);
      },
    );
    final harness = await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: PaymentScreen(loan: loan),
    );

    expect(find.text('Alice'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    debugDebtStep('thanh toán: nhập số tiền vượt dư nợ');
    await tester.enterText(find.byType(TextFormField).first, '600');
    await tester.ensureVisible(find.byType(ElevatedButton));
    final saveButton = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    await runDebtStep(
      tester,
      'thanh toán: nhấn lưu và kiểm tra số tiền vượt dư nợ',
      () async {
        saveButton.onPressed!();
      },
    );
    await pumpDebtFrames(tester);

    expect(
      await runDebtValue(
        tester,
        'thanh toán: đọc số lần trả nợ',
        harness.fixture.paymentCount,
      ),
      0,
    );
    expect(
      await runDebtValue(
        tester,
        'thanh toán: đọc số giao dịch',
        harness.fixture.transactionCount,
      ),
      1,
    );
    expect(
      await runDebtValue(
        tester,
        'thanh toán: đọc số dư tài khoản',
        harness.fixture.accountBalance,
      ),
      1500,
    );
  });

  // Sửa khoản vay từ UI phải cập nhật provider và hiệu chỉnh số dư theo số tiền mới.
  testWidgets('Màn sửa khoản vay lưu lại thông tin và số tiền mới', (tester) async {
    late final DebtDatabaseFixture fixture;
    late final Loan loan;
    await runDebtStep(
      tester,
      'fixture sửa khoản vay: tạo khoản vay ban đầu',
      () async {
        fixture = await openFfiDebtDatabaseFixture(initialBalance: 1000);
        loan = await _insertLoan(fixture, amount: 500);
      },
    );
    addTearDown(fixture.dispose);

    final harness = await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: AddEditLoanScreen(loan: loan),
    );

    expect(find.text('Sửa vay/cho vay'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Alice cập nhật');
    await tester.enterText(find.byType(TextFormField).at(1), '700');
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Lưu thay đổi'));
    final saveButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Lưu thay đổi'),
    );
    await runDebtStep(
      tester,
      'sửa khoản vay: lưu thông tin cập nhật',
      () async {
        saveButton.onPressed!();
        await waitForDebtCondition(
          'provider chứa khoản vay đã sửa',
          () => harness.loanProvider.loans.single.amount == 700,
        );
      },
    );
    await pumpDebtFrames(tester);

    expect(harness.loanProvider.loans.single.personName, 'Alice cập nhật');
    expect(harness.loanProvider.loans.single.amount, 700);
    expect(
      await runDebtValue(
        tester,
        'sửa khoản vay: đọc số dư tài khoản',
        fixture.accountBalance,
      ),
      1700,
    );
  });

  // Chi tiết khoản đã tất toán phải hiển thị lịch sử nhưng không cho trả thêm.
  testWidgets('Màn chi tiết hiển thị lịch sử và ẩn thanh toán khi đã trả hết', (
    tester,
  ) async {
    late final DebtDatabaseFixture fixture;
    late final Loan paidLoan;
    await runDebtStep(
      tester,
      'fixture chi tiết: tạo và trả hết khoản vay',
      () async {
        fixture = await openFfiDebtDatabaseFixture(initialBalance: 1000);
        final loan = await _insertLoan(fixture, amount: 500);
        await LoanDao().recordPaymentWithTransaction(
          loanId: loan.id!,
          userId: fixture.userId,
          amount: 500,
          paymentDate: DateTime(2026, 5, 24),
          note: 'Đã thanh toán đủ',
          accountId: fixture.accountId!,
          categoryId: fixture.borrowPaymentCategoryId,
        );
        paidLoan = (await LoanDao().findByIdForUser(loan.id!, fixture.userId))!;
      },
    );
    addTearDown(fixture.dispose);

    await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: LoanDetailScreen(loan: paidLoan),
    );
    await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 10)));
    await pumpDebtFrames(tester);

    expect(find.text('Đã trả'), findsWidgets);
    expect(find.text(Formatters.currency(500)), findsWidgets);
    expect(find.text('Đã thanh toán đủ'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Thanh toán'), findsNothing);
  });

  // Dialog xóa phải hỗ trợ hủy an toàn; xác nhận xóa mới rollback số dư.
  testWidgets('Màn chi tiết hủy rồi xác nhận xóa khoản vay và hoàn tác số dư', (
    tester,
  ) async {
    late final DebtDatabaseFixture fixture;
    late final Loan loan;
    await runDebtStep(
      tester,
      'fixture xóa khoản vay: tạo dữ liệu ban đầu',
      () async {
        fixture = await openFfiDebtDatabaseFixture(initialBalance: 1000);
        loan = await _insertLoan(fixture, amount: 500);
      },
    );
    addTearDown(fixture.dispose);

    final harness = await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: LoanDetailScreen(loan: loan),
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    await pumpDebtFrames(tester, frames: 1);
    expect(find.text('Xóa khoản vay'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
    await pumpDebtFrames(tester, frames: 1);
    expect(harness.loanProvider.loans, hasLength(1));

    await tester.tap(find.byIcon(Icons.delete_outline));
    await pumpDebtFrames(tester, frames: 1);
    final deleteButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Xóa'),
    );
    await runDebtStep(
      tester,
      'xóa khoản vay: xác nhận xóa và chờ tải lại dữ liệu',
      () async {
        deleteButton.onPressed!();
        await waitForDebtCondition(
          'provider không còn khoản vay sau khi xóa',
          () => harness.loanProvider.loans.isEmpty,
        );
      },
    );
    await pumpDebtFrames(tester);

    expect(harness.loanProvider.loans, isEmpty);
    expect(
      await runDebtValue(
        tester,
        'xóa khoản vay: đọc số dư hoàn tác',
        fixture.accountBalance,
      ),
      1000,
    );
  });

  // Thu đủ khoản cho vay từ UI phải tất toán và đưa tiền về tài khoản đã chọn.
  testWidgets('Màn thu nợ khoản cho vay lưu thanh toán đủ và khôi phục số dư', (
    tester,
  ) async {
    late final DebtDatabaseFixture fixture;
    late final Loan loan;
    await runDebtStep(
      tester,
      'fixture thu nợ: tạo khoản cho vay',
      () async {
        fixture = await openFfiDebtDatabaseFixture(initialBalance: 1000);
        loan = await _insertLoan(
          fixture,
          type: 'lend',
          personName: 'Bob',
          amount: 300,
        );
      },
    );
    addTearDown(fixture.dispose);

    final harness = await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: PaymentScreen(loan: loan),
    );

    expect(find.text('Ghi nhận thu nợ'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '300');
    final saveButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Lưu thanh toán'),
    );
    await runDebtStep(
      tester,
      'thu nợ: lưu khoản thu đủ',
      () async {
        saveButton.onPressed!();
        await waitForDebtCondition(
          'provider chuyển khoản cho vay sang đã trả',
          () => harness.loanProvider.loans.single.status == 'paid',
        );
      },
    );
    await pumpDebtFrames(tester);

    expect(harness.loanProvider.loans.single.remainingAmount, 0);
    expect(
      await runDebtValue(
        tester,
        'thu nợ: đọc số dư tài khoản',
        fixture.accountBalance,
      ),
      1000,
    );
  });

  // Form payment không được tạo lịch sử nếu chưa có tài khoản nhận/chi tiền.
  testWidgets('Màn thanh toán yêu cầu tài khoản trước khi lưu', (tester) async {
    late final DebtDatabaseFixture fixture;
    await runDebtStep(
      tester,
      'fixture thanh toán thiếu tài khoản: tạo dữ liệu không có tài khoản',
      () async {
        fixture = await openFfiDebtDatabaseFixture(seedAccount: false);
      },
    );
    addTearDown(fixture.dispose);
    final now = DateTime.now();
    final loan = Loan(
      id: 1,
      userId: fixture.userId,
      type: 'borrow',
      personName: 'Alice',
      amount: 500,
      remainingAmount: 500,
      startDate: now.subtract(const Duration(days: 1)),
      createdAt: now,
      updatedAt: now,
    );

    await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: PaymentScreen(loan: loan),
    );
    await tester.enterText(find.byType(TextFormField).first, '100');
    final saveButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Lưu thanh toán'),
    );
    saveButton.onPressed!();
    await pumpDebtFrames(tester);

    expect(find.text('Vui lòng chọn tài khoản'), findsOneWidget);
    expect(
      await runDebtValue(
        tester,
        'thanh toán thiếu tài khoản: đọc số lần trả',
        fixture.paymentCount,
      ),
      0,
    );
  });
}

/// Seed một khoản vay/cho vay qua DAO để widget test mở thẳng màn cần kiểm tra.
Future<Loan> _insertLoan(
  DebtDatabaseFixture fixture, {
  String type = 'borrow',
  String personName = 'Alice',
  required double amount,
}) async {
  final now = DateTime(2026, 5, 24, 8);
  final dao = LoanDao();
  final loanId = await dao.insertWithInitialTransaction(
    loan: Loan(
      userId: fixture.userId,
      type: type,
      personName: personName,
      amount: amount,
      remainingAmount: amount,
      startDate: DateTime(2026, 5, 24),
      accountId: fixture.accountId,
      createdAt: now,
      updatedAt: now,
    ),
    categoryId: type == 'borrow'
        ? fixture.borrowInitialCategoryId
        : fixture.lendInitialCategoryId,
  );
  return (await dao.findByIdForUser(loanId, fixture.userId))!;
}
