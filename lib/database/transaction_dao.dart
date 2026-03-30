import '../models/transaction_model.dart';
import 'database_helper.dart';

/// Data access object for the [TransactionModel] table.
///
/// Report-oriented aggregation queries live here too so that heavy lifting
/// stays inside SQLite rather than Dart.
class TransactionDao {
  final _dbHelper = DatabaseHelper.instance;

  /// Insert a transaction and update account balances atomically.
  Future<int> insertWithBalance(TransactionModel txn) async {
    final db = await _dbHelper.database;
    late int txnId;

    await db.transaction((dbTxn) async {
      txnId = await dbTxn.insert('transactions', txn.toMap());

      // Update account balance based on transaction type
      switch (txn.type) {
        case 'income':
          await dbTxn.rawUpdate(
            'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
            [txn.amount, DateTime.now().toIso8601String(), txn.accountId],
          );
          break;
        case 'expense':
          await dbTxn.rawUpdate(
            'UPDATE accounts SET balance = balance - ?, updated_at = ? WHERE id = ?',
            [txn.amount, DateTime.now().toIso8601String(), txn.accountId],
          );
          break;
        case 'transfer':
          // Deduct from source
          await dbTxn.rawUpdate(
            'UPDATE accounts SET balance = balance - ?, updated_at = ? WHERE id = ?',
            [txn.amount, DateTime.now().toIso8601String(), txn.accountId],
          );
          // Add to destination
          if (txn.toAccountId != null) {
            await dbTxn.rawUpdate(
              'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
              [txn.amount, DateTime.now().toIso8601String(), txn.toAccountId],
            );
          }
          break;
        case 'balance_adjust':
          // Direct set handled elsewhere; or treat amount as delta
          break;
        case 'loan': // Borrowed money — added to account
          await dbTxn.rawUpdate(
            'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
            [txn.amount, DateTime.now().toIso8601String(), txn.accountId],
          );
          break;
        case 'lend': // Lent money — deducted from account
          await dbTxn.rawUpdate(
            'UPDATE accounts SET balance = balance - ?, updated_at = ? WHERE id = ?',
            [txn.amount, DateTime.now().toIso8601String(), txn.accountId],
          );
          break;
      }
    });

    return txnId;
  }

  /// Delete a transaction and reverse its balance impact.
  Future<void> deleteWithBalance(int txnId) async {
    final db = await _dbHelper.database;
    final rows = await db.query('transactions', where: 'id = ?', whereArgs: [txnId]);
    if (rows.isEmpty) return;

    final txn = TransactionModel.fromMap(rows.first);

    await db.transaction((dbTxn) async {
      // Reverse balance
      switch (txn.type) {
        case 'income':
          await dbTxn.rawUpdate(
            'UPDATE accounts SET balance = balance - ?, updated_at = ? WHERE id = ?',
            [txn.amount, DateTime.now().toIso8601String(), txn.accountId],
          );
          break;
        case 'expense':
          await dbTxn.rawUpdate(
            'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
            [txn.amount, DateTime.now().toIso8601String(), txn.accountId],
          );
          break;
        case 'transfer':
          await dbTxn.rawUpdate(
            'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
            [txn.amount, DateTime.now().toIso8601String(), txn.accountId],
          );
          if (txn.toAccountId != null) {
            await dbTxn.rawUpdate(
              'UPDATE accounts SET balance = balance - ?, updated_at = ? WHERE id = ?',
              [txn.amount, DateTime.now().toIso8601String(), txn.toAccountId],
            );
          }
          break;
        case 'loan':
          await dbTxn.rawUpdate(
            'UPDATE accounts SET balance = balance - ?, updated_at = ? WHERE id = ?',
            [txn.amount, DateTime.now().toIso8601String(), txn.accountId],
          );
          break;
        case 'lend':
          await dbTxn.rawUpdate(
            'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
            [txn.amount, DateTime.now().toIso8601String(), txn.accountId],
          );
          break;
        default:
          break;
      }

      await dbTxn.delete('transactions', where: 'id = ?', whereArgs: [txnId]);
    });
  }

  /// Fetch transactions for a user with joined category/account names.
  Future<List<TransactionModel>> getByUser(
    int userId, {
    String? startDate,
    String? endDate,
    String? type,
    int? categoryId,
    int? accountId,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    final db = await _dbHelper.database;

    final where = StringBuffer('t.user_id = ?');
    final args = <dynamic>[userId];

    if (startDate != null) {
      where.write(' AND t.date >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      where.write(' AND t.date <= ?');
      args.add(endDate);
    }
    if (type != null) {
      where.write(' AND t.type = ?');
      args.add(type);
    }
    if (categoryId != null) {
      where.write(' AND t.category_id = ?');
      args.add(categoryId);
    }
    if (accountId != null) {
      where.write(' AND (t.account_id = ? OR t.to_account_id = ?)');
      args.addAll([accountId, accountId]);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      where.write(' AND (t.note LIKE ? OR c.name LIKE ?)');
      final q = '%$searchQuery%';
      args.addAll([q, q]);
    }

    var sql = '''
      SELECT t.*,
             a.name as account_name,
             a2.name as to_account_name,
             c.name as category_name,
             c.icon_name as category_icon_name
      FROM transactions t
      LEFT JOIN accounts a ON t.account_id = a.id
      LEFT JOIN accounts a2 ON t.to_account_id = a2.id
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE $where
      ORDER BY t.date DESC, t.created_at DESC
    ''';

    if (limit != null) {
      sql += ' LIMIT $limit';
      if (offset != null) {
        sql += ' OFFSET $offset';
      }
    }

    final result = await db.rawQuery(sql, args);
    return result.map((m) => TransactionModel.fromMap(m)).toList();
  }

  // ─── Report Queries ────────────────────────────────────────────

  /// Total income in a date range.
  Future<double> totalIncome(int userId, String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions '
      'WHERE user_id = ? AND type = ? AND date >= ? AND date <= ?',
      [userId, 'income', startDate, endDate],
    );
    return (result.first['total'] as num).toDouble();
  }

  /// Total expense in a date range.
  Future<double> totalExpense(int userId, String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions '
      'WHERE user_id = ? AND type = ? AND date >= ? AND date <= ?',
      [userId, 'expense', startDate, endDate],
    );
    return (result.first['total'] as num).toDouble();
  }

  /// Spending by category in a date range (for pie chart).
  Future<List<Map<String, dynamic>>> expenseByCategory(
      int userId, String startDate, String endDate) async {
    final db = await _dbHelper.database;
    return db.rawQuery('''
      SELECT c.id, c.name, c.icon_name, c.color,
             COALESCE(SUM(t.amount), 0) as total
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE t.user_id = ? AND t.type = 'expense'
        AND t.date >= ? AND t.date <= ?
      GROUP BY c.id
      ORDER BY total DESC
    ''', [userId, startDate, endDate]);
  }

  /// Daily totals in a date range (for line/bar chart).
  Future<List<Map<String, dynamic>>> dailyTotals(
      int userId, String startDate, String endDate, String type) async {
    final db = await _dbHelper.database;
    return db.rawQuery('''
      SELECT date, COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE user_id = ? AND type = ? AND date >= ? AND date <= ?
      GROUP BY date
      ORDER BY date ASC
    ''', [userId, type, startDate, endDate]);
  }

  /// Monthly totals for a given year.
  Future<List<Map<String, dynamic>>> monthlyTotals(
      int userId, int year, String type) async {
    final db = await _dbHelper.database;
    return db.rawQuery('''
      SELECT strftime('%m', date) as month, COALESCE(SUM(amount), 0) as total
      FROM transactions
      WHERE user_id = ? AND type = ? AND strftime('%Y', date) = ?
      GROUP BY month
      ORDER BY month ASC
    ''', [userId, type, year.toString()]);
  }

  /// Spending by account in a date range.
  Future<List<Map<String, dynamic>>> expenseByAccount(
      int userId, String startDate, String endDate) async {
    final db = await _dbHelper.database;
    return db.rawQuery('''
      SELECT a.id, a.name, a.icon_name,
             COALESCE(SUM(t.amount), 0) as total
      FROM transactions t
      JOIN accounts a ON t.account_id = a.id
      WHERE t.user_id = ? AND t.type = 'expense'
        AND t.date >= ? AND t.date <= ?
      GROUP BY a.id
      ORDER BY total DESC
    ''', [userId, startDate, endDate]);
  }

  /// Recent N transactions.
  Future<List<TransactionModel>> getRecent(int userId, {int count = 5}) async {
    return getByUser(userId, limit: count);
  }
}
