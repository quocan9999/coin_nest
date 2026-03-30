import 'package:flutter/foundation.dart';
import '../database/transaction_dao.dart';

/// Computes report data for charts and analytics.
class ReportProvider extends ChangeNotifier {
  final _txnDao = TransactionDao();

  double _totalIncome = 0;
  double _totalExpense = 0;
  List<Map<String, dynamic>> _expenseByCategory = [];
  List<Map<String, dynamic>> _expenseByAccount = [];
  List<Map<String, dynamic>> _dailyExpense = [];
  List<Map<String, dynamic>> _dailyIncome = [];
  List<Map<String, dynamic>> _monthlyExpense = [];
  List<Map<String, dynamic>> _monthlyIncome = [];
  bool _isLoading = false;

  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get netBalance => _totalIncome - _totalExpense;
  List<Map<String, dynamic>> get expenseByCategory => _expenseByCategory;
  List<Map<String, dynamic>> get expenseByAccount => _expenseByAccount;
  List<Map<String, dynamic>> get dailyExpense => _dailyExpense;
  List<Map<String, dynamic>> get dailyIncome => _dailyIncome;
  List<Map<String, dynamic>> get monthlyExpense => _monthlyExpense;
  List<Map<String, dynamic>> get monthlyIncome => _monthlyIncome;
  bool get isLoading => _isLoading;

  Future<void> loadReport(int userId, {DateTime? from, DateTime? to}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startDate = from ?? DateTime(now.year, now.month, 1);
      final endDate = to ?? DateTime(now.year, now.month + 1, 0);

      final start = startDate.toIso8601String().split('T').first;
      final end = endDate.toIso8601String().split('T').first;

      _totalIncome = await _txnDao.totalIncome(userId, start, end);
      _totalExpense = await _txnDao.totalExpense(userId, start, end);
      _expenseByCategory = await _txnDao.expenseByCategory(userId, start, end);
      _expenseByAccount = await _txnDao.expenseByAccount(userId, start, end);
      _dailyExpense = await _txnDao.dailyTotals(userId, start, end, 'expense');
      _dailyIncome = await _txnDao.dailyTotals(userId, start, end, 'income');
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadYearlyReport(int userId, {int? year}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final y = year ?? DateTime.now().year;
      _monthlyExpense = await _txnDao.monthlyTotals(userId, y, 'expense');
      _monthlyIncome = await _txnDao.monthlyTotals(userId, y, 'income');
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }
}
