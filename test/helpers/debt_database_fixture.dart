import 'package:coin_nest/database/database_helper.dart';
import 'package:coin_nest/models/user.dart';
import 'package:sqflite/sqflite.dart';

class DebtDatabaseFixture {
  DebtDatabaseFixture({
    required this.db,
    required this.user,
    required this.userId,
    required this.accountId,
    required this.borrowInitialCategoryId,
    required this.lendInitialCategoryId,
    required this.borrowPaymentCategoryId,
    required this.lendPaymentCategoryId,
  });

  final Database db;
  final User user;
  final int userId;
  final int? accountId;
  final int borrowInitialCategoryId;
  final int lendInitialCategoryId;
  final int borrowPaymentCategoryId;
  final int lendPaymentCategoryId;

  Future<double> accountBalance() async {
    if (accountId == null) return 0;
    return accountBalanceFor(accountId!);
  }

  Future<double> accountBalanceFor(int id) async {
    final rows = await db.query(
      'accounts',
      columns: ['balance'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return (rows.first['balance'] as num).toDouble();
  }

  Future<int> insertAccount({
    required String name,
    required double balance,
  }) {
    final now = DateTime(2026, 5, 24, 8).toIso8601String();
    return db.insert('accounts', {
      'user_id': userId,
      'name': name,
      'type': 'bank',
      'balance': balance,
      'currency': 'VND',
      'icon_name': 'bank',
      'is_included_in_total': 1,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<int> insertOtherUser() {
    final now = DateTime(2026, 5, 24, 8).toIso8601String();
    // User phụ chỉ phục vụ xác nhận truy vấn debt không rò dữ liệu chéo user.
    return db.insert('users', {
      'full_name': 'Debt Other User',
      'phone': '0911111111',
      'email': 'debt-other@example.com',
      'firebase_uid': 'debt-other-firebase-uid',
      'auth_provider': 'email',
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<Map<String, Object?>>> transactionsForLoan(int loanId) {
    return db.query(
      'transactions',
      where: 'loan_id = ?',
      whereArgs: [loanId],
      orderBy: 'id ASC',
    );
  }

  Future<int> transactionCount() async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS total FROM transactions');
    return rows.first['total'] as int;
  }

  Future<int> paymentCount() async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS total FROM loan_payments');
    return rows.first['total'] as int;
  }

  Future<void> dispose() async {
    await DatabaseHelper.instance.resetForTesting();
  }
}

Future<DebtDatabaseFixture> seedDebtDatabaseFixture(
  Database db, {
  double initialBalance = 1000000,
  bool seedAccount = true,
}) async {
  await DatabaseHelper.instance.useDatabaseForTesting(db);
  await DatabaseHelper.instance.createSchemaForTesting(db);

  final now = DateTime(2026, 5, 24, 8).toIso8601String();
  final userId = await db.insert('users', {
    'full_name': 'Debt Test User',
    'phone': '0900000000',
    'email': 'debt-test@example.com',
    'firebase_uid': 'debt-test-firebase-uid',
    'auth_provider': 'email',
    'created_at': now,
    'updated_at': now,
  });

  int? accountId;
  if (seedAccount) {
    accountId = await db.insert('accounts', {
      'user_id': userId,
      'name': 'Test Cash',
      'type': 'cash',
      'balance': initialBalance,
      'currency': 'VND',
      'icon_name': 'cash',
      'is_included_in_total': 1,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });
  }

  await DatabaseHelper.instance.seedDefaultCategories(userId);

  Future<int> categoryId(String type, int sortOrder) async {
    final rows = await db.query(
      'categories',
      columns: ['id'],
      where: 'user_id = ? AND type = ? AND sort_order = ?',
      whereArgs: [userId, type, sortOrder],
      limit: 1,
    );
    return rows.single['id'] as int;
  }

  final user = User(
    id: userId,
    fullName: 'Debt Test User',
    phone: '0900000000',
    email: 'debt-test@example.com',
    firebaseUid: 'debt-test-firebase-uid',
    authProvider: 'email',
    createdAt: DateTime.parse(now),
    updatedAt: DateTime.parse(now),
  );

  return DebtDatabaseFixture(
    db: db,
    user: user,
    userId: userId,
    accountId: accountId,
    borrowInitialCategoryId: await categoryId('income', 1),
    lendInitialCategoryId: await categoryId('expense', 1),
    borrowPaymentCategoryId: await categoryId('expense', 2),
    lendPaymentCategoryId: await categoryId('income', 2),
  );
}
