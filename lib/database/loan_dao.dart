import '../models/loan.dart';
import '../models/loan_payment.dart';
import 'database_helper.dart';

/// Data access object for the [Loan] table.
class LoanDao {
  final _dbHelper = DatabaseHelper.instance;

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
      if (paymentDate.isAfter(DateTime.now())) {
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

      final nowIso = DateTime.now().toIso8601String();
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
}
