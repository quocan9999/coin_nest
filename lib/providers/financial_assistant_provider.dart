import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';
import '../models/budget.dart';
import '../models/financial_assistant.dart';
import '../models/loan.dart';
import '../models/transaction_model.dart';
import '../providers/report_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/financial_assistant_service.dart';

class FinancialAssistantProvider extends ChangeNotifier {
  FinancialAssistantProvider({FinancialAssistantService? service})
    : _service = service ?? FinancialAssistantService();

  static const defaultSuggestedQuestions = [
    'Tháng này tôi chi nhiều nhất vào đâu?',
    'Tôi có đang chi quá nhiều không?',
    'Tôi nên tiết kiệm ở khoản nào?',
  ];

  static const _maxStoredMessages = 20;
  static const _maxContextMessages = 6;

  final FinancialAssistantService _service;

  List<FinancialAssistantMessage> _messages = [];
  List<String> _suggestedQuestions = defaultSuggestedQuestions;
  bool _isLoading = false;
  String? _errorMessage;
  int? _loadedUserId;

  List<FinancialAssistantMessage> get messages => List.unmodifiable(_messages);
  List<String> get suggestedQuestions => List.unmodifiable(_suggestedQuestions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isConfigured => _service.isConfigured;

  Future<void> loadHistory(int userId) async {
    if (_loadedUserId == userId) return;

    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_cacheKey(userId));
    _loadedUserId = userId;

    if (encoded == null) {
      _messages = [];
      _suggestedQuestions = defaultSuggestedQuestions;
      notifyListeners();
      return;
    }

    try {
      _messages = decodeFinancialAssistantMessages(
        encoded,
      ).take(_maxStoredMessages).toList();
      notifyListeners();
    } catch (_) {
      _messages = [];
      await prefs.remove(_cacheKey(userId));
      notifyListeners();
    }
  }

  Future<void> clearHistory(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey(userId));
    _messages = [];
    _suggestedQuestions = defaultSuggestedQuestions;
    _loadedUserId = userId;
    notifyListeners();
  }

  Future<void> askQuestion({
    required int userId,
    required String question,
    required ReportProvider reportProvider,
    required TransactionProvider transactionProvider,
    required List<Account> accounts,
    required List<Loan> loans,
    required List<Budget> budgets,
  }) async {
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty || _isLoading) return;

    await loadHistory(userId);

    final now = DateTime.now();
    final userMessage = FinancialAssistantMessage(
      role: 'user',
      content: trimmedQuestion,
      createdAt: now,
    );
    _messages = [..._messages, userMessage];
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = buildRequest(
        userId: userId,
        question: trimmedQuestion,
        reportProvider: reportProvider,
        transactionProvider: transactionProvider,
        accounts: accounts,
        loans: loans,
        budgets: budgets,
        now: now,
        recentMessages: _messages
            .where((message) => message != userMessage)
            .toList(),
      );
      final response = await _service.ask(request);
      final assistantMessage = FinancialAssistantMessage(
        role: 'assistant',
        content: response.answer,
        createdAt: response.generatedAt,
      );

      _messages = [..._messages, assistantMessage].takeLast(_maxStoredMessages);
      _suggestedQuestions = response.suggestedQuestions.isEmpty
          ? defaultSuggestedQuestions
          : response.suggestedQuestions;
      await _saveHistory(userId);
    } catch (_) {
      _errorMessage = isConfigured
          ? 'Không kết nối được trợ lý AI. Vui lòng thử lại sau.'
          : 'Chưa cấu hình AI_API_BASE_URL cho API AI.';
      _messages = _messages.takeLast(_maxStoredMessages);
      await _saveHistory(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  FinancialAssistantRequest buildRequest({
    required int userId,
    required String question,
    required ReportProvider reportProvider,
    required TransactionProvider transactionProvider,
    required List<Account> accounts,
    required List<Loan> loans,
    required List<Budget> budgets,
    DateTime? now,
    List<FinancialAssistantMessage> recentMessages = const [],
  }) {
    final current = now ?? DateTime.now();
    final period =
        '${current.year}-${current.month.toString().padLeft(2, '0')}';
    final accountBalance = accounts
        .where((account) => account.isIncludedInTotal)
        .fold<double>(0, (sum, account) => sum + account.balance);
    final monthlyTransactions = _monthlyTransactions(
      transactionProvider.transactions,
      current,
    );
    final totalIncome = reportProvider.totalIncome;
    final totalExpense = reportProvider.totalExpense;
    final activeLoans = loans.where((loan) => !loan.isPaid).toList();
    final activeBudgets = budgets.where((budget) => budget.isActive).toList();

    return FinancialAssistantRequest(
      userId: userId.toString(),
      question: question,
      period: period,
      reportSummary: {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'netBalance': totalIncome - totalExpense,
        'accountBalance': accountBalance,
      },
      topExpenseCategories: _categorySummaries(
        reportProvider.expenseByCategory,
        fallbackTransactions: monthlyTransactions,
        fallbackTypes: {'expense', 'lend'},
        total: totalExpense,
      ),
      topIncomeCategories: _categorySummaries(
        reportProvider.incomeByCategory,
        fallbackTransactions: monthlyTransactions,
        fallbackTypes: {'income', 'loan'},
        total: totalIncome,
      ),
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
      recentMessages: recentMessages.takeLast(_maxContextMessages),
    );
  }

  Future<void> _saveHistory(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey(userId),
      encodeFinancialAssistantMessages(_messages),
    );
  }

  static List<TransactionModel> _monthlyTransactions(
    List<TransactionModel> transactions,
    DateTime now,
  ) {
    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    return transactions
        .where(
          (txn) =>
              !txn.date.isBefore(monthStart) && txn.date.isBefore(nextMonth),
        )
        .toList();
  }

  static List<Map<String, dynamic>> _categorySummaries(
    List<Map<String, dynamic>> reportRows, {
    required List<TransactionModel> fallbackTransactions,
    required Set<String> fallbackTypes,
    required double total,
  }) {
    final rows = reportRows.isNotEmpty
        ? reportRows
        : _fallbackCategoryRows(fallbackTransactions, fallbackTypes);

    return rows.take(5).map((row) {
      final amount = (row['total'] as num?)?.toDouble() ?? 0;
      return {
        'name': (row['name'] as String?) ?? 'Khác',
        'amount': amount,
        'percent': total > 0 ? amount / total * 100 : 0,
      };
    }).toList();
  }

  static List<Map<String, dynamic>> _fallbackCategoryRows(
    List<TransactionModel> transactions,
    Set<String> types,
  ) {
    final grouped = <String, double>{};
    for (final transaction in transactions) {
      if (!types.contains(transaction.type)) continue;

      final name =
          transaction.categoryName ?? _fallbackCategoryName(transaction);
      grouped.update(
        name,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map((entry) => {'name': entry.key, 'total': entry.value})
        .toList();
  }

  static String _fallbackCategoryName(TransactionModel transaction) {
    return switch (transaction.type) {
      'loan' => 'Vay mượn',
      'lend' => 'Cho mượn',
      _ => 'Khác',
    };
  }

  static String _cacheKey(int userId) => 'financial_assistant_chat_$userId';
}

extension _TakeLast<T> on List<T> {
  List<T> takeLast(int count) {
    if (length <= count) return List<T>.from(this);
    return sublist(length - count);
  }
}
