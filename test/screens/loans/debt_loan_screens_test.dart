import 'package:coin_nest/database/loan_dao.dart';
import 'package:coin_nest/models/loan.dart';
import 'package:coin_nest/screens/loans/add_edit_loan_screen.dart';
import 'package:coin_nest/screens/loans/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/debt_database_fixture.dart';
import '../../helpers/debt_ffi_database.dart';
import '../../helpers/debt_ffi_widget_harness.dart';
import '../../helpers/debt_widget_harness.dart';

void main() {
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
        loan = await _insertBorrowLoan(fixture, amount: 500);
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
}

Future<Loan> _insertBorrowLoan(
  DebtDatabaseFixture fixture, {
  required double amount,
}) async {
  final now = DateTime(2026, 5, 24, 8);
  final dao = LoanDao();
  final loanId = await dao.insertWithInitialTransaction(
    loan: Loan(
      userId: fixture.userId,
      type: 'borrow',
      personName: 'Alice',
      amount: amount,
      remainingAmount: amount,
      startDate: DateTime(2026, 5, 24),
      accountId: fixture.accountId,
      createdAt: now,
      updatedAt: now,
    ),
    categoryId: fixture.borrowInitialCategoryId,
  );
  return (await dao.findByIdForUser(loanId, fixture.userId))!;
}
