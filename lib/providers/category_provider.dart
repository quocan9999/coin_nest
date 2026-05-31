import 'package:flutter/foundation.dart' hide Category;
import '../database/category_dao.dart';
import '../models/category.dart';
import 'backup_alert_provider.dart';
import '../utils/security_utils.dart';

class CategoryProvider extends ChangeNotifier {
  final _categoryDao = CategoryDao();
  BackupAlertProvider? _backupAlertProvider;
  List<Category> _expenseCategories = [];
  List<Category> _incomeCategories = [];
  bool _isLoading = false;

  List<Category> get expenseCategories => _expenseCategories;
  List<Category> get incomeCategories => _incomeCategories;
  bool get isLoading => _isLoading;

  void setBackupAlertProvider(BackupAlertProvider backupAlertProvider) {
    _backupAlertProvider = backupAlertProvider;
  }

  Future<void> loadCategories(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _expenseCategories = await _categoryDao.getExpenseCategories(userId);
      _incomeCategories = await _categoryDao.getIncomeCategories(userId);
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addCategory({
    required int userId,
    required String name,
    required String type,
    required String iconName,
    String? color,
    int? parentId,
  }) async {
    try {
      final cat = Category(
        userId: userId,
        name: SecurityUtils.sanitise(name),
        type: type,
        iconName: iconName,
        color: color,
        parentId: parentId,
        createdAt: DateTime.now(),
      );
      await _categoryDao.insert(cat);
      await _backupAlertProvider?.markChanged(userId, source: 'category');
      await loadCategories(userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCategory(Category category) async {
    try {
      await _categoryDao.update(
        category.copyWith(name: SecurityUtils.sanitise(category.name)),
      );
      await _backupAlertProvider?.markChanged(
        category.userId,
        source: 'category',
      );
      await loadCategories(category.userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCategory(int id, int userId) async {
    try {
      await _categoryDao.softDelete(id);
      await _backupAlertProvider?.markChanged(userId, source: 'category');
      await loadCategories(userId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
