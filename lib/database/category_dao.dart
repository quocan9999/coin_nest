import '../models/category.dart';
import 'database_helper.dart';

/// Data access object for the [Category] table.
class CategoryDao {
  final _dbHelper = DatabaseHelper.instance;

  Future<int> insert(Category category) async {
    final db = await _dbHelper.database;
    return db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllByUser(int userId,
      {String? type, bool activeOnly = true}) async {
    final db = await _dbHelper.database;

    final where = StringBuffer('user_id = ?');
    final args = <dynamic>[userId];

    if (activeOnly) {
      where.write(' AND is_active = 1');
    }
    if (type != null) {
      where.write(' AND type = ?');
      args.add(type);
    }

    final result = await db.query(
      'categories',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'sort_order ASC, name ASC',
    );
    return result.map((m) => Category.fromMap(m)).toList();
  }

  Future<Category?> findById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Category.fromMap(result.first);
  }

  Future<int> update(Category category) async {
    final db = await _dbHelper.database;
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Soft-delete: mark inactive (preserves historical transactions).
  Future<int> softDelete(int id) async {
    final db = await _dbHelper.database;
    return db.update(
      'categories',
      {'is_active': 0},
      where: 'id = ? AND is_default = 0', // Prevent deleting default categories
      whereArgs: [id],
    );
  }

  /// Get expense categories for a user.
  Future<List<Category>> getExpenseCategories(int userId) async {
    return getAllByUser(userId, type: 'expense');
  }

  /// Get income categories for a user.
  Future<List<Category>> getIncomeCategories(int userId) async {
    return getAllByUser(userId, type: 'income');
  }
}
