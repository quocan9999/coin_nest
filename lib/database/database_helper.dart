import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:coin_nest/utils/constants.dart';

/// Resolved database helper draft for merging main-GiaHao + feature/debt.
///
/// Intended direction:
/// - Treat feature/debt Firebase auth as the source of truth.
/// - Keep feature/debt's users schema: every new local user must map to a
///   Firebase Auth user through firebase_uid.
/// - Use version 3 as the Firebase-auth baseline from feature/debt.
/// - Only recreate data when upgrading from a pre-baseline local-auth schema.
/// - Preserve data for future upgrades by adding explicit versioned migrations.
/// - Add feature/debt loan payment schema and loan columns.
/// - Keep report-friendly default categories and add debt categories.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static const int _firebaseAuthBaselineVersion = 3;
  static const List<Map<String, Object>> _defaultExpenseCategories = [
    {'name': 'Cho mượn', 'icon_name': 'lend', 'color': '#FF7043', 'sort': 1},
    {'name': 'Trả nợ', 'icon_name': 'loan', 'color': '#8A5100', 'sort': 2},
    {
      'name': AppConstants.autoExpenseCategoryName,
      'icon_name': 'auto_record',
      'color': '#BB1614',
      'sort': 90,
    },
  ];
  static const List<Map<String, Object>> _defaultIncomeCategories = [
    {'name': 'Vay mượn', 'icon_name': 'loan', 'color': '#42A5F5', 'sort': 1},
    {'name': 'Thu nợ', 'icon_name': 'lend', 'color': '#66BB6A', 'sort': 2},
    {
      'name': 'Tiết kiệm lãi',
      'icon_name': 'interest',
      'color': '#26C6DA',
      'sort': 3,
    },
    {
      'name': AppConstants.autoIncomeCategoryName,
      'icon_name': 'auto_record',
      'color': '#006E1C',
      'sort': 90,
    },
  ];

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  @visibleForTesting
  Future<void> useDatabaseForTesting(Database database) async {
    // Chỉ dùng trong test: các DAO đang đi qua singleton DatabaseHelper,
    // nên test cần trỏ singleton này sang DB in-memory thay vì DB thật.
    final existing = _database;
    if (existing != null && existing.isOpen && existing != database) {
      await existing.close();
    }
    _database = database;
  }

  @visibleForTesting
  Future<void> createSchemaForTesting(DatabaseExecutor db) async {
    // Chỉ dùng trong test khi tự mở DB in-memory; runtime vẫn đi qua onCreate.
    await _onConfigure(db);
    await _createAllTables(db);
    await _createIndexes(db);
  }

  @visibleForTesting
  Future<void> resetForTesting() async {
    // Dọn singleton sau mỗi test để test sau không dùng nhầm DB cũ.
    await close();
  }

  Future<Database> _initDatabase() async {
    final path = await _databasePathByName(AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(DatabaseExecutor db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await db.transaction((txn) async {
        if (oldVersion < _firebaseAuthBaselineVersion) {
          await _dropAllTables(txn);
          await _createAllTables(txn);
          await _createIndexes(txn);
          return;
        }

        await _migratePreservingData(txn, oldVersion, newVersion);
        await _createAllTables(txn);
        await _createIndexes(txn);
      });
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> _dropAllTables(DatabaseExecutor db) async {
    await db.execute('DROP TABLE IF EXISTS feedbacks');
    await db.execute('DROP TABLE IF EXISTS budgets');
    await db.execute('DROP TABLE IF EXISTS loan_payments');
    await db.execute('DROP TABLE IF EXISTS transactions');
    await db.execute('DROP TABLE IF EXISTS loans');
    await db.execute('DROP TABLE IF EXISTS categories');
    await db.execute('DROP TABLE IF EXISTS accounts');
    await db.execute('DROP TABLE IF EXISTS users');
  }

  Future<void> _migratePreservingData(
    DatabaseExecutor db,
    int oldVersion,
    int newVersion,
  ) async {
    if (newVersion <= oldVersion) return;

    // Add future migrations here. Example:
    //
    // if (oldVersion < 4) {
    //   await _addColumnIfMissing(
    //     db,
    //     'transactions',
    //     'sync_status',
    //     "TEXT NOT NULL DEFAULT 'pending'",
    //   );
    // }
    //
    // Keep migrations additive whenever possible so existing users keep their
    // accounts, transactions, loans, and report data.
    if (oldVersion < 4) {
      await _seedDefaultCategoriesForExistingUsers(db);
    }
    if (oldVersion < 5) {
      await _rebuildBudgetsForExtendedPeriods(db);
    }
    if (oldVersion < 6) {
      await _addColumnIfMissing(
        db,
        'loans',
        'interest_paid',
        'REAL NOT NULL DEFAULT 0',
      );
      await _addColumnIfMissing(
        db,
        'loan_payments',
        'principal_amount',
        'REAL NOT NULL DEFAULT 0',
      );
      await _addColumnIfMissing(
        db,
        'loan_payments',
        'interest_amount',
        'REAL NOT NULL DEFAULT 0',
      );
      await db.execute('''
        UPDATE loan_payments
        SET principal_amount = amount
        WHERE principal_amount = 0 AND interest_amount = 0
      ''');
    }
  }

  Future<void> _rebuildBudgetsForExtendedPeriods(DatabaseExecutor db) async {
    final existing = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'budgets'",
    );
    if (existing.isEmpty) return;

    await db.execute('ALTER TABLE budgets RENAME TO budgets_old_v5');
    await _createBudgetsTable(db);
    await db.execute('''
      INSERT INTO budgets (
        id,
        user_id,
        category_id,
        account_id,
        name,
        amount,
        period,
        start_date,
        end_date,
        is_active,
        created_at,
        updated_at
      )
      SELECT
        id,
        user_id,
        category_id,
        account_id,
        name,
        amount,
        CASE
          WHEN period IN ('none','daily','weekly','monthly','quarterly','yearly','custom')
            THEN period
          ELSE 'monthly'
        END,
        start_date,
        end_date,
        is_active,
        created_at,
        updated_at
      FROM budgets_old_v5
    ''');
    await db.execute('DROP TABLE budgets_old_v5');
  }

  // ignore: unused_element
  Future<void> _addColumnIfMissing(
    DatabaseExecutor db,
    String table,
    String column,
    String definition,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == column);
    if (exists) return;

    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }

  Future<void> _seedDefaultCategoriesForExistingUsers(
    DatabaseExecutor db,
  ) async {
    final users = await db.query('users', columns: ['id']);
    final now = DateTime.now().toIso8601String();

    for (final user in users) {
      final userId = user['id'] as int;
      await _seedDefaultCategoriesForUser(db, userId, now);
    }
  }

  Future<void> _createAllTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        phone TEXT UNIQUE,
        email TEXT UNIQUE,
        password_hash TEXT,
        password_salt TEXT,
        firebase_uid TEXT NOT NULL UNIQUE,
        auth_provider TEXT NOT NULL CHECK(auth_provider IN ('phone','email','google')),
        avatar_path TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('cash','bank','e_wallet','savings','credit_card','other')),
        balance REAL NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'VND',
        icon_name TEXT,
        color TEXT,
        is_included_in_total INTEGER NOT NULL DEFAULT 1,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('income','expense')),
        icon_name TEXT NOT NULL,
        color TEXT,
        parent_id INTEGER,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_default INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS loans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('borrow','lend')),
        person_name TEXT NOT NULL,
        amount REAL NOT NULL CHECK(amount >= 0),
        remaining_amount REAL NOT NULL CHECK(remaining_amount >= 0),
        interest_rate REAL DEFAULT 0,
        interest_calculated REAL NOT NULL DEFAULT 0,
        interest_paid REAL NOT NULL DEFAULT 0,
        note TEXT,
        start_date TEXT NOT NULL,
        due_date TEXT,
        status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','paid','overdue')),
        account_id INTEGER,
        transaction_id INTEGER,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        account_id INTEGER NOT NULL,
        to_account_id INTEGER,
        category_id INTEGER,
        type TEXT NOT NULL CHECK(type IN ('income','expense','transfer','loan','lend','balance_adjust')),
        amount REAL NOT NULL CHECK(amount >= 0),
        note TEXT,
        date TEXT NOT NULL,
        time TEXT,
        loan_id INTEGER,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
        FOREIGN KEY (to_account_id) REFERENCES accounts(id) ON DELETE SET NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
        FOREIGN KEY (loan_id) REFERENCES loans(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS loan_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        loan_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        transaction_id INTEGER,
        amount REAL NOT NULL CHECK(amount > 0),
        principal_amount REAL NOT NULL DEFAULT 0,
        interest_amount REAL NOT NULL DEFAULT 0,
        payment_date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (loan_id) REFERENCES loans(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL
      )
    ''');

    await _createBudgetsTable(db);

    await db.execute('''
      CREATE TABLE IF NOT EXISTS feedbacks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('bug','feature','improvement','other')),
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        rating INTEGER CHECK(rating >= 1 AND rating <= 5),
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createBudgetsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category_id INTEGER,
        account_id INTEGER,
        name TEXT NOT NULL,
        amount REAL NOT NULL CHECK(amount > 0),
        period TEXT NOT NULL CHECK(period IN ('none','daily','weekly','monthly','quarterly','yearly','custom')),
        start_date TEXT NOT NULL,
        end_date TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
        FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON transactions(user_id, date DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_account ON transactions(account_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_loan ON transactions(loan_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_accounts_user ON accounts(user_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_categories_user ON categories(user_id, type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_loans_user ON loans(user_id, status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_loans_transaction ON loans(transaction_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_budgets_user ON budgets(user_id, is_active)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_loan_payments_loan ON loan_payments(loan_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_loan_payments_user_date ON loan_payments(user_id, payment_date DESC)',
    );
  }

  /// Seed debt-related categories for a user.
  Future<void> seedDefaultCategories(int userId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await _seedDefaultCategoriesForUser(txn, userId, now);
    });
  }

  Future<void> _seedDefaultCategoriesForUser(
    DatabaseExecutor db,
    int userId,
    String now,
  ) async {
    for (final category in _defaultExpenseCategories) {
      await _insertCategoryIfMissing(db, userId, 'expense', category, now);
    }
    for (final category in _defaultIncomeCategories) {
      await _insertCategoryIfMissing(db, userId, 'income', category, now);
    }
  }

  Future<void> _insertCategoryIfMissing(
    DatabaseExecutor db,
    int userId,
    String type,
    Map<String, Object> category,
    String now,
  ) async {
    final existing = await db.query(
      'categories',
      columns: ['id'],
      where: 'user_id = ? AND type = ? AND name = ?',
      whereArgs: [userId, type, category['name']],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    await db.insert('categories', {
      'user_id': userId,
      'name': category['name'],
      'type': type,
      'icon_name': category['icon_name'],
      'color': category['color'],
      'sort_order': category['sort'],
      'is_default': 1,
      'is_active': 1,
      'created_at': now,
    });
  }

  /// Seed a default cash account for a new user.
  Future<void> seedDefaultAccount(int userId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final existing = await db.query(
      'accounts',
      columns: ['id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    await db.insert('accounts', {
      'user_id': userId,
      'name': 'Tiền mặt',
      'type': 'cash',
      'balance': 0,
      'currency': 'VND',
      'icon_name': 'cash',
      'is_included_in_total': 1,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }

  Future<String> getDatabasePath() async {
    return _databasePathByName(AppConstants.dbName);
  }

  Future<String> _databasePathByName(String dbName) async {
    final dir = await getApplicationDocumentsDirectory();
    return join(dir.path, dbName);
  }
}
