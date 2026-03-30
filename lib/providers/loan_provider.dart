import 'package:flutter/foundation.dart';
import '../database/loan_dao.dart';
import '../models/loan.dart';
import '../utils/security_utils.dart';

class LoanProvider extends ChangeNotifier {
  final _loanDao = LoanDao();
  List<Loan> _loans = [];
  Map<String, double> _summary = {'borrowed': 0, 'lent': 0};
  bool _isLoading = false;

  List<Loan> get loans => _loans;
  Map<String, double> get summary => _summary;
  bool get isLoading => _isLoading;

  List<Loan> get activeLoans => _loans.where((l) => l.status == 'active').toList();
  List<Loan> get borrowedLoans => _loans.where((l) => l.type == 'borrow').toList();
  List<Loan> get lentLoans => _loans.where((l) => l.type == 'lend').toList();

  Future<void> loadLoans(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _loans = await _loanDao.getAllByUser(userId);
      _summary = await _loanDao.getSummary(userId);
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addLoan({
    required int userId,
    required String type,
    required String personName,
    required double amount,
    double interestRate = 0,
    String? note,
    required DateTime startDate,
    DateTime? dueDate,
    int? accountId,
  }) async {
    try {
      final now = DateTime.now();
      final loan = Loan(
        userId: userId,
        type: type,
        personName: SecurityUtils.sanitise(personName),
        amount: amount,
        remainingAmount: amount,
        interestRate: interestRate,
        note: note != null ? SecurityUtils.sanitise(note) : null,
        startDate: startDate,
        dueDate: dueDate,
        accountId: accountId,
        createdAt: now,
        updatedAt: now,
      );
      await _loanDao.insert(loan);
      await loadLoans(userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> recordPayment(int loanId, double amount, int userId) async {
    try {
      await _loanDao.recordPayment(loanId, amount);
      await loadLoans(userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteLoan(int id, int userId) async {
    try {
      await _loanDao.delete(id);
      await loadLoans(userId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
