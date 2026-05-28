import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'debt_database_fixture.dart';
import 'debt_ffi_database.dart';
import 'debt_widget_harness.dart';

/// Tạo fixture FFI và dựng widget debt trong một lần gọi cho screen test đơn giản.
Future<DebtWidgetHarness> pumpDebtWidget(
  WidgetTester tester, {
  required Widget child,
  double initialBalance = 1000000,
  bool seedAccount = true,
}) async {
  late final DebtDatabaseFixture fixture;
  await runDebtStep(
    tester,
    'fixture: mở cơ sở dữ liệu FFI và tạo dữ liệu vay mẫu',
    () async {
      fixture = await openFfiDebtDatabaseFixture(
        initialBalance: initialBalance,
        seedAccount: seedAccount,
      );
    },
  );
  addTearDown(fixture.dispose);

  return pumpDebtWidgetWithFixture(
    tester,
    fixture: fixture,
    child: child,
  );
}
