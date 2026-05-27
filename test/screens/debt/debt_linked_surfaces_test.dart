import 'package:coin_nest/database/loan_dao.dart';
import 'package:coin_nest/models/loan.dart';
import 'package:coin_nest/providers/loan_provider.dart';
import 'package:coin_nest/screens/loans/loan_detail_screen.dart';
import 'package:coin_nest/screens/loans/loan_list_screen.dart';
import 'package:coin_nest/screens/reports/loan_tracking_screen.dart';
import 'package:coin_nest/screens/transactions/transaction_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/debt_database_fixture.dart';
import '../../helpers/debt_ffi_database.dart';
import '../../helpers/debt_widget_harness.dart';

void main() {
  testWidgets('Danh sách khoản vay hiển thị trạng thái rỗng', (tester) async {
    late final DebtDatabaseFixture fixture;
    await runDebtStep(
      tester,
      'fixture danh sách rỗng: tạo cơ sở dữ liệu không có khoản vay',
      () async {
        fixture = await openFfiDebtDatabaseFixture(initialBalance: 1000);
      },
    );
    addTearDown(fixture.dispose);

    await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: const LoanListScreen(),
    );
    await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 10)));
    await pumpDebtFrames(tester);

    expect(find.text('Chưa có khoản vay nào'), findsOneWidget);
  });

  testWidgets('Danh sách khoản vay hiển thị trạng thái quá hạn và đã trả', (
    tester,
  ) async {
    late final DebtDatabaseFixture fixture;
    await runDebtStep(
      tester,
      'fixture danh sách: tạo khoản quá hạn và khoản đã trả',
      () async {
        fixture = await openFfiDebtDatabaseFixture(initialBalance: 1000);
        await _insertLoan(
          fixture,
          personName: 'Khoản quá hạn',
          amount: 200,
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        final paid = await _insertLoan(
          fixture,
          type: 'lend',
          personName: 'Khoản đã thu',
          amount: 300,
        );
        await LoanDao().recordPaymentWithTransaction(
          loanId: paid.id!,
          userId: fixture.userId,
          amount: 300,
          paymentDate: DateTime.now().subtract(const Duration(days: 1)),
          accountId: fixture.accountId!,
          categoryId: fixture.lendPaymentCategoryId,
        );
      },
    );
    addTearDown(fixture.dispose);

    await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: const LoanListScreen(),
    );
    await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 10)));
    await pumpDebtFrames(tester);

    expect(find.text('Khoản quá hạn'), findsOneWidget);
    expect(find.text('Khoản đã thu'), findsOneWidget);
    expect(find.text('Quá hạn'), findsOneWidget);
    expect(find.text('Đã trả'), findsOneWidget);
  });

  testWidgets('Giao dịch liên kết mở chi tiết khoản vay', (tester) async {
    late final DebtDatabaseFixture fixture;
    await runDebtStep(
      tester,
      'fixture giao dịch: tạo khoản vay liên kết',
      () async {
        fixture = await openFfiDebtDatabaseFixture(initialBalance: 1000);
        await _insertLoan(fixture, personName: 'Alice liên kết', amount: 500);
      },
    );
    addTearDown(fixture.dispose);

    await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: const TransactionListScreen(),
    );
    await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 10)));
    await pumpDebtFrames(tester);
    expect(find.text('Vay mượn'), findsOneWidget);

    final tile = tester.widget<GestureDetector>(
      find.ancestor(
        of: find.text('Vay mượn'),
        matching: find.byType(GestureDetector),
      ).first,
    );
    await runDebtStep(
      tester,
      'giao dịch liên kết: mở chi tiết',
      () async {
        tile.onTap!();
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
    );
    await pumpDebtFrames(tester);

    expect(find.byType(LoanDetailScreen), findsOneWidget);
    expect(find.text('Alice liên kết'), findsOneWidget);
  });

  testWidgets('Giao dịch vay thiếu liên kết hiển thị thông báo lỗi', (
    tester,
  ) async {
    late final DebtDatabaseFixture fixture;
    await runDebtStep(
      tester,
      'fixture giao dịch lỗi: tạo giao dịch debt không còn khoản vay',
      () async {
        fixture = await openFfiDebtDatabaseFixture(initialBalance: 1000);
        final now = DateTime.now();
        await fixture.db.insert('transactions', {
          'user_id': fixture.userId,
          'account_id': fixture.accountId,
          'category_id': fixture.borrowInitialCategoryId,
          'type': 'loan',
          'amount': 250,
          'date': now.toIso8601String().split('T').first,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
      },
    );
    addTearDown(fixture.dispose);

    await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: const TransactionListScreen(),
    );
    await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 10)));
    await pumpDebtFrames(tester);
    final tile = tester.widget<GestureDetector>(
      find.ancestor(
        of: find.text('Vay mượn'),
        matching: find.byType(GestureDetector),
      ).first,
    );
    await runDebtStep(
      tester,
      'giao dịch lỗi: thử mở khoản vay liên kết',
      () async {
        tile.onTap!();
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
    );
    await pumpDebtFrames(tester);

    expect(
      find.text('Không tìm thấy khoản vay liên kết với giao dịch này'),
      findsOneWidget,
    );
  });

  testWidgets('Màn theo dõi vay nợ hiển thị hai tab và mở chi tiết', (
    tester,
  ) async {
    late final DebtDatabaseFixture fixture;
    await runDebtStep(
      tester,
      'fixture theo dõi: tạo khoản vay và cho vay',
      () async {
        fixture = await openFfiDebtDatabaseFixture(initialBalance: 1000);
        await _insertLoan(
          fixture,
          personName: 'Alice quá hạn',
          amount: 500,
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        );
        await _insertLoan(
          fixture,
          type: 'lend',
          personName: 'Bob theo dõi',
          amount: 300,
        );
        final paid = await _insertLoan(
          fixture,
          type: 'lend',
          personName: 'Bob đã thu đủ',
          amount: 200,
        );
        await LoanDao().recordPaymentWithTransaction(
          loanId: paid.id!,
          userId: fixture.userId,
          amount: 200,
          paymentDate: DateTime.now().subtract(const Duration(days: 1)),
          accountId: fixture.accountId!,
          categoryId: fixture.lendPaymentCategoryId,
        );
      },
    );
    addTearDown(fixture.dispose);

    await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: const LoanTrackingScreen(),
      loanProviderOverride: _PreloadedLoanTrackingProvider(),
    );
    await pumpDebtFrames(tester);
    await pumpDebtUntil(
      tester,
      () => find.text('Bob theo dõi').evaluate().isNotEmpty,
    );

    expect(find.text('Theo dõi vay nợ'), findsOneWidget);
    expect(find.text('Cho vay'), findsOneWidget);
    expect(find.text('Còn nợ'), findsOneWidget);
    expect(find.text('Bob theo dõi'), findsOneWidget);
    expect(find.text('Bob đã thu đủ'), findsOneWidget);
    expect(find.text('Đã trả'), findsOneWidget);

    await tester.tap(find.text('Bob theo dõi'));
    await pumpDebtFrames(tester);
    expect(find.byType(LoanDetailScreen), findsOneWidget);

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.arrow_back_ios_rounded),
    );
    await pumpDebtFrames(tester);
    await tester.tap(find.text('Còn nợ'));
    await pumpDebtFrames(tester);
    expect(find.text('Alice quá hạn'), findsOneWidget);
    expect(find.text('Quá hạn'), findsOneWidget);
  });
}

class _PreloadedLoanTrackingProvider extends LoanProvider {
  var _loadCalls = 0;

  @override
  Future<void> loadLoans(int userId) async {
    _loadCalls++;
    if (_loadCalls > 1) {
      // Harness đã preload trong runAsync; lần reload post-frame chạy ngoài
      // runAsync sẽ làm truy vấn SQLite FFI bị treo trong widget test.
      return;
    }
    await super.loadLoans(userId);
  }
}

Future<Loan> _insertLoan(
  DebtDatabaseFixture fixture, {
  String type = 'borrow',
  required String personName,
  required double amount,
  DateTime? dueDate,
}) async {
  final now = DateTime.now();
  final loanId = await LoanDao().insertWithInitialTransaction(
    loan: Loan(
      userId: fixture.userId,
      type: type,
      personName: personName,
      amount: amount,
      remainingAmount: amount,
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      dueDate: dueDate,
      accountId: fixture.accountId,
      createdAt: now,
      updatedAt: now,
    ),
    categoryId: type == 'borrow'
        ? fixture.borrowInitialCategoryId
        : fixture.lendInitialCategoryId,
  );
  return (await LoanDao().findByIdForUser(loanId, fixture.userId))!;
}
