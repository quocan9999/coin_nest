import '../models/loan_payment.dart';
import 'database_helper.dart';

class LoanPaymentDao {
  final _dbHelper = DatabaseHelper.instance;

  Future<int> insert(LoanPayment payment) async {
    final db = await _dbHelper.database;
    return db.insert('loan_payments', payment.toMap());
  }

  Future<List<LoanPayment>> getByLoanId(int loanId, int userId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'loan_payments',
      where: 'loan_id = ? AND user_id = ?',
      whereArgs: [loanId, userId],
      orderBy: 'payment_date DESC, created_at DESC',
    );
    return result.map((m) => LoanPayment.fromMap(m)).toList();
  }

  Future<int> deleteByLoanId(int loanId, int userId) async {
    final db = await _dbHelper.database;
    return db.delete(
      'loan_payments',
      where: 'loan_id = ? AND user_id = ?',
      whereArgs: [loanId, userId],
    );
  }

  Future<double> getTotalPaid(int loanId, int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM loan_payments WHERE loan_id = ? AND user_id = ?',
      [loanId, userId],
    );
    return (result.first['total'] as num).toDouble();
  }
}
