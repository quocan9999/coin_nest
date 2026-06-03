import '../models/budget.dart';
import '../utils/budget_period.dart';
import 'database_helper.dart';

/// Data access object for the [Budget] table.
class BudgetDao {
  final _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Budget budget) async {
    final db = await _dbHelper.database;
    return db.insert('budgets', budget.toMap());
  }

  /// Get all budgets with their current spent amount computed from transactions.
  Future<List<Budget>> getAllByUser(
    int userId, {
    bool activeOnly = true,
    DateTime? now,
  }) async {
    final db = await _dbHelper.database;

    final where = activeOnly ? 'AND b.is_active = 1' : '';

    final result = await db.rawQuery(
      '''
      SELECT b.*,
             c.name as category_name,
             c.icon_name as category_icon_name,
             a.name as account_name
      FROM budgets b
      LEFT JOIN categories c ON b.category_id = c.id
      LEFT JOIN accounts a ON b.account_id = a.id
      WHERE b.user_id = ? $where
      ORDER BY b.created_at DESC
    ''',
      [userId],
    );

    final budgets = <Budget>[];
    for (final row in result) {
      final budget = Budget.fromMap(row);
      final spentAmount = await _getSpentAmount(
        budget,
        now: now ?? DateTime.now(),
      );
      budgets.add(Budget.fromMap({...row, 'spent_amount': spentAmount}));
    }
    return budgets;
  }

  Future<double> _getSpentAmount(Budget budget, {required DateTime now}) async {
    final db = await _dbHelper.database;
    final range = BudgetPeriod.currentRange(
      period: budget.period,
      startDate: budget.startDate,
      endDate: budget.endDate,
      now: now,
    );
    final query = StringBuffer('''
      SELECT COALESCE(SUM(t.amount), 0) as total
      FROM transactions t
      WHERE t.user_id = ?
        AND t.type = 'expense'
        AND (? IS NULL OR t.category_id = ?)
        AND (? IS NULL OR t.account_id = ?)
        AND t.date >= ?
    ''');
    final args = <Object?>[
      budget.userId,
      budget.categoryId,
      budget.categoryId,
      budget.accountId,
      budget.accountId,
      BudgetPeriod.toDbDate(range.start),
    ];

    if (range.end != null) {
      query.write(' AND t.date <= ?');
      args.add(BudgetPeriod.toDbDate(range.end!));
    }

    final result = await db.rawQuery(query.toString(), args);
    return ((result.first['total'] as num?) ?? 0).toDouble();
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
