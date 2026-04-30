import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../utils/constants.dart';

/// Singleton database helper - manages the SQLite lifecycle.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, AppConstants.dbName);

    return openDatabase(
      path,
      // Keep local DB versioning here so migrations can run even if constants lag.
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
      onOpen: _onOpen,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onOpen(Database db) async {
    await _ensureSchema(db);
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _createAllTables(db);
    await _ensureSchema(db);
    await _createIndexes(db);
  }

  Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
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
        note TEXT,
        start_date TEXT NOT NULL,
        due_date TEXT,
        status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','paid','overdue')),
        account_id INTEGER,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL
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
      CREATE TABLE IF NOT EXISTS budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category_id INTEGER,
        name TEXT NOT NULL,
        amount REAL NOT NULL CHECK(amount > 0),
        period TEXT NOT NULL CHECK(period IN ('daily','weekly','monthly','yearly','custom')),
        start_date TEXT NOT NULL,
        end_date TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');

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

  Future<void> _createIndexes(Database db) async {
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
      'CREATE INDEX IF NOT EXISTS idx_accounts_user ON accounts(user_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_categories_user ON categories(user_id, type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_loans_user ON loans(user_id, status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_budgets_user ON budgets(user_id, is_active)',
    );
  }

  Future<void> _ensureSchema(Database db) async {
    await _createAllTables(db);

    await _ensureColumns(db, 'users', {
      'full_name': "TEXT NOT NULL DEFAULT ''",
      'email': "TEXT NOT NULL DEFAULT ''",
      'password_hash': "TEXT NOT NULL DEFAULT ''",
      'password_salt': "TEXT NOT NULL DEFAULT ''",
      'avatar_path': 'TEXT',
      'created_at': "TEXT NOT NULL DEFAULT (datetime('now'))",
      'updated_at': "TEXT NOT NULL DEFAULT (datetime('now'))",
    });

    await _ensureColumns(db, 'accounts', {
      'user_id': 'INTEGER NOT NULL DEFAULT 0',
      'name': "TEXT NOT NULL DEFAULT ''",
      'type': "TEXT NOT NULL DEFAULT 'other'",
      'balance': 'REAL NOT NULL DEFAULT 0',
      'currency': "TEXT NOT NULL DEFAULT 'VND'",
      'icon_name': 'TEXT',
      'color': 'TEXT',
      'is_included_in_total': 'INTEGER NOT NULL DEFAULT 1',
      'is_active': 'INTEGER NOT NULL DEFAULT 1',
      'created_at': "TEXT NOT NULL DEFAULT (datetime('now'))",
      'updated_at': "TEXT NOT NULL DEFAULT (datetime('now'))",
    });

    await _ensureColumns(db, 'categories', {
      'user_id': 'INTEGER NOT NULL DEFAULT 0',
      'name': "TEXT NOT NULL DEFAULT ''",
      'type': "TEXT NOT NULL DEFAULT 'expense'",
      'icon_name': "TEXT NOT NULL DEFAULT 'category'",
      'color': 'TEXT',
      'parent_id': 'INTEGER',
      'sort_order': 'INTEGER NOT NULL DEFAULT 0',
      'is_default': 'INTEGER NOT NULL DEFAULT 0',
      'is_active': 'INTEGER NOT NULL DEFAULT 1',
      'created_at': "TEXT NOT NULL DEFAULT (datetime('now'))",
    });

    await _ensureColumns(db, 'transactions', {
      'user_id': 'INTEGER NOT NULL DEFAULT 0',
      'account_id': 'INTEGER NOT NULL DEFAULT 0',
      'to_account_id': 'INTEGER',
      'category_id': 'INTEGER',
      'type': "TEXT NOT NULL DEFAULT 'expense'",
      'amount': 'REAL NOT NULL DEFAULT 0',
      'note': 'TEXT',
      'date': "TEXT NOT NULL DEFAULT (date('now'))",
      'time': 'TEXT',
      'loan_id': 'INTEGER',
      'created_at': "TEXT NOT NULL DEFAULT (datetime('now'))",
      'updated_at': "TEXT NOT NULL DEFAULT (datetime('now'))",
    });

    await _ensureColumns(db, 'loans', {
      'user_id': 'INTEGER NOT NULL DEFAULT 0',
      'type': "TEXT NOT NULL DEFAULT 'borrow'",
      'person_name': "TEXT NOT NULL DEFAULT ''",
      'amount': 'REAL NOT NULL DEFAULT 0',
      'remaining_amount': 'REAL NOT NULL DEFAULT 0',
      'interest_rate': 'REAL DEFAULT 0',
      'note': 'TEXT',
      'start_date': "TEXT NOT NULL DEFAULT (date('now'))",
      'due_date': 'TEXT',
      'status': "TEXT NOT NULL DEFAULT 'active'",
      'account_id': 'INTEGER',
      'created_at': "TEXT NOT NULL DEFAULT (datetime('now'))",
      'updated_at': "TEXT NOT NULL DEFAULT (datetime('now'))",
    });

    await _ensureColumns(db, 'budgets', {
      'user_id': 'INTEGER NOT NULL DEFAULT 0',
      'category_id': 'INTEGER',
      'name': "TEXT NOT NULL DEFAULT ''",
      'amount': 'REAL NOT NULL DEFAULT 0',
      'period': "TEXT NOT NULL DEFAULT 'monthly'",
      'start_date': "TEXT NOT NULL DEFAULT (date('now'))",
      'end_date': 'TEXT',
      'is_active': 'INTEGER NOT NULL DEFAULT 1',
      'created_at': "TEXT NOT NULL DEFAULT (datetime('now'))",
      'updated_at': "TEXT NOT NULL DEFAULT (datetime('now'))",
    });
  }

  Future<void> _ensureColumns(
    Database db,
    String table,
    Map<String, String> columns,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final existing = info.map((e) => e['name'] as String).toSet();

    for (final entry in columns.entries) {
      if (!existing.contains(entry.key)) {
        await db.execute(
          'ALTER TABLE $table ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
  }

  /// Seed default categories for a new user.
  Future<void> seedDefaultCategories(int userId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final existing = await db.query(
      'categories',
      columns: ['id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    final batch = db.batch();

    const expenseCategories = [
      {'name': 'Ăn uống', 'icon_name': 'restaurant', 'color': '#FF7043', 'sort': 1},
      {'name': 'Di chuyển', 'icon_name': 'directions_car', 'color': '#42A5F5', 'sort': 2},
      {'name': 'Xăng', 'icon_name': 'local_gas_station', 'color': '#FFA726', 'sort': 3},
      {'name': 'Mua sắm', 'icon_name': 'shopping_bag', 'color': '#AB47BC', 'sort': 4},
      {'name': 'Giải trí', 'icon_name': 'movie', 'color': '#26A69A', 'sort': 5},
      {'name': 'Sức khỏe', 'icon_name': 'health_and_safety', 'color': '#EF5350', 'sort': 6},
      {'name': 'Giáo dục', 'icon_name': 'school', 'color': '#5C6BC0', 'sort': 7},
      {'name': 'Hóa đơn', 'icon_name': 'receipt_long', 'color': '#8D6E63', 'sort': 8},
      {'name': 'Khác', 'icon_name': 'category', 'color': '#78909C', 'sort': 9},
    ];

    for (final cat in expenseCategories) {
      batch.insert('categories', {
        'user_id': userId,
        'name': cat['name'],
        'type': 'expense',
        'icon_name': cat['icon_name'],
        'color': cat['color'],
        'sort_order': cat['sort'],
        'is_default': 1,
        'is_active': 1,
        'created_at': now,
      });
    }

    const incomeCategories = [
      {'name': 'Lương', 'icon_name': 'payments', 'color': '#66BB6A', 'sort': 10},
      {'name': 'Thưởng', 'icon_name': 'emoji_events', 'color': '#FBC02D', 'sort': 11},
      {'name': 'Đầu tư', 'icon_name': 'trending_up', 'color': '#26C6DA', 'sort': 12},
      {'name': 'Phụ cấp', 'icon_name': 'account_balance_wallet', 'color': '#7E57C2', 'sort': 13},
      {'name': 'Thu nhập khác', 'icon_name': 'attach_money', 'color': '#9CCC65', 'sort': 14},
    ];

    for (final cat in incomeCategories) {
      batch.insert('categories', {
        'user_id': userId,
        'name': cat['name'],
        'type': 'income',
        'icon_name': cat['icon_name'],
        'color': cat['color'],
        'sort_order': cat['sort'],
        'is_default': 1,
        'is_active': 1,
        'created_at': now,
      });
    }

    await batch.commit(noResult: true);
  }

  /// Seed a default cash account for a new user.
  Future<void> seedDefaultAccount(int userId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

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
    final dir = await getApplicationDocumentsDirectory();
    return join(dir.path, AppConstants.dbName);
  }
}
