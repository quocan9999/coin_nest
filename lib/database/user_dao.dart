import '../models/user.dart';
import 'database_helper.dart';

/// Data access object for the [User] table.
class UserDao {
  final _dbHelper = DatabaseHelper.instance;

  /// Insert a new user. Returns the auto-generated id.
  Future<int> insert(User user) async {
    final db = await _dbHelper.database;
    return db.insert('users', user.toMap());
  }

  /// Find a user by phone number.
  Future<User?> findByPhone(String phone) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [phone],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  /// Find a user by id.
  Future<User?> findById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  /// Update a user's profile (name, avatar).
  Future<int> update(User user) async {
    final db = await _dbHelper.database;
    return db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Update the password hash and salt for a user.
  Future<int> updatePassword(
      int userId, String newHash, String newSalt) async {
    final db = await _dbHelper.database;
    return db.update(
      'users',
      {
        'password_hash': newHash,
        'password_salt': newSalt,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Delete a user and all associated data (CASCADE).
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  /// Check if a phone is already registered.
  Future<bool> phoneExists(String phone) async {
    final user = await findByPhone(phone);
    return user != null;
  }
}
