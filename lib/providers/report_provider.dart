import 'package:flutter/foundation.dart';
import '../database/transaction_dao.dart';
import '../models/transaction_model.dart';

/// Computes report data for charts and analytics.
class ReportProvider extends ChangeNotifier {
  final _txnDao = TransactionDao();

  double _totalIncome = 0;
  double _totalExpense = 0;
  List<Map<String, dynamic>> _expenseByCategory = [];
  List<Map<String, dynamic>> _expenseByAccount = [];
  List<Map<String, dynamic>> _incomeByCategory = [];
  List<Map<String, dynamic>> _incomeByAccount = [];
  List<Map<String, dynamic>> _dailyExpense = [];
  List<Map<String, dynamic>> _dailyIncome = [];
  List<Map<String, dynamic>> _hourlyExpense = [];
  List<Map<String, dynamic>> _hourlyIncome = [];
  List<TransactionModel> _dailyExpenseTransactions = [];
  List<Map<String, dynamic>> _monthlyExpense = [];
  List<Map<String, dynamic>> _monthlyIncome = [];
  bool _isLoading = false;
  bool _hasError = false;

  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get netBalance => _totalIncome - _totalExpense;
  List<Map<String, dynamic>> get expenseByCategory => _expenseByCategory;
  List<Map<String, dynamic>> get expenseByAccount => _expenseByAccount;
  List<Map<String, dynamic>> get incomeByCategory => _incomeByCategory;
  List<Map<String, dynamic>> get incomeByAccount => _incomeByAccount;
  List<Map<String, dynamic>> get dailyExpense => _dailyExpense;
  List<Map<String, dynamic>> get dailyIncome => _dailyIncome;
  List<Map<String, dynamic>> get hourlyExpense => _hourlyExpense;
  List<Map<String, dynamic>> get hourlyIncome => _hourlyIncome;
  List<TransactionModel> get dailyExpenseTransactions =>
      _dailyExpenseTransactions;
  List<Map<String, dynamic>> get monthlyExpense => _monthlyExpense;
  List<Map<String, dynamic>> get monthlyIncome => _monthlyIncome;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  Future<void> loadReport(int userId, {DateTime? from, DateTime? to}) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startDate = from ?? DateTime(now.year, now.month, 1);
      final endDate = to ?? DateTime(now.year, now.month + 1, 0);

      final start = startDate.toIso8601String().split('T').first;
      final end = endDate.toIso8601String().split('T').first;
      final isSingleDay = start == end;

      _totalIncome = await _txnDao.totalIncome(userId, start, end);
      _totalExpense = await _txnDao.totalExpense(userId, start, end);
      _expenseByCategory = await _txnDao.expenseByCategory(userId, start, end);
      _expenseByAccount = await _txnDao.expenseByAccount(userId, start, end);
      _incomeByCategory = await _txnDao.incomeByCategory(userId, start, end);
      _incomeByAccount = await _txnDao.incomeByAccount(userId, start, end);
      _dailyExpense = await _txnDao.dailyTotals(userId, start, end, 'expense');
      _dailyIncome = await _txnDao.dailyTotals(userId, start, end, 'income');
      if (isSingleDay) {
        _hourlyExpense = await _txnDao.hourlyTotals(userId, start, 'expense');
        _hourlyIncome = await _txnDao.hourlyTotals(userId, start, 'income');
        _dailyExpenseTransactions = await _txnDao.getByUser(
          userId,
          startDate: start,
          endDate: end,
          type: 'expense',
        );
      } else {
        _hourlyExpense = [];
        _hourlyIncome = [];
        _dailyExpenseTransactions = [];
      }
    } catch (e, st) {
      debugPrint('ReportProvider error: $e\n$st');
      _hasError = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadYearlyReport(int userId, {int? year}) async {
    _isLoading = true;
    _hasError = false;
    _totalIncome = 0;
    _totalExpense = 0;
    // Intentionally clear daily fields during yearly load.
    // Screens that require monthly/day data should keep local snapshots.
    _dailyExpense = [];
    _dailyIncome = [];
    _hourlyExpense = [];
    _hourlyIncome = [];
    _dailyExpenseTransactions = [];
    _expenseByCategory = [];
    _incomeByCategory = [];
    notifyListeners();

    try {
      final y = year ?? DateTime.now().year;
      _monthlyExpense = await _txnDao.monthlyTotals(userId, y, 'expense');
      _monthlyIncome = await _txnDao.monthlyTotals(userId, y, 'income');
      _totalExpense = _monthlyExpense.fold(
        0,
        (s, e) => s + (e['total'] as num).toDouble(),
      );
      _totalIncome = _monthlyIncome.fold(
        0,
        (s, e) => s + (e['total'] as num).toDouble(),
      );
    } catch (e, st) {
      debugPrint('ReportProvider error: $e\n$st');
      _hasError = true;
    }

    _isLoading = false;
    notifyListeners();
  }
}
