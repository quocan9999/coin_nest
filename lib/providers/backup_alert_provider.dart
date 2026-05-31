import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupAlertProvider extends ChangeNotifier {
  int _currentUserId = 0;
  int _pendingCount = 0;
  bool _isLoaded = false;

  int get pendingCount => _pendingCount;
  bool get hasPendingChanges => _pendingCount > 0;
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
      _isLoaded = true;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _currentUserId = userId;
    _pendingCount = prefs.getInt(_keyFor(userId)) ?? 0;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> markChanged(int userId, {String? source}) async {
    if (userId == 0) return;

    final prefs = await SharedPreferences.getInstance();
    final nextCount = (prefs.getInt(_keyFor(userId)) ?? 0) + 1;
    await prefs.setInt(_keyFor(userId), nextCount);

    if (_currentUserId == userId || !_isLoaded) {
      _currentUserId = userId;
      _pendingCount = nextCount;
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> clearPending(int userId) async {
    if (userId == 0) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFor(userId), 0);

    if (_currentUserId == userId || !_isLoaded) {
      _currentUserId = userId;
      _pendingCount = 0;
      _isLoaded = true;
      notifyListeners();
    }
  }

  String _keyFor(int userId) => 'backup_pending_changes_$userId';
}
