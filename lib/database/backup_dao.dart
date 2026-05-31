import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import '../utils/constants.dart';
import 'database_helper.dart';

class BackupSnapshot {
  BackupSnapshot({
    required this.formatVersion,
    required this.sourceDbVersion,
    required this.appVersion,
    required this.payload,
    required this.payloadSha256,
    required this.recordCounts,
  });

  final int formatVersion;
  final int sourceDbVersion;
  final String appVersion;
  final Map<String, dynamic> payload;
  final String payloadSha256;
  final Map<String, int> recordCounts;

  String get payloadJson => jsonEncode(payload);
}

class BackupRestoreResult {
  BackupRestoreResult({required this.recordCounts});

  final Map<String, int> recordCounts;
}

enum BackupDataError {
  checksum,
  unsupportedFormat,
  missingTable,
  invalidReference,
}

class BackupDataException implements Exception {
  const BackupDataException(this.error, this.message);

  final BackupDataError error;
  final String message;

  @override
  String toString() => message;
}

class BackupDao {
  BackupDao({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  static const int formatVersion = 1;

  final DatabaseHelper _databaseHelper;

  Future<BackupSnapshot> createSnapshot(int userId) async {
    final db = await _databaseHelper.database;
    final payload = <String, dynamic>{
      'formatVersion': formatVersion,
      'accounts': await _queryRows(db, 'accounts', userId),
      'categories': await _queryRows(db, 'categories', userId),
      'transactions': await _queryRows(db, 'transactions', userId),
      'loans': await _queryRows(db, 'loans', userId),
      'loan_payments': await _queryRows(db, 'loan_payments', userId),
      'budgets': await _queryRows(db, 'budgets', userId),
    };
    final payloadJson = jsonEncode(payload);

    return BackupSnapshot(
      formatVersion: formatVersion,
      sourceDbVersion: AppConstants.dbVersion,
      appVersion: AppConstants.appVersion,
      payload: payload,
      payloadSha256: sha256.convert(utf8.encode(payloadJson)).toString(),
      recordCounts: _recordCounts(payload),
    );
  }

  Future<BackupRestoreResult> restoreSnapshot({
    required int userId,
    required Map<String, dynamic> payload,
    required String expectedSha256,
  }) async {
    final actualSha256 = sha256
        .convert(utf8.encode(jsonEncode(payload)))
        .toString();
    if (actualSha256 != expectedSha256) {
      throw const BackupDataException(
        BackupDataError.checksum,
        'Backup checksum không hợp lệ',
      );
    }

    if (payload['formatVersion'] != formatVersion) {
      throw const BackupDataException(
        BackupDataError.unsupportedFormat,
        'Định dạng backup không được hỗ trợ',
      );
    }

    final tables = <String>[
      'accounts',
      'categories',
      'loans',
      'transactions',
      'loan_payments',
      'budgets',
    ];
    for (final table in tables) {
      if (payload[table] is! List) {
        throw BackupDataException(
          BackupDataError.missingTable,
          'Backup thiếu bảng $table',
        );
      }
    }

    final db = await _databaseHelper.database;
    final recordCounts = _recordCounts(payload);

    await db.transaction((txn) async {
      await _deleteCurrentFinancialData(txn, userId);

      final accountIds = await _insertRowsWithRemap(
        txn: txn,
        table: 'accounts',
        rows: _rows(payload['accounts']),
        userId: userId,
      );

      final categoryIds = await _insertCategories(
        txn: txn,
        rows: _rows(payload['categories']),
        userId: userId,
      );

      final loanIds = await _insertLoansWithoutTransactionLink(
        txn: txn,
        rows: _rows(payload['loans']),
        userId: userId,
        accountIds: accountIds,
      );

      final transactionIds = await _insertTransactions(
        txn: txn,
        rows: _rows(payload['transactions']),
        userId: userId,
        accountIds: accountIds,
        categoryIds: categoryIds,
        loanIds: loanIds,
      );

      await _insertLoanPayments(
        txn: txn,
        rows: _rows(payload['loan_payments']),
        userId: userId,
        loanIds: loanIds,
        transactionIds: transactionIds,
      );

      await _insertBudgets(
        txn: txn,
        rows: _rows(payload['budgets']),
        userId: userId,
        categoryIds: categoryIds,
        accountIds: accountIds,
      );

      await _restoreLoanTransactionLinks(
        txn: txn,
        rows: _rows(payload['loans']),
        loanIds: loanIds,
        transactionIds: transactionIds,
      );

      final violations = await txn.rawQuery('PRAGMA foreign_key_check');
      if (violations.isNotEmpty) {
        throw const BackupDataException(
          BackupDataError.invalidReference,
          'Backup tạo liên kết dữ liệu không hợp lệ',
        );
      }
    });

    return BackupRestoreResult(recordCounts: recordCounts);
  }

  Future<List<Map<String, Object?>>> _queryRows(
    DatabaseExecutor db,
    String table,
    int userId,
  ) {
    return db.query(
      table,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );
  }

  Future<void> _deleteCurrentFinancialData(
    DatabaseExecutor txn,
    int userId,
  ) async {
    await txn.delete(
      'loan_payments',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    await txn.delete('transactions', where: 'user_id = ?', whereArgs: [userId]);
    await txn.delete('budgets', where: 'user_id = ?', whereArgs: [userId]);
    await txn.delete('loans', where: 'user_id = ?', whereArgs: [userId]);
    await txn.delete('categories', where: 'user_id = ?', whereArgs: [userId]);
    await txn.delete('accounts', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<Map<int, int>> _insertRowsWithRemap({
    required DatabaseExecutor txn,
    required String table,
    required List<Map<String, dynamic>> rows,
    required int userId,
  }) async {
    final idMap = <int, int>{};
    for (final row in rows) {
      final oldId = row['id'] as int?;
      final insertRow = Map<String, dynamic>.from(row)
        ..remove('id')
        ..['user_id'] = userId;
      final newId = await txn.insert(table, insertRow);
      if (oldId != null) idMap[oldId] = newId;
    }
    return idMap;
  }

  Future<Map<int, int>> _insertCategories({
    required DatabaseExecutor txn,
    required List<Map<String, dynamic>> rows,
    required int userId,
  }) async {
    final idMap = <int, int>{};
    for (final row in rows) {
      final oldId = row['id'] as int?;
      final insertRow = Map<String, dynamic>.from(row)
        ..remove('id')
        ..['user_id'] = userId
        ..['parent_id'] = null;
      final newId = await txn.insert('categories', insertRow);
      if (oldId != null) idMap[oldId] = newId;
    }

    for (final row in rows) {
      final oldId = row['id'] as int?;
      final oldParentId = row['parent_id'] as int?;
      final newId = oldId == null ? null : idMap[oldId];
      final newParentId = oldParentId == null ? null : idMap[oldParentId];
      if (newId != null && newParentId != null) {
        await txn.update(
          'categories',
          {'parent_id': newParentId},
          where: 'id = ?',
          whereArgs: [newId],
        );
      }
    }
    return idMap;
  }

  Future<Map<int, int>> _insertLoansWithoutTransactionLink({
    required DatabaseExecutor txn,
    required List<Map<String, dynamic>> rows,
    required int userId,
    required Map<int, int> accountIds,
  }) async {
    final idMap = <int, int>{};
    for (final row in rows) {
      final oldId = row['id'] as int?;
      final oldAccountId = row['account_id'] as int?;
      final insertRow = Map<String, dynamic>.from(row)
        ..remove('id')
        ..['user_id'] = userId
        ..['account_id'] = _nullableRemap(accountIds, oldAccountId)
        ..['transaction_id'] = null;
      final newId = await txn.insert('loans', insertRow);
      if (oldId != null) idMap[oldId] = newId;
    }
    return idMap;
  }

  Future<Map<int, int>> _insertTransactions({
    required DatabaseExecutor txn,
    required List<Map<String, dynamic>> rows,
    required int userId,
    required Map<int, int> accountIds,
    required Map<int, int> categoryIds,
    required Map<int, int> loanIds,
  }) async {
    final idMap = <int, int>{};
    for (final row in rows) {
      final oldId = row['id'] as int?;
      final insertRow = Map<String, dynamic>.from(row)
        ..remove('id')
        ..['user_id'] = userId
        ..['account_id'] = _requiredRemap(accountIds, row['account_id'] as int?)
        ..['to_account_id'] = _nullableRemap(
          accountIds,
          row['to_account_id'] as int?,
        )
        ..['category_id'] = _nullableRemap(
          categoryIds,
          row['category_id'] as int?,
        )
        ..['loan_id'] = _nullableRemap(loanIds, row['loan_id'] as int?);
      final newId = await txn.insert('transactions', insertRow);
      if (oldId != null) idMap[oldId] = newId;
    }
    return idMap;
  }

  Future<void> _insertLoanPayments({
    required DatabaseExecutor txn,
    required List<Map<String, dynamic>> rows,
    required int userId,
    required Map<int, int> loanIds,
    required Map<int, int> transactionIds,
  }) async {
    for (final row in rows) {
      final insertRow = Map<String, dynamic>.from(row)
        ..remove('id')
        ..['user_id'] = userId
        ..['loan_id'] = _requiredRemap(loanIds, row['loan_id'] as int?)
        ..['transaction_id'] = _nullableRemap(
          transactionIds,
          row['transaction_id'] as int?,
        );
      await txn.insert('loan_payments', insertRow);
    }
  }

  Future<void> _insertBudgets({
    required DatabaseExecutor txn,
    required List<Map<String, dynamic>> rows,
    required int userId,
    required Map<int, int> categoryIds,
    required Map<int, int> accountIds,
  }) async {
    for (final row in rows) {
      final insertRow = Map<String, dynamic>.from(row)
        ..remove('id')
        ..['user_id'] = userId
        ..['category_id'] = _nullableRemap(
          categoryIds,
          row['category_id'] as int?,
        )
        ..['account_id'] = _nullableRemap(
          accountIds,
          row['account_id'] as int?,
        );
      await txn.insert('budgets', insertRow);
    }
  }

  Future<void> _restoreLoanTransactionLinks({
    required DatabaseExecutor txn,
    required List<Map<String, dynamic>> rows,
    required Map<int, int> loanIds,
    required Map<int, int> transactionIds,
  }) async {
    for (final row in rows) {
      final oldLoanId = row['id'] as int?;
      final oldTransactionId = row['transaction_id'] as int?;
      final newLoanId = oldLoanId == null ? null : loanIds[oldLoanId];
      final newTransactionId = oldTransactionId == null
          ? null
          : transactionIds[oldTransactionId];
      if (newLoanId != null && newTransactionId != null) {
        await txn.update(
          'loans',
          {'transaction_id': newTransactionId},
          where: 'id = ?',
          whereArgs: [newLoanId],
        );
      }
    }
  }

  int _requiredRemap(Map<int, int> ids, int? oldId) {
    if (oldId == null || !ids.containsKey(oldId)) {
      throw const BackupDataException(
        BackupDataError.invalidReference,
        'Backup tham chiếu id bắt buộc không hợp lệ',
      );
    }
    return ids[oldId]!;
  }

  int? _nullableRemap(Map<int, int> ids, int? oldId) {
    if (oldId == null) return null;
    return ids[oldId];
  }

  List<Map<String, dynamic>> _rows(Object? value) {
    return (value as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Map<String, int> _recordCounts(Map<String, dynamic> payload) {
    return {
      'accounts': (payload['accounts'] as List?)?.length ?? 0,
      'categories': (payload['categories'] as List?)?.length ?? 0,
      'transactions': (payload['transactions'] as List?)?.length ?? 0,
      'loans': (payload['loans'] as List?)?.length ?? 0,
      'loan_payments': (payload['loan_payments'] as List?)?.length ?? 0,
      'budgets': (payload['budgets'] as List?)?.length ?? 0,
    };
  }
}
