import 'package:coin_nest/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../debt/helpers/debt_ffi_database.dart';

void main() {
  test('seed hạng mục tự động mặc định cho user', () async {
    final fixture = await openFfiDebtDatabaseFixture(initialBalance: 1000);
    addTearDown(fixture.dispose);

    final categories = await fixture.db.query(
      'categories',
      columns: ['name', 'type', 'icon_name', 'is_default', 'is_active'],
      where: 'user_id = ?',
      whereArgs: [fixture.userId],
    );

    expect(
      categories,
      contains(containsPair('name', AppConstants.autoExpenseCategoryName)),
    );
    expect(
      categories,
      contains(containsPair('name', AppConstants.autoIncomeCategoryName)),
    );
    expect(
      categories.where(
        (row) =>
            row['name'] == AppConstants.autoExpenseCategoryName &&
            row['type'] == AppConstants.typeExpense &&
            row['icon_name'] == 'auto_record' &&
            row['is_default'] == 1 &&
            row['is_active'] == 1,
      ),
      hasLength(1),
    );
    expect(
      categories.where(
        (row) =>
            row['name'] == AppConstants.autoIncomeCategoryName &&
            row['type'] == AppConstants.typeIncome &&
            row['icon_name'] == 'auto_record' &&
            row['is_default'] == 1 &&
            row['is_active'] == 1,
      ),
      hasLength(1),
    );
  });
}
