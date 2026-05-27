import 'dart:io';

import 'package:coin_nest/screens/loans/add_edit_loan_screen.dart';
import 'package:coin_nest/screens/loans/loan_detail_screen.dart';
import 'package:coin_nest/screens/loans/loan_list_screen.dart';
import 'package:coin_nest/screens/loans/payment_screen.dart';
import 'package:coin_nest/theme/app_theme.dart';
import 'package:coin_nest/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

import '../test/helpers/debt_database_fixture.dart';
import '../test/helpers/debt_widget_harness.dart';

const _thoiGianQuanSat = Duration(seconds: 2);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (!Platform.isAndroid) {
    testWidgets('Luồng tích hợp vay và cho vay chỉ chạy trên Android', (tester) async {
      markTestSkipped('Chỉ chạy trên Android: Genymotion hoặc điện thoại thật.');
    });
    return;
  }

  testWidgets('Luồng vay qua danh sách và chi tiết, trả nợ và cho vay dùng dữ liệu biệt lập', (
    tester,
  ) async {
    late final Database db;
    late final DebtDatabaseFixture fixture;
    await runDebtStep(
      tester,
      'tích hợp fixture: mở cơ sở dữ liệu và tạo dữ liệu vay mẫu',
      () async {
        db = await openDatabase(inMemoryDatabasePath);
        fixture = await seedDebtDatabaseFixture(db, initialBalance: 1000);
      },
    );
    addTearDown(fixture.dispose);

    final borrowHarness = await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: const LoanListScreen(),
      theme: AppTheme.lightTheme,
    );
    expect(find.byType(LoanListScreen), findsOneWidget);
    await _dungDeQuanSat(tester, 'danh sách khoản vay ban đầu');

    debugDebtStep('tích hợp vay: mở màn thêm khoản vay từ danh sách');
    await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
    await pumpDebtFrames(tester);
    expect(find.byType(AddEditLoanScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Alice');
    await tester.enterText(find.byType(TextFormField).at(1), '500');
    await pumpDebtFrames(tester, frames: 1);
    await _dungDeQuanSat(tester, 'biểu mẫu vay trước khi lưu');
    await tester.ensureVisible(find.byType(ElevatedButton));
    final borrowSaveButton = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    await runDebtStep(
      tester,
      'tích hợp vay: nhấn lưu',
      () async {
        borrowSaveButton.onPressed!();
        await waitForDebtCondition(
          'provider tích hợp chứa khoản vay vừa lưu',
          () => borrowHarness.loanProvider.loans.length == 1,
        );
      },
    );
    await pumpDebtFrames(tester);

    expect(find.byType(LoanListScreen), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text(Formatters.currency(500)), findsWidgets);
    expect(borrowHarness.loanProvider.loans, hasLength(1));
    expect(borrowHarness.loanProvider.summary['borrowed'], 500);
    await _dungDeQuanSat(tester, 'danh sách sau khi tạo khoản vay');
    expect(
      await runDebtValue(
        tester,
        'tích hợp vay: đọc số dư tài khoản',
        fixture.accountBalance,
      ),
      1500,
    );

    debugDebtStep('tích hợp vay: mở chi tiết từ danh sách');
    await tester.tap(find.text('Alice'));
    await pumpDebtFrames(tester);
    expect(find.byType(LoanDetailScreen), findsOneWidget);
    expect(find.text(Formatters.currency(500)), findsWidgets);
    await _dungDeQuanSat(tester, 'chi tiết khoản vay trước khi trả nợ');

    debugDebtStep('tích hợp trả nợ: mở màn thanh toán từ chi tiết');
    await tester.tap(find.byType(ElevatedButton));
    await pumpDebtFrames(tester);
    expect(find.byType(PaymentScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '200');
    await pumpDebtFrames(tester, frames: 1);
    await _dungDeQuanSat(tester, 'biểu mẫu thanh toán trước khi lưu');
    await tester.ensureVisible(find.byType(ElevatedButton));
    final paymentSaveButton = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    await runDebtStep(
      tester,
      'tích hợp trả nợ: nhấn lưu',
      () async {
        paymentSaveButton.onPressed!();
        await waitForDebtCondition(
          'provider tích hợp cập nhật dư nợ sau khi trả',
          () => borrowHarness.loanProvider.loans.single.remainingAmount == 300,
        );
      },
    );
    await pumpDebtFrames(tester);

    expect(find.byType(LoanDetailScreen), findsOneWidget);
    expect(borrowHarness.loanProvider.loans.single.remainingAmount, 300);
    debugDebtStep('tích hợp trả nợ: chờ chi tiết hiển thị dư nợ mới');
    await pumpDebtUntil(
      tester,
      () => find.text(Formatters.currency(300)).evaluate().isNotEmpty,
    );
    debugDebtStep('tích hợp trả nợ: chi tiết đã hiển thị dư nợ mới');
    expect(find.text(Formatters.currency(300)), findsOneWidget);
    await _dungDeQuanSat(tester, 'chi tiết khoản vay sau khi trả một phần');
    expect(
      await runDebtValue(
        tester,
        'tích hợp trả nợ: đọc số dư tài khoản',
        fixture.accountBalance,
      ),
      1300,
    );

    debugDebtStep('tích hợp cho vay: quay lại danh sách từ chi tiết');
    await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
    await pumpDebtFrames(tester);
    expect(find.byType(LoanListScreen), findsOneWidget);

    debugDebtStep('tích hợp cho vay: mở màn thêm khoản cho vay từ danh sách');
    await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
    await pumpDebtFrames(tester);
    expect(find.byType(AddEditLoanScreen), findsOneWidget);

    await tester.tap(find.text('Cho vay'));
    await tester.enterText(find.byType(TextFormField).at(0), 'Bob');
    await tester.enterText(find.byType(TextFormField).at(1), '300');
    await pumpDebtFrames(tester, frames: 1);
    await _dungDeQuanSat(tester, 'biểu mẫu cho vay trước khi lưu');
    await tester.ensureVisible(find.byType(ElevatedButton));
    final lendSaveButton = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    await runDebtStep(
      tester,
      'tích hợp cho vay: nhấn lưu',
      () async {
        lendSaveButton.onPressed!();
        await waitForDebtCondition(
          'provider tích hợp cập nhật tổng cho vay',
          () => borrowHarness.loanProvider.summary['lent'] == 300,
        );
      },
    );
    await pumpDebtFrames(tester);

    expect(find.byType(LoanListScreen), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    await _dungDeQuanSat(tester, 'danh sách sau khi tạo khoản cho vay');
    expect(borrowHarness.loanProvider.summary['borrowed'], 300);
    expect(borrowHarness.loanProvider.summary['lent'], 300);
    expect(
      await runDebtValue(
        tester,
        'tích hợp cho vay: đọc số dư tài khoản',
        fixture.accountBalance,
      ),
      1000,
    );

    final txns = await runDebtValue(
      tester,
      'tích hợp cho vay: đọc danh sách giao dịch',
      () => fixture.db.query(
        'transactions',
        orderBy: 'id ASC',
      ),
    );
    expect(txns.map((txn) => txn['type']), containsAll(['loan', 'expense', 'lend']));
    expect(txns.last['category_id'], fixture.lendInitialCategoryId);
  });
}

Future<void> _dungDeQuanSat(WidgetTester tester, String trangThai) async {
  // Delay chỉ dành cho integration test để quan sát UI trên thiết bị Android.
  debugDebtStep('quan sát UI: $trangThai');
  await tester.runAsync(
    () async => Future<void>.delayed(_thoiGianQuanSat),
  );
}
