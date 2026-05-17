import '../models/budget.dart';
import 'database_helper.dart';

/// Data access object for the [Budget] table.
class BudgetDao {
  final _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Budget budget) async {
    final db = await _dbHelper.database;
    return db.insert('budgets', budget.toMap());
  }

  /// Get all budgets with their current spent amount computed from transactions.
  Future<List<Budget>> getAllByUser(int userId, {bool activeOnly = true}) async {
    final db = await _dbHelper.database;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1)
        .toIso8601String()
        .split('T')
        .first;
    final monthEnd = DateTime(now.year, now.month + 1, 0)
        .toIso8601String()
        .split('T')
        .first;

    final where = activeOnly ? 'AND b.is_active = 1' : '';

    final result = await db.rawQuery('''
      SELECT b.*,
             c.name as category_name,
             c.icon_name as category_icon_name,
             COALESCE(
               (SELECT SUM(t.amount) FROM transactions t
                WHERE t.user_id = b.user_id
                  AND t.type = 'expense'
                  AND (b.category_id IS NULL OR t.category_id = b.category_id)
                  AND t.date >= CASE b.period
                    WHEN 'monthly' THEN ?
                    WHEN 'yearly' THEN strftime('%Y', 'now') || '-01-01'
                    ELSE b.start_date
                  END
                  AND t.date <= CASE b.period
                    WHEN 'monthly' THEN ?
                    WHEN 'yearly' THEN strftime('%Y', 'now') || '-12-31'
                    ELSE COALESCE(b.end_date, '9999-12-31')
                  END
               ), 0
             ) as spent_amount
      FROM budgets b
      LEFT JOIN categories c ON b.category_id = c.id
      WHERE b.user_id = ? $where
      ORDER BY b.created_at DESC
    ''', [monthStart, monthEnd, userId]);

    return result.map((m) => Budget.fromMap(m)).toList();
  }

  Future<Budget?> findById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Budget.fromMap(result.first);
  }

  Future<int> update(Budget budget) async {
    final db = await _dbHelper.database;
    return db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }
}
