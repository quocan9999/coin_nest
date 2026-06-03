import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_spending_insight.dart';
import '../models/budget.dart';
import '../models/loan.dart';
import '../models/transaction_model.dart';
import '../services/ai_spending_insight_service.dart';

class AiSpendingInsightProvider extends ChangeNotifier {
  AiSpendingInsightProvider({AiSpendingInsightService? service})
    : _service = service ?? AiSpendingInsightService();

  final AiSpendingInsightService _service;

  AiSpendingInsight? _insight;
  bool _isLoading = false;
  String? _errorMessage;

  AiSpendingInsight? get insight => _insight;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isConfigured => _service.isConfigured;

  Future<void> loadCachedInsight(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_cacheKey(userId));
    if (encoded == null) return;

    try {
      _insight = AiSpendingInsight.decode(encoded);
      notifyListeners();
    } catch (_) {
      await prefs.remove(_cacheKey(userId));
    }
  }

  Future<void> refreshInsight({
    required int userId,
    required double totalBalance,
    required List<TransactionModel> transactions,
    required List<Loan> loans,
    required List<Budget> budgets,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = buildMonthlyRequest(
        userId: userId,
        totalBalance: totalBalance,
        transactions: transactions,
        loans: loans,
        budgets: budgets,
      );
      final result = await _service.fetchInsight(request);
      _insight = result;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey(userId), result.encode());
    } catch (_) {
      final configured = await _service.isConfiguredAsync();
      _errorMessage = configured
          ? 'Không kết nối được AI. Vui lòng thử lại sau.'
          : 'Chưa cấu hình API AI trong Cài đặt chung.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  AiSpendingInsightRequest buildMonthlyRequest({
    required int userId,
    required double totalBalance,
    required List<TransactionModel> transactions,
    required List<Loan> loans,
    required List<Budget> budgets,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final monthStart = DateTime(current.year, current.month);
    final nextMonth = DateTime(current.year, current.month + 1);
    final monthlyTransactions = transactions
        .where(
          (txn) =>
              !txn.date.isBefore(monthStart) && txn.date.isBefore(nextMonth),
        )
        .toList();

    final income = _sumTypes(monthlyTransactions, {'income', 'loan'});
    final expense = _sumTypes(monthlyTransactions, {'expense', 'lend'});
    final topCategories = _topExpenseCategories(monthlyTransactions, expense);
    final activeLoans = loans.where((loan) => !loan.isPaid).toList();
    final activeBudgets = budgets.where((budget) => budget.isActive).toList();

    return AiSpendingInsightRequest(
      userId: userId.toString(),
      period: '${current.year}-${current.month.toString().padLeft(2, '0')}',
      totalIncome: income,
      totalExpense: expense,
      balance: totalBalance,
      topExpenseCategories: topCategories,
      debtSummary: {
        'borrowedRemaining': activeLoans
            .where((loan) => loan.type == 'borrow')
            .fold<double>(0, (sum, loan) => sum + loan.remainingAmount),
        'lentRemaining': activeLoans
            .where((loan) => loan.type == 'lend')
            .fold<double>(0, (sum, loan) => sum + loan.remainingAmount),
        'overdueCount': activeLoans.where((loan) => loan.isOverdue).length,
      },
      budgetSummary: {
        'activeCount': activeBudgets.length,
        'exceededCount': activeBudgets
            .where((budget) => budget.isExceeded)
            .length,
        'highestUsagePercent': activeBudgets.fold<double>(
          0,
          (highest, budget) =>
              budget.usagePercent > highest ? budget.usagePercent : highest,
        ),
      },
    );
  }

  static double _sumTypes(
    List<TransactionModel> transactions,
    Set<String> types,
  ) {
    return transactions
        .where((txn) => types.contains(txn.type))
        .fold<double>(0, (sum, txn) => sum + txn.amount);
  }

  static List<Map<String, dynamic>> _topExpenseCategories(
    List<TransactionModel> transactions,
    double totalExpense,
  ) {
    final grouped = <String, double>{};

    for (final txn in transactions) {
      if (txn.type != 'expense' && txn.type != 'lend') continue;

      final name =
          txn.categoryName ?? (txn.type == 'lend' ? 'Cho mượn' : 'Khác');
      grouped.update(
        name,
        (value) => value + txn.amount,
        ifAbsent: () => txn.amount,
      );
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(5).map((entry) {
      return {
        'name': entry.key,
        'amount': entry.value,
        'percent': totalExpense > 0 ? entry.value / totalExpense * 100 : 0,
      };
    }).toList();
  }

  static String _cacheKey(int userId) => 'ai_spending_insight_$userId';
}
