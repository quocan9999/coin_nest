import 'package:flutter/foundation.dart';
import '../database/account_dao.dart';
import '../models/account.dart';
import '../utils/security_utils.dart';

/// Manages the list of user accounts and selected account state.
class AccountProvider extends ChangeNotifier {
  final _accountDao = AccountDao();

  List<Account> _accounts = [];
  double _totalBalance = 0;
  bool _isLoading = false;

  List<Account> get accounts => _accounts;
  double get totalBalance => _totalBalance;
  bool get isLoading => _isLoading;

  Future<void> loadAccounts(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _accounts = await _accountDao.getAllByUser(userId);
      _totalBalance = await _accountDao.getTotalBalance(userId);
    } catch (_) {
      // Silently handle — list stays empty
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAccount({
    required int userId,
    required String name,
    required String type,
    double initialBalance = 0,
    String? iconName,
    String? color,
    bool isIncludedInTotal = true,
  }) async {
    try {
      final now = DateTime.now();
      final account = Account(
        userId: userId,
        name: SecurityUtils.sanitise(name),
        type: type,
        balance: initialBalance,
        iconName: iconName ?? type,
        color: color,
        isIncludedInTotal: isIncludedInTotal,
        createdAt: now,
        updatedAt: now,
      );
      await _accountDao.insert(account);
      await loadAccounts(userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateAccount(Account account) async {
    try {
      final updated = account.copyWith(
        name: SecurityUtils.sanitise(account.name),
        updatedAt: DateTime.now(),
      );
      await _accountDao.update(updated);
      await loadAccounts(account.userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAccount(int accountId, int userId) async {
    try {
      await _accountDao.softDelete(accountId);
      await loadAccounts(userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> adjustBalance(int accountId, double newBalance, int userId) async {
    try {
      await _accountDao.setBalance(accountId, newBalance);
      await loadAccounts(userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Account? findById(int id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
