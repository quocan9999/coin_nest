import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupAlertProvider extends ChangeNotifier {
  BackupAlertProvider() {
    _instances.add(this);
  }

  static final Set<BackupAlertProvider> _instances = {};

  int _currentUserId = 0;
  int _pendingCount = 0;
  int _pendingTransactionCount = 0;
  bool _isLoaded = false;

  int get pendingCount => _pendingCount;
  int get pendingTransactionCount => _pendingTransactionCount;
  bool get hasPendingChanges => _pendingCount > 0;
  bool get hasPendingTransactions => _pendingTransactionCount > 0;
  bool get isLoaded => _isLoaded;

  String get badgeLabel {
    if (_pendingCount <= 0) return '';
    if (_pendingCount > 99) return '99+';
    return _pendingCount.toString();
  }

  Future<void> loadForUser(int userId) async {
    if (userId == 0) {
      _currentUserId = 0;
      _pendingCount = 0;
      _pendingTransactionCount = 0;
      _isLoaded = true;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _currentUserId = userId;
    _pendingCount = prefs.getInt(_keyFor(userId)) ?? 0;
    _pendingTransactionCount = prefs.getInt(_transactionKeyFor(userId)) ?? 0;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> markChanged(int userId, {String? source}) async {
    await markUserChanged(userId, source: source);
  }

  static Future<void> markUserChanged(int userId, {String? source}) async {
    if (userId == 0) return;

    final prefs = await SharedPreferences.getInstance();
    final nextCount = (prefs.getInt(_keyFor(userId)) ?? 0) + 1;
    await prefs.setInt(_keyFor(userId), nextCount);
    final isTransactionChange = source == 'transaction';
    final nextTransactionCount = isTransactionChange
        ? (prefs.getInt(_transactionKeyFor(userId)) ?? 0) + 1
        : (prefs.getInt(_transactionKeyFor(userId)) ?? 0);
    if (isTransactionChange) {
      await prefs.setInt(_transactionKeyFor(userId), nextTransactionCount);
    }

    for (final instance in _instances) {
      if (instance._currentUserId == userId || !instance._isLoaded) {
        instance._currentUserId = userId;
        instance._pendingCount = nextCount;
        instance._pendingTransactionCount = nextTransactionCount;
        instance._isLoaded = true;
        instance.notifyListeners();
      }
    }
  }

  Future<void> clearPending(int userId) async {
    if (userId == 0) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFor(userId), 0);
    await prefs.setInt(_transactionKeyFor(userId), 0);

    if (_currentUserId == userId || !_isLoaded) {
      _currentUserId = userId;
      _pendingCount = 0;
      _pendingTransactionCount = 0;
      _isLoaded = true;
      notifyListeners();
    }
  }

  static String _keyFor(int userId) => 'backup_pending_changes_$userId';
  static String _transactionKeyFor(int userId) =>
      'backup_pending_transaction_changes_$userId';

  @override
  void dispose() {
    _instances.remove(this);
    super.dispose();
  }
}
