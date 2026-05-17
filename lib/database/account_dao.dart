import '../models/account.dart';
import 'database_helper.dart';

/// Data access object for the [Account] table.
class AccountDao {
  final _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Account account) async {
    final db = await _dbHelper.database;
    return db.insert('accounts', account.toMap());
  }

  Future<List<Account>> getAllByUser(int userId, {bool activeOnly = true}) async {
    final db = await _dbHelper.database;
    final where = activeOnly ? 'user_id = ? AND is_active = 1' : 'user_id = ?';
    final result = await db.query(
      'accounts',
      where: where,
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
    return result.map((m) => Account.fromMap(m)).toList();
  }

  Future<Account?> findById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Account.fromMap(result.first);
  }

  Future<int> update(Account account) async {
    final db = await _dbHelper.database;
    return db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  /// Soft-delete: mark inactive instead of removing (preserves transaction history).
  Future<int> softDelete(int id) async {
    final db = await _dbHelper.database;
    return db.update(
      'accounts',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update balance by a delta (for transaction recording).
  Future<void> updateBalance(int accountId, double delta) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
      [delta, DateTime.now().toIso8601String(), accountId],
    );
  }

  /// Set balance to an exact value (for balance adjustment).
  Future<void> setBalance(int accountId, double newBalance) async {
    final db = await _dbHelper.database;
    await db.update(
      'accounts',
      {
        'balance': newBalance,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  /// Get total balance across all included accounts for a user.
  Future<double> getTotalBalance(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(balance), 0) as total '
      'FROM accounts WHERE user_id = ? AND is_active = 1 AND is_included_in_total = 1',
      [userId],
    );
    return (result.first['total'] as num).toDouble();
  }
}
