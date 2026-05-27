import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'debt_database_fixture.dart';

Future<DebtDatabaseFixture> openFfiDebtDatabaseFixture({
  double initialBalance = 1000000,
  bool seedAccount = true,
}) async {
  sqfliteFfiInit();

  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  return seedDebtDatabaseFixture(
    db,
    initialBalance: initialBalance,
    seedAccount: seedAccount,
  );
}
