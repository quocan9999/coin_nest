import '../models/loan.dart';
import 'database_helper.dart';

/// Data access object for the [Loan] table.
class LoanDao {
  final _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Loan loan) async {
    final db = await _dbHelper.database;
    return db.insert('loans', loan.toMap());
  }

  Future<List<Loan>> getAllByUser(int userId, {String? status, String? type}) async {
    final db = await _dbHelper.database;

    final where = StringBuffer('l.user_id = ?');
    final args = <dynamic>[userId];

    if (status != null) {
      where.write(' AND l.status = ?');
      args.add(status);
    }
    if (type != null) {
      where.write(' AND l.type = ?');
      args.add(type);
    }

    final result = await db.rawQuery('''
      SELECT l.*, a.name as account_name
      FROM loans l
      LEFT JOIN accounts a ON l.account_id = a.id
      WHERE $where
      ORDER BY l.created_at DESC
    ''', args);

    return result.map((m) => Loan.fromMap(m)).toList();
  }

  Future<Loan?> findById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT l.*, a.name as account_name
      FROM loans l
      LEFT JOIN accounts a ON l.account_id = a.id
      WHERE l.id = ?
      LIMIT 1
    ''', [id]);
    if (result.isEmpty) return null;
    return Loan.fromMap(result.first);
  }

  Future<int> update(Loan loan) async {
    final db = await _dbHelper.database;
    return db.update(
      'loans',
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  /// Record a payment toward a loan.
  Future<void> recordPayment(int loanId, double amount) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE loans SET remaining_amount = MAX(remaining_amount - ?, 0), '
        'updated_at = ? WHERE id = ?',
        [amount, DateTime.now().toIso8601String(), loanId],
      );

      // Auto-complete if fully paid
      final rows = await txn.query('loans', where: 'id = ?', whereArgs: [loanId]);
      if (rows.isNotEmpty) {
        final remaining = (rows.first['remaining_amount'] as num).toDouble();
        if (remaining <= 0) {
          await txn.update(
            'loans',
            {'status': 'paid', 'updated_at': DateTime.now().toIso8601String()},
            where: 'id = ?',
            whereArgs: [loanId],
          );
        }
      }
    });
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete('loans', where: 'id = ?', whereArgs: [id]);
  }

  /// Get summary: total borrowed, total lent, for a user.
  Future<Map<String, double>> getSummary(int userId) async {
    final db = await _dbHelper.database;
    final borrowed = await db.rawQuery(
      'SELECT COALESCE(SUM(remaining_amount), 0) as total '
      'FROM loans WHERE user_id = ? AND type = ? AND status = ?',
      [userId, 'borrow', 'active'],
    );
    final lent = await db.rawQuery(
      'SELECT COALESCE(SUM(remaining_amount), 0) as total '
      'FROM loans WHERE user_id = ? AND type = ? AND status = ?',
      [userId, 'lend', 'active'],
    );
    return {
      'borrowed': (borrowed.first['total'] as num).toDouble(),
      'lent': (lent.first['total'] as num).toDouble(),
    };
  }
}
