import 'dart:async';

import 'package:coin_nest/providers/account_provider.dart';
import 'package:coin_nest/providers/auth_provider.dart';
import 'package:coin_nest/providers/backup_alert_provider.dart';
import 'package:coin_nest/providers/loan_provider.dart';
import 'package:coin_nest/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'debt_database_fixture.dart';
import 'fake_auth_service.dart';

const _debtHostKey = ValueKey<String>('debt-test-route-host');

/// Gom fixture và các provider đang được widget sử dụng để assertion đọc đúng state.
class DebtWidgetHarness {
  DebtWidgetHarness({
    required this.fixture,
    required this.authProvider,
    required this.accountProvider,
    required this.transactionProvider,
    required this.loanProvider,
  });

  final DebtDatabaseFixture fixture;
  final AuthProvider authProvider;
  final AccountProvider accountProvider;
  final TransactionProvider transactionProvider;
  final LoanProvider loanProvider;
}

/// Dựng màn debt thật với auth giả và provider đã nạp từ database biệt lập.
///
/// `loanProviderOverride` chỉ phục vụ case cần kiểm soát vòng đời tải dữ liệu,
/// ví dụ tránh gọi SQLite FFI từ fake-async zone của widget test.
Future<DebtWidgetHarness> pumpDebtWidgetWithFixture(
  WidgetTester tester, {
  required DebtDatabaseFixture fixture,
  required Widget child,
  ThemeData? theme,
  LoanProvider? loanProviderOverride,
}) async {
  debugDebtStep('harness: thiết lập SharedPreferences giả');
  SharedPreferences.setMockInitialValues({});

  late AuthProvider authProvider;
  late AccountProvider accountProvider;
  late BackupAlertProvider backupAlertProvider;
  late TransactionProvider transactionProvider;
  late LoanProvider loanProvider;

  await runDebtStep(
    tester,
    'harness: tạo provider và tải dữ liệu cơ sở dữ liệu ban đầu',
    () async {
      authProvider = AuthProvider(authService: FakeAuthService(fixture.user));
      await authProvider.login(
        identifier: fixture.user.email ?? 'debt-test@example.com',
        password: 'password',
      );

      accountProvider = AccountProvider();
      await accountProvider.loadAccounts(fixture.userId);

      backupAlertProvider = BackupAlertProvider();
      await backupAlertProvider.loadForUser(fixture.userId);

      transactionProvider = TransactionProvider();
      await transactionProvider.loadTransactions(fixture.userId);

      loanProvider = loanProviderOverride ?? LoanProvider();
      loanProvider.setTransactionProvider(transactionProvider);
      await loanProvider.loadLoans(fixture.userId);
    },
  );

  debugDebtStep('harness: dựng cây widget');
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<AccountProvider>.value(value: accountProvider),
        ChangeNotifierProvider<BackupAlertProvider>.value(
          value: backupAlertProvider,
        ),
        ChangeNotifierProvider<TransactionProvider>.value(
          value: transactionProvider,
        ),
        ChangeNotifierProvider<LoanProvider>.value(value: loanProvider),
      ],
      child: MaterialApp(
        theme: theme ?? ThemeData(useMaterial3: true),
        home: const _DebtTestRouteHost(),
      ),
    ),
  );
  await pumpDebtFrames(tester);
  debugDebtStep('harness: mở màn mục tiêu trên route nền ổn định');
  unawaited(
    Navigator.of(
      tester.element(find.byKey(_debtHostKey)),
    ).push<void>(MaterialPageRoute<void>(builder: (_) => child)),
  );
  await pumpDebtFrames(tester);
  debugDebtStep('harness: cây widget đã sẵn sàng');

  return DebtWidgetHarness(
    fixture: fixture,
    authProvider: authProvider,
    accountProvider: accountProvider,
    transactionProvider: transactionProvider,
    loanProvider: loanProvider,
  );
}

/// Route nền giữ Navigator còn hợp lệ khi màn được kiểm tra tự đóng sau submit.
class _DebtTestRouteHost extends StatelessWidget {
  const _DebtTestRouteHost();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox(key: _debtHostKey));
  }
}

/// Pump số frame hữu hạn để render animation ngắn mà không chờ vô hạn như settle.
Future<void> pumpDebtFrames(
  WidgetTester tester, {
  int frames = 5,
  Duration step = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}

/// Chạy thao tác async có side effect DB/provider trong real async zone có timeout.
Future<void> runDebtStep(
  WidgetTester tester,
  String label,
  Future<void> Function() action, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  debugDebtStep('start $label');
  await tester.runAsync(
    () async => action().timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException('Timed out during $label after $timeout');
      },
    ),
  );
  debugDebtStep('done $label');
}

/// Đọc giá trị async từ DB trong real async zone và trả kết quả cho assertion.
Future<T> runDebtValue<T>(
  WidgetTester tester,
  String label,
  Future<T> Function() action, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  debugDebtStep('start $label');
  final result = await tester.runAsync(
    () async => action().timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException('Timed out during $label after $timeout');
      },
    ),
  );
  debugDebtStep('done $label');
  if (result == null) {
    throw StateError('runAsync returned null during $label');
  }
  return result;
}

/// Poll state provider trong real async zone cho đến khi side effect hoàn tất.
Future<void> waitForDebtCondition(
  String label,
  bool Function() condition, {
  int maxAttempts = 50,
  Duration step = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < maxAttempts; i++) {
    if (condition()) return;
    await Future<void>.delayed(step);
  }
  throw TimeoutException('Timed out waiting for $label');
}

void debugDebtStep(String message) {
  // Checkpoint có chủ đích để debug widget test bị treo trong fake async.
  // Giữ log ngắn để biết chính xác bước cuối cùng trước khi timeout.
  // ignore: avoid_print
  print('[debt-widget-test] $message');
}

/// Pump giao diện theo predicate có giới hạn để phát hiện render không hội tụ.
Future<void> pumpDebtUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxFrames = 30,
  Duration step = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < maxFrames; i++) {
    if (condition()) return;
    await tester.pump(step);
  }
  if (!condition()) {
    throw TestFailure('Condition was not met after bounded debt widget pumps.');
  }
}
