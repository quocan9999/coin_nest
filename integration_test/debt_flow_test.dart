import 'dart:io';

import 'package:coin_nest/database/loan_dao.dart';
import 'package:coin_nest/models/loan.dart';
import 'package:coin_nest/screens/loans/add_edit_loan_screen.dart';
import 'package:coin_nest/screens/loans/loan_detail_screen.dart';
import 'package:coin_nest/screens/loans/loan_list_screen.dart';
import 'package:coin_nest/screens/loans/payment_screen.dart';
import 'package:coin_nest/screens/reports/loan_tracking_screen.dart';
import 'package:coin_nest/screens/transactions/transaction_list_screen.dart';
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
    // Khóa phạm vi chạy integration debt vào Android để tránh xác nhận sai
    // trên các nền tảng không thuộc kịch bản nghiệm thu của feature.
    testWidgets('Luồng tích hợp vay và cho vay chỉ chạy trên Android', (tester) async {
      markTestSkipped('Chỉ chạy trên Android: Genymotion hoặc điện thoại thật.');
    });
    return;
  }

  // Kiểm tra hành trình lõi: tạo khoản vay, trả một phần rồi tạo khoản cho vay.
  // Xác minh đồng thời list/detail, tổng dư nợ, số dư tài khoản và giao dịch sinh ra.
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

  // Kiểm tra việc sửa thông tin khoản vay và thanh toán hết dư nợ.
  // Khoản đã tất toán phải đổi trạng thái, ẩn thao tác thanh toán và rời tổng đang vay.
  testWidgets('Luồng sửa và trả hết khoản vay cập nhật chi tiết và trạng thái', (
    tester,
  ) async {
    final fixture = await _taoFixtureTichHop(tester);
    addTearDown(fixture.dispose);
    await runDebtValue(
      tester,
      'tích hợp sửa: tạo khoản vay ban đầu',
      () => _themKhoanDebt(fixture, personName: 'Alice', amount: 500),
    );

    final harness = await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: const LoanListScreen(),
      theme: AppTheme.lightTheme,
    );
    await tester.tap(find.text('Alice'));
    await pumpDebtFrames(tester);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await pumpDebtFrames(tester);
    expect(find.byType(AddEditLoanScreen), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Alice cập nhật');
    await tester.enterText(find.byType(TextFormField).at(1), '700');
    await tester.enterText(find.byType(TextFormField).at(2), '5');
    await tester.enterText(find.byType(TextFormField).at(3), 'Có lãi suất');
    await _dungDeQuanSat(tester, 'biểu mẫu sửa khoản vay trước khi lưu');
    final editButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Lưu thay đổi'),
    );
    await runDebtStep(
      tester,
      'tích hợp sửa: lưu thay đổi',
      () async {
        editButton.onPressed!();
        await waitForDebtCondition(
          'provider cập nhật khoản vay đã sửa',
          () => harness.loanProvider.loans.single.amount == 700,
        );
      },
    );
    await pumpDebtFrames(tester);
    await pumpDebtUntil(
      tester,
      () => find.text('Alice cập nhật').evaluate().isNotEmpty,
    );
    expect(find.text('Có lãi suất'), findsOneWidget);
    await _dungDeQuanSat(tester, 'chi tiết khoản vay sau khi chỉnh sửa');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Thanh toán'));
    await pumpDebtFrames(tester);
    await tester.enterText(find.byType(TextFormField).first, '700');
    await _dungDeQuanSat(tester, 'biểu mẫu thanh toán đủ dư nợ');
    final paymentButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Lưu thanh toán'),
    );
    await runDebtStep(
      tester,
      'tích hợp trả hết: lưu thanh toán',
      () async {
        paymentButton.onPressed!();
        await waitForDebtCondition(
          'provider chuyển khoản vay sang đã trả',
          () => harness.loanProvider.loans.single.status == 'paid',
        );
      },
    );
    await pumpDebtFrames(tester);
    await pumpDebtUntil(tester, () => find.text('Đã trả').evaluate().isNotEmpty);

    expect(find.widgetWithText(ElevatedButton, 'Thanh toán'), findsNothing);
    expect(harness.loanProvider.summary['borrowed'], 0);
    expect(await runDebtValue(tester, 'tích hợp trả hết: đọc số dư', fixture.accountBalance), 1000);
    await _dungDeQuanSat(tester, 'chi tiết khoản vay đã trả hết');
  });

  // Kiểm tra phía cho vay: thu hồi một phần tiền trước khi xóa khoản cho vay.
  // Việc hủy/xác nhận xóa phải đúng UI và thao tác xóa phải hoàn tác số dư đã tác động.
  testWidgets('Luồng cho vay thu nợ và xóa hoàn tác dữ liệu qua giao diện', (
    tester,
  ) async {
    final fixture = await _taoFixtureTichHop(tester);
    addTearDown(fixture.dispose);
    await runDebtValue(
      tester,
      'tích hợp cho vay xóa: tạo khoản ban đầu',
      () => _themKhoanDebt(
        fixture,
        type: 'lend',
        personName: 'Bob',
        amount: 300,
      ),
    );

    final harness = await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: const LoanListScreen(),
      theme: AppTheme.lightTheme,
    );
    await tester.tap(find.text('Bob'));
    await pumpDebtFrames(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Thu nợ'));
    await pumpDebtFrames(tester);
    await tester.enterText(find.byType(TextFormField).first, '100');
    await _dungDeQuanSat(tester, 'biểu mẫu thu nợ trước khi lưu');
    final collectButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Lưu thanh toán'),
    );
    await runDebtStep(
      tester,
      'tích hợp thu nợ: lưu thanh toán một phần',
      () async {
        collectButton.onPressed!();
        await waitForDebtCondition(
          'provider cập nhật dư nợ cho vay',
          () => harness.loanProvider.loans.single.remainingAmount == 200,
        );
      },
    );
    await pumpDebtFrames(tester);
    expect(await runDebtValue(tester, 'tích hợp thu nợ: đọc số dư', fixture.accountBalance), 800);
    await _dungDeQuanSat(tester, 'chi tiết khoản cho vay sau khi thu nợ');

    await tester.tap(find.byIcon(Icons.delete_outline));
    await pumpDebtFrames(tester, frames: 1);
    await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
    await pumpDebtFrames(tester, frames: 1);
    expect(find.byType(LoanDetailScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await pumpDebtFrames(tester, frames: 1);
    final deleteButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Xóa'),
    );
    await runDebtStep(
      tester,
      'tích hợp xóa: xác nhận và hoàn tác khoản cho vay',
      () async {
        deleteButton.onPressed!();
        await waitForDebtCondition(
          'provider không còn khoản cho vay',
          () => harness.loanProvider.loans.isEmpty,
        );
      },
    );
    await pumpDebtFrames(tester);

    expect(find.byType(LoanListScreen), findsOneWidget);
    expect(find.text('Bob'), findsNothing);
    expect(await runDebtValue(tester, 'tích hợp xóa: đọc số dư hoàn tác', fixture.accountBalance), 1000);
    await _dungDeQuanSat(tester, 'danh sách sau khi xóa khoản cho vay');
  });

  // Kiểm tra invariant dòng tiền khi chuyển một khoản từ vay sang cho vay
  // và đồng thời đổi tài khoản liên kết: số dư phải được hiệu chỉnh đúng tài khoản mới.
  testWidgets('Luồng đổi loại vay cho vay và tài khoản liên kết cập nhật dòng tiền', (
    tester,
  ) async {
    final fixture = await _taoFixtureTichHop(tester);
    addTearDown(fixture.dispose);
    final secondAccountId = await runDebtValue(
      tester,
      'tích hợp đổi tài khoản: tạo tài khoản thứ hai',
      () => fixture.insertAccount(name: 'Test Bank', balance: 2000),
    );
    await runDebtValue(
      tester,
      'tích hợp đổi tài khoản: tạo khoản vay',
      () => _themKhoanDebt(fixture, personName: 'Chuyển loại', amount: 500),
    );

    final harness = await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: const LoanListScreen(),
      theme: AppTheme.lightTheme,
    );
    await tester.tap(find.text('Chuyển loại'));
    await pumpDebtFrames(tester);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await pumpDebtFrames(tester);
    await tester.tap(find.text('Cho vay'));
    await tester.ensureVisible(find.byType(DropdownButton<int>));
    await pumpDebtFrames(tester, frames: 1);
    await tester.tap(find.byType(DropdownButton<int>));
    await pumpDebtFrames(tester, frames: 1);
    await tester.tap(find.text('Test Bank').last);
    await pumpDebtFrames(tester, frames: 1);
    await _dungDeQuanSat(tester, 'biểu mẫu sau khi đổi loại và tài khoản');

    final editButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Lưu thay đổi'),
    );
    await runDebtStep(
      tester,
      'tích hợp đổi loại: lưu thay đổi',
      () async {
        editButton.onPressed!();
        await waitForDebtCondition(
          'provider ghi loại cho vay mới',
          () => harness.loanProvider.loans.single.type == 'lend',
        );
      },
    );
    await pumpDebtFrames(tester);

    expect(harness.loanProvider.loans.single.accountId, secondAccountId);
    await pumpDebtUntil(
      tester,
      () => find.text('Cho vay').evaluate().isNotEmpty,
    );
    expect(find.text('Cho vay'), findsOneWidget);
    expect(await runDebtValue(tester, 'tích hợp đổi loại: số dư tiền mặt', fixture.accountBalance), 1000);
    expect(
      await runDebtValue(
        tester,
        'tích hợp đổi loại: số dư ngân hàng',
        () => fixture.accountBalanceFor(secondAccountId),
      ),
      1500,
    );
    await _dungDeQuanSat(tester, 'chi tiết sau khi đổi thành khoản cho vay');
  });

  // Kiểm tra điều hướng từ giao dịch có liên kết sang chi tiết khoản vay,
  // đồng thời xác nhận UI báo lỗi rõ ràng khi giao dịch không còn loan tương ứng.
  testWidgets('Luồng giao dịch vay mở chi tiết và báo lỗi khi liên kết thiếu', (
    tester,
  ) async {
    final fixture = await _taoFixtureTichHop(tester);
    addTearDown(fixture.dispose);
    await runDebtValue(
      tester,
      'tích hợp giao dịch: tạo khoản liên kết',
      () => _themKhoanDebt(fixture, personName: 'Alice giao dịch', amount: 500),
    );

    final harness = await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: const TransactionListScreen(),
      theme: AppTheme.lightTheme,
    );
    await tester.tap(find.text('Vay mượn'));
    await pumpDebtFrames(tester);
    await pumpDebtUntil(
      tester,
      () => find.byType(LoanDetailScreen).evaluate().isNotEmpty,
    );
    expect(find.byType(LoanDetailScreen), findsOneWidget);
    await _dungDeQuanSat(tester, 'chi tiết mở từ giao dịch liên kết');
    await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
    await pumpDebtFrames(tester);

    await runDebtStep(
      tester,
      'tích hợp giao dịch: thêm giao dịch không còn liên kết',
      () async {
        final now = DateTime.now();
        await fixture.db.insert('transactions', {
          'user_id': fixture.userId,
          'account_id': fixture.accountId,
          'category_id': fixture.borrowInitialCategoryId,
          'type': 'loan',
          'amount': 250,
          'note': 'Liên kết thiếu',
          'date': now.toIso8601String().split('T').first,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
        await harness.transactionProvider.loadTransactions(fixture.userId);
      },
    );
    await pumpDebtFrames(tester);
    await tester.tap(find.textContaining('Liên kết thiếu'));
    await pumpDebtFrames(tester);

    expect(
      find.text('Không tìm thấy khoản vay liên kết với giao dịch này'),
      findsOneWidget,
    );
    await _dungDeQuanSat(tester, 'thông báo giao dịch thiếu liên kết');
  });

  // Kiểm tra màn theo dõi phản ánh tiến độ thu nợ sau thao tác thực tế ở chi tiết,
  // và tab còn nợ vẫn nhận diện đúng khoản vay đã quá hạn.
  testWidgets('Luồng theo dõi vay nợ làm mới tiến độ sau khi thu nợ', (
    tester,
  ) async {
    final fixture = await _taoFixtureTichHop(tester);
    addTearDown(fixture.dispose);
    await runDebtValue(
      tester,
      'tích hợp theo dõi: tạo khoản cho vay',
      () => _themKhoanDebt(
        fixture,
        type: 'lend',
        personName: 'Bob theo dõi',
        amount: 300,
      ),
    );
    await runDebtValue(
      tester,
      'tích hợp theo dõi: tạo khoản quá hạn',
      () => _themKhoanDebt(
        fixture,
        personName: 'Alice quá hạn',
        amount: 500,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );

    await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: const LoanTrackingScreen(),
      theme: AppTheme.lightTheme,
    );
    await pumpDebtFrames(tester);
    await pumpDebtUntil(tester, () => find.text('Bob theo dõi').evaluate().isNotEmpty);
    expect(find.text('Bob theo dõi'), findsOneWidget);
    await _dungDeQuanSat(tester, 'theo dõi khoản cho vay ban đầu');

    await tester.tap(find.text('Bob theo dõi'));
    await pumpDebtFrames(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Thu nợ'));
    await pumpDebtFrames(tester);
    await tester.enterText(find.byType(TextFormField).first, '100');
    final collectButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Lưu thanh toán'),
    );
    await runDebtStep(
      tester,
      'tích hợp theo dõi: thu nợ từ chi tiết',
      () async {
        collectButton.onPressed!();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
    );
    await pumpDebtFrames(tester);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
    await pumpDebtFrames(tester);
    await pumpDebtUntil(tester, () => find.text('33%').evaluate().isNotEmpty);

    expect(find.text('33%'), findsWidgets);
    await _dungDeQuanSat(tester, 'theo dõi sau khi thu một phần');
    await tester.tap(find.text('Còn nợ'));
    await pumpDebtFrames(tester);
    expect(find.text('Alice quá hạn'), findsOneWidget);
    expect(find.text('Quá hạn'), findsOneWidget);
    await _dungDeQuanSat(tester, 'theo dõi khoản vay quá hạn');
  });

  // Kiểm tra validation tạo khoản vay không cho lưu khi thiếu tài khoản nguồn,
  // nhằm bảo đảm thao tác lỗi không ghi giao dịch vào cơ sở dữ liệu.
  testWidgets('Luồng validation giao diện từ chối tạo khoản vay khi thiếu tài khoản', (
    tester,
  ) async {
    final fixture = await _taoFixtureTichHop(tester, seedAccount: false);
    addTearDown(fixture.dispose);
    await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: const AddEditLoanScreen(),
      theme: AppTheme.lightTheme,
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Không tài khoản');
    await tester.enterText(find.byType(TextFormField).at(1), '500');
    final saveButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Lưu'),
    );
    saveButton.onPressed!();
    await pumpDebtFrames(tester);

    expect(find.text('Vui lòng chọn tài khoản'), findsOneWidget);
    expect(await runDebtValue(tester, 'validation: đọc số giao dịch', fixture.transactionCount), 0);
    await _dungDeQuanSat(tester, 'thông báo thiếu tài khoản');
  });

  // Kiểm tra validation thanh toán chặn số tiền lớn hơn dư nợ còn lại,
  // nhằm bảo đảm không phát sinh lịch sử trả nợ sai từ giao diện.
  testWidgets('Luồng validation giao diện từ chối thanh toán vượt dư nợ', (
    tester,
  ) async {
    final fixture = await _taoFixtureTichHop(tester);
    addTearDown(fixture.dispose);
    final loan = await runDebtValue(
      tester,
      'validation thanh toán: tạo khoản vay',
      () => _themKhoanDebt(fixture, personName: 'Alice', amount: 500),
    );
    await pumpDebtWidgetWithFixture(
      tester,
      fixture: fixture,
      child: PaymentScreen(loan: loan),
      theme: AppTheme.lightTheme,
    );

    await tester.enterText(find.byType(TextFormField).first, '600');
    final saveButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Lưu thanh toán'),
    );
    saveButton.onPressed!();
    await pumpDebtFrames(tester);

    expect(find.text('Số tiền không được vượt quá dư nợ còn lại'), findsOneWidget);
    expect(await runDebtValue(tester, 'validation thanh toán: đọc số lần trả', fixture.paymentCount), 0);
    await _dungDeQuanSat(tester, 'validation số tiền thanh toán');
  });
}

/// Tạm dừng có chủ đích để người kiểm thử quan sát từng trạng thái trên Android.
Future<void> _dungDeQuanSat(WidgetTester tester, String trangThai) async {
  // Delay chỉ dành cho integration test để quan sát UI trên thiết bị Android.
  debugDebtStep('quan sát UI: $trangThai');
  await tester.runAsync(
    () async => Future<void>.delayed(_thoiGianQuanSat),
  );
}

/// Khởi tạo dữ liệu biệt lập cho mỗi flow integration mà không dùng DB thật của app.
Future<DebtDatabaseFixture> _taoFixtureTichHop(
  WidgetTester tester, {
  bool seedAccount = true,
}) {
  return runDebtValue(
    tester,
    'tích hợp fixture: mở cơ sở dữ liệu và seed dữ liệu',
    () async {
      final db = await openDatabase(inMemoryDatabasePath);
      return seedDebtDatabaseFixture(
        db,
        initialBalance: 1000,
        seedAccount: seedAccount,
      );
    },
  );
}

/// Seed loan qua DAO cho các flow không cần kiểm tra riêng thao tác nhập form tạo mới.
Future<Loan> _themKhoanDebt(
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
      startDate: now.subtract(const Duration(days: 2)),
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
