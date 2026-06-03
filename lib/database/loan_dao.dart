import 'package:sqflite/sqflite.dart';

import '../models/loan.dart';
import '../models/loan_payment.dart';
import '../models/transaction_model.dart';
import 'database_helper.dart';

/// Data access object for the [Loan] table.
class LoanDao {
  LoanDao({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final _dbHelper = DatabaseHelper.instance;
  final DateTime Function() _now;

  Future<int> insert(Loan loan) async {
    final db = await _dbHelper.database;
    return db.insert('loans', loan.toMap());
  }

  Future<void> updateTransactionId({
    required int loanId,
    required int transactionId,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      'loans',
      {'transaction_id': transactionId},
      where: 'id = ?',
      whereArgs: [loanId],
    );
  }

  Future<List<Loan>> getAllByUser(
    int userId, {
    String? status,
    String? type,
  }) async {
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

  Future<Loan?> findByIdForUser(int id, int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT l.*, a.name as account_name
      FROM loans l
      LEFT JOIN accounts a ON l.account_id = a.id
      WHERE l.id = ? AND l.user_id = ?
      LIMIT 1
    ''',
      [id, userId],
    );
    if (result.isEmpty) return null;
    return Loan.fromMap(result.first);
  }

  Future<Loan?> findByTransactionForUser(int transactionId, int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT DISTINCT l.*, a.name as account_name
      FROM loans l
      LEFT JOIN accounts a ON l.account_id = a.id
      LEFT JOIN transactions t ON t.loan_id = l.id
      WHERE l.user_id = ? AND (l.transaction_id = ? OR t.id = ?)
      LIMIT 1
    ''',
      [userId, transactionId, transactionId],
    );
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

  Future<int> insertWithInitialTransaction({
    required Loan loan,
    int? categoryId,
  }) async {
    final db = await _dbHelper.database;
    late int loanId;

    await db.transaction((txn) async {
      loanId = await txn.insert('loans', loan.toMap());
      final now = _now();
      final initialTransaction = TransactionModel(
        userId: loan.userId,
        accountId: loan.accountId!,
        categoryId: categoryId,
        type: loan.type == 'borrow' ? 'loan' : 'lend',
        amount: loan.amount,
        note: loan.note,
        date: loan.startDate,
        time: _formatTime(now),
        loanId: loanId,
        createdAt: now,
        updatedAt: now,
      );

      final transactionId = await txn.insert(
        'transactions',
        initialTransaction.toMap(),
      );
      await _applyBalance(txn, initialTransaction);
      await txn.update(
        'loans',
        {'transaction_id': transactionId},
        where: 'id = ? AND user_id = ?',
        whereArgs: [loanId, loan.userId],
      );
    });

    return loanId;
  }

  Future<void> updateLoanWithTransactions({
    required Loan loan,
    required int userId,
    required int? initialCategoryId,
    int? paymentCategoryId,
  }) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      final existingRows = await txn.query(
        'loans',
        where: 'id = ? AND user_id = ?',
        whereArgs: [loan.id, userId],
        limit: 1,
      );
      if (existingRows.isEmpty) {
        throw StateError('Loan not found');
      }

      final existingLoan = Loan.fromMap(existingRows.first);
      final paymentRows = await txn.query(
        'loan_payments',
        where: 'loan_id = ? AND user_id = ?',
        whereArgs: [loan.id, userId],
      );
      final payments = paymentRows.map((row) => LoanPayment.fromMap(row));
      final totalPaid = payments.fold<double>(
        0,
        (sum, payment) => sum + payment.amount,
      );

      if (loan.amount < totalPaid) {
        throw ArgumentError(
          'Số tiền vay không được thấp hơn tổng số tiền đã thanh toán',
        );
      }

      DateTime? earliestPaymentDate;
      for (final payment in payments) {
        if (earliestPaymentDate == null ||
            payment.paymentDate.isBefore(earliestPaymentDate)) {
          earliestPaymentDate = payment.paymentDate;
        }
      }
      if (earliestPaymentDate != null &&
          loan.startDate.isAfter(earliestPaymentDate)) {
        throw ArgumentError('Ngày bắt đầu vay không được sau ngày thanh toán');
      }

      final now = _now();
      final remainingAmount = loan.amount - totalPaid;
      final initialTransactionId = await _resolveInitialTransactionId(
        txn,
        existingLoan,
      );
      final existingInitialTransactionRow = initialTransactionId == null
          ? null
          : await _findTransactionRow(txn, initialTransactionId);
      final existingInitialTransaction = existingInitialTransactionRow == null
          ? null
          : TransactionModel.fromMap(existingInitialTransactionRow);
      final newInitialTransaction = TransactionModel(
        id: initialTransactionId,
        userId: userId,
        accountId: loan.accountId!,
        categoryId: initialCategoryId,
        type: loan.type == 'borrow' ? 'loan' : 'lend',
        amount: loan.amount,
        note: loan.note,
        date: loan.startDate,
        time: existingInitialTransaction?.time ?? _formatTime(now),
        loanId: loan.id,
        createdAt: existingInitialTransaction?.createdAt ?? now,
        updatedAt: now,
      );

      var transactionIdForLoan = initialTransactionId;
      if (initialTransactionId == null) {
        final transactionId = await txn.insert(
          'transactions',
          newInitialTransaction.toMap(),
        );
        transactionIdForLoan = transactionId;
        await _applyBalance(txn, newInitialTransaction);
        await txn.update(
          'loans',
          {'transaction_id': transactionId},
          where: 'id = ? AND user_id = ?',
          whereArgs: [loan.id, userId],
        );
      } else {
        await _updateTransactionWithBalance(txn, newInitialTransaction);
      }

      for (final payment in payments) {
        final paymentTransactionId = payment.transactionId;
        if (paymentTransactionId == null) continue;

        final row = await _findTransactionRow(txn, paymentTransactionId);
        if (row == null) continue;

        final existingPaymentTxn = TransactionModel.fromMap(row);
        final newPaymentTxn = TransactionModel(
          id: existingPaymentTxn.id,
          userId: userId,
          accountId: loan.accountId!,
          categoryId: paymentCategoryId,
          type: loan.type == 'borrow' ? 'expense' : 'income',
          amount: payment.amount,
          note: payment.note,
          date: payment.paymentDate,
          time: existingPaymentTxn.time ?? _formatTime(now),
          loanId: loan.id,
          createdAt: existingPaymentTxn.createdAt,
          updatedAt: now,
        );
        await _updateTransactionWithBalance(txn, newPaymentTxn);
      }

      final updatedLoan = Loan(
        id: existingLoan.id,
        userId: userId,
        type: loan.type,
        personName: loan.personName,
        amount: loan.amount,
        remainingAmount: remainingAmount,
        interestRate: loan.interestRate,
        note: loan.note,
        startDate: loan.startDate,
        dueDate: loan.dueDate,
        status: remainingAmount <= 0 ? 'paid' : 'active',
        accountId: loan.accountId,
        transactionId: transactionIdForLoan,
        interestCalculated: existingLoan.interestCalculated,
        createdAt: existingLoan.createdAt,
        updatedAt: now,
      );

      await txn.update(
        'loans',
        updatedLoan.toMap(),
        where: 'id = ? AND user_id = ?',
        whereArgs: [loan.id, userId],
      );
    });
  }

  Future<void> recordPaymentWithTransaction({
    required int loanId,
    required int userId,
    required double amount,
    required DateTime paymentDate,
    String? note,
    required int accountId,
    int? categoryId,
  }) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      if (amount <= 0) {
        throw ArgumentError('Payment amount must be greater than 0');
      }
      final now = _now();
      if (paymentDate.isAfter(now)) {
        throw ArgumentError('Payment date cannot be in the future');
      }

      final rows = await txn.query(
        'loans',
        where: 'id = ? AND user_id = ?',
        whereArgs: [loanId, userId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('Loan not found for current user');
      }

      final loan = Loan.fromMap(rows.first);
      if (loan.isPaid) {
        throw StateError('Loan has already been paid');
      }
      if (amount > loan.remainingAmount) {
        throw ArgumentError('Payment amount exceeds remaining amount');
      }
      if (paymentDate.isBefore(loan.startDate)) {
        throw ArgumentError('Payment date cannot be before loan start date');
      }

      final paymentTransaction = TransactionModel(
        userId: userId,
        accountId: accountId,
        categoryId: categoryId,
        type: loan.type == 'borrow' ? 'expense' : 'income',
        amount: amount,
        note: note,
        date: paymentDate,
        time: _formatTime(now),
        loanId: loanId,
        createdAt: now,
        updatedAt: now,
      );

      final transactionId = await txn.insert(
        'transactions',
        paymentTransaction.toMap(),
      );
      await _applyBalance(txn, paymentTransaction);

      await txn.insert('loan_payments', {
        'loan_id': loanId,
        'user_id': userId,
        'transaction_id': transactionId,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String().split('T').first,
        'note': note,
        'created_at': now.toIso8601String(),
      });

      final remaining = loan.remainingAmount - amount;
      await txn.update(
        'loans',
        {
          'remaining_amount': remaining < 0 ? 0 : remaining,
          'status': remaining <= 0 ? 'paid' : 'active',
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ? AND user_id = ?',
        whereArgs: [loanId, userId],
      );
    });
  }

  Future<int> deleteForUserWithRollback(int id, int userId) async {
    final db = await _dbHelper.database;
    var deleted = 0;

    await db.transaction((txn) async {
      final loanRows = await txn.query(
        'loans',
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
        limit: 1,
      );
      if (loanRows.isEmpty) return;

      final loan = Loan.fromMap(loanRows.first);
      final transactionRows = await txn.query(
        'transactions',
        where: loan.transactionId == null
            ? 'loan_id = ? AND user_id = ?'
            : '(loan_id = ? OR id = ?) AND user_id = ?',
        whereArgs: loan.transactionId == null
            ? [id, userId]
            : [id, loan.transactionId, userId],
      );

      for (final row in transactionRows) {
        final transaction = TransactionModel.fromMap(row);
        await _reverseBalance(txn, transaction);
      }
      for (final row in transactionRows) {
        await txn.delete(
          'transactions',
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
      await txn.delete(
        'loan_payments',
        where: 'loan_id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
      deleted = await txn.delete(
        'loans',
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
    });

    return deleted;
  }

  Future<int?> _resolveInitialTransactionId(
    DatabaseExecutor db,
    Loan loan,
  ) async {
    if (loan.transactionId != null) {
      final row = await _findTransactionRow(db, loan.transactionId!);
      if (row != null) return loan.transactionId;
    }

    final rows = await db.query(
      'transactions',
      columns: ['id'],
      where: 'loan_id = ? AND user_id = ? AND type IN (?, ?)',
      whereArgs: [loan.id, loan.userId, 'loan', 'lend'],
      orderBy: 'date ASC, created_at ASC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['id'] as int?;
  }

  Future<Map<String, Object?>?> _findTransactionRow(
    DatabaseExecutor db,
    int id,
  ) async {
    final rows = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> _updateTransactionWithBalance(
    DatabaseExecutor db,
    TransactionModel newTransaction,
  ) async {
    final row = await _findTransactionRow(db, newTransaction.id!);
    if (row == null) {
      throw StateError('Transaction not found');
    }

    final oldTransaction = TransactionModel.fromMap(row);
    await _reverseBalance(db, oldTransaction);
    await _applyBalance(db, newTransaction);
    await db.update(
      'transactions',
      newTransaction.toMap(),
      where: 'id = ?',
      whereArgs: [newTransaction.id],
    );
  }

  Future<void> _applyBalance(
    DatabaseExecutor db,
    TransactionModel transaction,
  ) async {
    switch (transaction.type) {
      case 'income':
      case 'loan':
        await _updateAccountBalance(
          db,
          transaction.accountId,
          transaction.amount,
        );
        break;
      case 'expense':
      case 'lend':
        await _updateAccountBalance(
          db,
          transaction.accountId,
          -transaction.amount,
        );
        break;
      case 'transfer':
        await _updateAccountBalance(
          db,
          transaction.accountId,
          -transaction.amount,
        );
        if (transaction.toAccountId != null) {
          await _updateAccountBalance(
            db,
            transaction.toAccountId!,
            transaction.amount,
          );
        }
        break;
      default:
        break;
    }
  }

  Future<void> _reverseBalance(
    DatabaseExecutor db,
    TransactionModel transaction,
  ) async {
    switch (transaction.type) {
      case 'income':
      case 'loan':
        await _updateAccountBalance(
          db,
          transaction.accountId,
          -transaction.amount,
        );
        break;
      case 'expense':
      case 'lend':
        await _updateAccountBalance(
          db,
          transaction.accountId,
          transaction.amount,
        );
        break;
      case 'transfer':
        await _updateAccountBalance(
          db,
          transaction.accountId,
          transaction.amount,
        );
        if (transaction.toAccountId != null) {
          await _updateAccountBalance(
            db,
            transaction.toAccountId!,
            -transaction.amount,
          );
        }
        break;
      default:
        break;
    }
  }

  Future<void> _updateAccountBalance(
    DatabaseExecutor db,
    int accountId,
    double delta,
  ) async {
    await db.rawUpdate(
      'UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?',
      [delta, _now().toIso8601String(), accountId],
    );
  }

  /// Record a payment toward a loan.
  Future<void> recordPayment({
    required int loanId,
    required int userId,
    required double amount,
    required DateTime paymentDate,
    String? note,
    int? transactionId,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      if (amount <= 0) {
        throw ArgumentError('Payment amount must be greater than 0');
      }
      final now = _now();
      if (paymentDate.isAfter(now)) {
        throw ArgumentError('Payment date cannot be in the future');
      }

      final rows = await txn.query(
        'loans',
        where: 'id = ? AND user_id = ?',
        whereArgs: [loanId, userId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('Loan not found for current user');
      }

      final loan = Loan.fromMap(rows.first);
      if (loan.isPaid) {
        throw StateError('Loan has already been paid');
      }
      if (amount > loan.remainingAmount) {
        throw ArgumentError('Payment amount exceeds remaining amount');
      }
      if (paymentDate.isBefore(loan.startDate)) {
        throw ArgumentError('Payment date cannot be before loan start date');
      }

      final nowIso = now.toIso8601String();
      await txn.insert('loan_payments', {
        'loan_id': loanId,
        'user_id': userId,
        'transaction_id': transactionId,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String().split('T').first,
        'note': note,
        'created_at': nowIso,
      });

      await txn.rawUpdate(
        'UPDATE loans SET remaining_amount = MAX(remaining_amount - ?, 0), '
        'updated_at = ? WHERE id = ? AND user_id = ?',
        [amount, nowIso, loanId, userId],
      );

      final updatedRows = await txn.query(
        'loans',
        where: 'id = ? AND user_id = ?',
        whereArgs: [loanId, userId],
        limit: 1,
      );
      if (updatedRows.isNotEmpty) {
        final remaining = (updatedRows.first['remaining_amount'] as num)
            .toDouble();
        if (remaining <= 0) {
          await txn.update(
            'loans',
            {'status': 'paid', 'updated_at': nowIso},
            where: 'id = ? AND user_id = ?',
            whereArgs: [loanId, userId],
          );
        }
      }
    });
  }

  Future<int> deleteForUser(int id, int userId) async {
    final db = await _dbHelper.database;
    return db.delete(
      'loans',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<List<LoanPayment>> getPaymentHistory(int loanId, int userId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'loan_payments',
      where: 'loan_id = ? AND user_id = ?',
      whereArgs: [loanId, userId],
      orderBy: 'payment_date DESC, created_at DESC',
    );
    return result.map((m) => LoanPayment.fromMap(m)).toList();
  }

  /// Backward-compatible helper for existing callers.
  Future<Loan?> findById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT l.*, a.name as account_name
      FROM loans l
      LEFT JOIN accounts a ON l.account_id = a.id
      WHERE l.id = ?
      LIMIT 1
    ''',
      [id],
    );
    if (result.isEmpty) return null;
    return Loan.fromMap(result.first);
  }

  /// Backward-compatible helper for existing callers.
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

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
