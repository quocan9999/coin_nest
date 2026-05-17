import 'package:flutter/foundation.dart';
import '../database/transaction_dao.dart';
import '../models/transaction_model.dart';
import '../utils/security_utils.dart';

/// Manages transaction listing, filtering, and CRUD.
class TransactionProvider extends ChangeNotifier {
  final _txnDao = TransactionDao();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _filterType;
  int? _filterCategoryId;
  int? _filterAccountId;
  String? _searchQuery;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  /// Grouped transactions by relative date label.
  Map<String, List<TransactionModel>> get groupedByDate {
    final map = <String, List<TransactionModel>>{};
    for (final txn in _transactions) {
      final label = _relativeDateLabel(txn.date);
      map.putIfAbsent(label, () => []).add(txn);
    }
    return map;
  }

  String _relativeDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'HÔM NAY';
    if (diff == 1) return 'HÔM QUA';
    return 'THÁNG NÀY';
  }

  Future<void> loadTransactions(int userId, {
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Default to current month if no range given
      final now = DateTime.now();
      final start = startDate ??
          DateTime(now.year, now.month, 1).toIso8601String().split('T').first;
      final end = endDate ??
          DateTime(now.year, now.month + 1, 0).toIso8601String().split('T').first;

      _transactions = await _txnDao.getByUser(
        userId,
        startDate: start,
        endDate: end,
        type: _filterType,
        categoryId: _filterCategoryId,
        accountId: _filterAccountId,
        searchQuery: _searchQuery,
      );
    } catch (_) {
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTransaction({
    required int userId,
    required int accountId,
    int? toAccountId,
    int? categoryId,
    required String type,
    required double amount,
    String? note,
    required DateTime date,
    String? time,
    int? loanId,
  }) async {
    try {
      final now = DateTime.now();
      final txn = TransactionModel(
        userId: userId,
        accountId: accountId,
        toAccountId: toAccountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        note: note != null ? SecurityUtils.sanitise(note) : null,
        date: date,
        time: time,
        loanId: loanId,
        createdAt: now,
        updatedAt: now,
      );

      await _txnDao.insertWithBalance(txn);
      await loadTransactions(userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteTransaction(int txnId, int userId) async {
    try {
      await _txnDao.deleteWithBalance(txnId);
      await loadTransactions(userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<TransactionModel>> getRecent(int userId, {int count = 5}) async {
    return _txnDao.getRecent(userId, count: count);
  }

  // ─── Filters ───────────────────────────────────────────────────

  void setFilterType(String? type) {
    _filterType = type;
    notifyListeners();
  }

  void setFilterCategory(int? categoryId) {
    _filterCategoryId = categoryId;
    notifyListeners();
  }

  void setFilterAccount(int? accountId) {
    _filterAccountId = accountId;
    notifyListeners();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _filterType = null;
    _filterCategoryId = null;
    _filterAccountId = null;
    _searchQuery = null;
    notifyListeners();
  }
}
