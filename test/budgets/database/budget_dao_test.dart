import 'package:coin_nest/database/budget_dao.dart';
import 'package:coin_nest/models/budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../debt/helpers/debt_database_fixture.dart';
import '../../debt/helpers/debt_ffi_database.dart';

void main() {
  late DebtDatabaseFixture fixture;
  late BudgetDao budgetDao;

  setUp(() async {
    fixture = await openFfiDebtDatabaseFixture(initialBalance: 1000);
    budgetDao = BudgetDao();
  });

  tearDown(() async {
    await fixture.dispose();
  });

  test('han muc theo quy tinh dung chi tieu trong quy hien tai', () async {
    final secondAccountId = await fixture.insertAccount(
      name: 'Test Bank',
      balance: 2000,
    );
    final categoryId = await _insertExpenseCategory(fixture, 'Ăn uống');
    await _insertExpense(
      fixture,
      amount: 100,
      accountId: fixture.accountId!,
      categoryId: categoryId,
      date: '2026-04-15',
    );
    await _insertExpense(
      fixture,
      amount: 200,
      accountId: secondAccountId,
      categoryId: categoryId,
      date: '2026-06-04',
    );
    await _insertExpense(
      fixture,
      amount: 300,
      accountId: fixture.accountId!,
      categoryId: categoryId,
      date: '2026-03-31',
    );
    await _insertBudget(
      fixture,
      categoryId: categoryId,
      accountId: null,
      period: 'quarterly',
      name: 'Ăn uống quý này',
    );

    final budgets = await budgetDao.getAllByUser(
      fixture.userId,
      now: DateTime(2026, 6, 4),
    );

    expect(budgets.single.spentAmount, 300);
  });

  test('han muc theo quy loc dung tai khoan neu duoc chon', () async {
    final secondAccountId = await fixture.insertAccount(
      name: 'Test Bank',
      balance: 2000,
    );
    final categoryId = await _insertExpenseCategory(fixture, 'Xăng');
    await _insertExpense(
      fixture,
      amount: 100,
      accountId: fixture.accountId!,
      categoryId: categoryId,
      date: '2026-06-04',
    );
    await _insertExpense(
      fixture,
      amount: 200,
      accountId: secondAccountId,
      categoryId: categoryId,
      date: '2026-06-04',
    );
    await _insertBudget(
      fixture,
      categoryId: categoryId,
      accountId: secondAccountId,
      period: 'quarterly',
      name: 'Xăng tài khoản ngân hàng',
    );

    final budgets = await budgetDao.getAllByUser(
      fixture.userId,
      now: DateTime(2026, 6, 4),
    );

    expect(budgets.single.spentAmount, 200);
  });

  test('han muc khong lap lai dung khoang ngay cau hinh', () async {
    final categoryId = await _insertExpenseCategory(fixture, 'Cà phê');
    await _insertExpense(
      fixture,
      amount: 50,
      accountId: fixture.accountId!,
      categoryId: categoryId,
      date: '2026-05-10',
    );
    await _insertExpense(
      fixture,
      amount: 70,
      accountId: fixture.accountId!,
      categoryId: categoryId,
      date: '2026-06-10',
    );
    await _insertBudget(
      fixture,
      categoryId: categoryId,
      accountId: null,
      period: 'none',
      name: 'Cà phê một lần',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 5, 31),
    );

    final budgets = await budgetDao.getAllByUser(
      fixture.userId,
      now: DateTime(2026, 6, 4),
    );

    expect(budgets.single.spentAmount, 50);
  });
}

Future<int> _insertExpenseCategory(DebtDatabaseFixture fixture, String name) {
  final now = DateTime(2026, 6, 4).toIso8601String();
  return fixture.db.insert('categories', {
    'user_id': fixture.userId,
    'name': name,
    'type': 'expense',
    'icon_name': 'food',
    'color': '#42A5F5',
    'sort_order': 20,
    'is_default': 0,
    'is_active': 1,
    'created_at': now,
  });
}

Future<int> _insertExpense(
  DebtDatabaseFixture fixture, {
  required double amount,
  required int accountId,
  required int categoryId,
  required String date,
}) {
  final now = DateTime(2026, 6, 4).toIso8601String();
  return fixture.db.insert('transactions', {
    'user_id': fixture.userId,
    'account_id': accountId,
    'category_id': categoryId,
    'type': 'expense',
    'amount': amount,
    'note': 'Test expense',
    'date': date,
    'time': '08:00',
    'created_at': now,
    'updated_at': now,
  });
}

Future<int> _insertBudget(
  DebtDatabaseFixture fixture, {
  required int categoryId,
  required int? accountId,
  required String period,
  required String name,
  DateTime? startDate,
  DateTime? endDate,
}) {
  final now = DateTime(2026, 6, 4).toIso8601String();
  return BudgetDao().insert(
    Budget(
      userId: fixture.userId,
      categoryId: categoryId,
      accountId: accountId,
      name: name,
      amount: 1000,
      period: period,
      startDate: startDate ?? DateTime(2026, 1),
      endDate: endDate,
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
    ),
  );
}
