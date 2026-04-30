import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';

/// Singleton database helper — manages the SQLite lifecycle.
///
/// All tables use parameterised queries exclusively (no string interpolation
/// into SQL) to prevent injection attacks.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
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

  /// Enable foreign keys (disabled by default in SQLite).
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        avatar_path TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
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
      CREATE TABLE categories (
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
      CREATE TABLE transactions (
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
      CREATE TABLE loans (
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
      CREATE TABLE budgets (
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
      CREATE TABLE feedbacks (
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

    // ─── Indexes for query performance ───────────────────────────
    await db.execute(
      'CREATE INDEX idx_transactions_user_date ON transactions(user_id, date DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_account ON transactions(account_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_category ON transactions(category_id)',
    );
    await db.execute('CREATE INDEX idx_accounts_user ON accounts(user_id)');
    await db.execute(
      'CREATE INDEX idx_categories_user ON categories(user_id, type)',
    );
    await db.execute('CREATE INDEX idx_loans_user ON loans(user_id, status)');
    await db.execute(
      'CREATE INDEX idx_budgets_user ON budgets(user_id, is_active)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // No migration path is kept intentionally.
    // The app now uses a fresh schema with `phone` as the user identity field.
  }

  /// Seed default categories for a new user.
  Future<void> seedDefaultCategories(int userId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final batch = db.batch();

    // Expense categories
    const expenseCategories = [
      {'name': 'Cho mượn', 'icon_name': 'lend', 'sort': 1},
      {'name': 'Trả nợ', 'icon_name': 'loan', 'sort': 2},
    ];

    for (final cat in expenseCategories) {
      batch.insert('categories', {
        'user_id': userId,
        'name': cat['name'],
        'type': 'expense',
        'icon_name': cat['icon_name'],
        'sort_order': cat['sort'],
        'is_default': 1,
        'is_active': 1,
        'created_at': now,
      });
    }

    // Income categories
    const incomeCategories = [
      {'name': 'Vay mượn', 'icon_name': 'loan', 'sort': 1},
      {'name': 'Thu nợ', 'icon_name': 'lend', 'sort': 2},
      {'name': 'Tiết kiệm lãi', 'icon_name': 'interest', 'sort': 3},
    ];

    for (final cat in incomeCategories) {
      batch.insert('categories', {
        'user_id': userId,
        'name': cat['name'],
        'type': 'income',
        'icon_name': cat['icon_name'],
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

  /// Close the database (e.g. on logout).
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }

  /// Export the database file path for backup.
  Future<String> getDatabasePath() async {
    return _databasePathByName(AppConstants.dbName);
  }

  Future<String> _databasePathByName(String dbName) async {
    final dir = await getApplicationDocumentsDirectory();
    return join(dir.path, dbName);
  }
}
