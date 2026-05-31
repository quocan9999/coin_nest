import 'package:flutter/foundation.dart';
import '../database/budget_dao.dart';
import '../models/budget.dart';
import 'backup_alert_provider.dart';
import '../utils/security_utils.dart';

class BudgetProvider extends ChangeNotifier {
  final _budgetDao = BudgetDao();
  BackupAlertProvider? _backupAlertProvider;
  List<Budget> _budgets = [];
  bool _isLoading = false;

  List<Budget> get budgets => _budgets;
  List<Budget> get activeBudgets => _budgets.where((b) => b.isActive).toList();
  List<Budget> get exceededBudgets =>
      _budgets.where((b) => b.isExceeded).toList();
  bool get isLoading => _isLoading;

  void setBackupAlertProvider(BackupAlertProvider backupAlertProvider) {
    _backupAlertProvider = backupAlertProvider;
  }

  Future<void> loadBudgets(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _budgets = await _budgetDao.getAllByUser(userId);
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addBudget({
    required int userId,
    int? categoryId,
    int? accountId, // ĐÃ THÊM: Nhận accountId từ UI
    required String name,
    required double amount,
    String period = 'monthly',
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final budget = Budget(
        userId: userId,
        categoryId: categoryId,
        accountId: accountId, // ĐÃ THÊM: Lưu vào model
        name: SecurityUtils.sanitise(name),
        amount: amount,
        period: period,
        startDate: startDate,
        endDate: endDate,
        createdAt: now,
        updatedAt: now,
      );
      await _budgetDao.insert(budget);
      await _backupAlertProvider?.markChanged(userId, source: 'budget');
      await loadBudgets(userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateBudget(Budget budget) async {
    try {
      await _budgetDao.update(budget.copyWith(updatedAt: DateTime.now()));
      await _backupAlertProvider?.markChanged(budget.userId, source: 'budget');
      await loadBudgets(budget.userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteBudget(int id, int userId) async {
    try {
      await _budgetDao.delete(id);
      await _backupAlertProvider?.markChanged(userId, source: 'budget');
      await loadBudgets(userId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
