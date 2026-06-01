import 'package:flutter/material.dart';
import 'backup_alert_provider.dart';
import '../database/transaction_dao.dart';
import '../models/transaction_model.dart';
import '../utils/security_utils.dart';

/// Manages transaction listing, filtering, and CRUD.
class TransactionProvider extends ChangeNotifier {
  final _txnDao = TransactionDao();
  BackupAlertProvider? _backupAlertProvider;

  List<TransactionModel> _transactions = [];
  // --- BỔ SUNG: Kênh dữ liệu riêng cho Trang chủ ---
  List<TransactionModel> _recentTransactions = [];
  bool _isLoading = false;
  int _revision = 0;

  String? _filterType;
  int? _filterCategoryId;

  // -- BỘ LỌC MỚI --
  int? _filterAccountId; // null = Tất cả tài khoản
  String _timeFilter =
      'all'; // 'all', 'today', 'this_month', 'last_month', 'custom'
  DateTimeRange? _customDateRange;
  String _searchQuery = ''; // Tìm kiếm văn bản trực tiếp

  List<TransactionModel> get transactions => _transactions;
  // --- BỔ SUNG: Getter lấy 5 giao dịch gần nhất ---
  List<TransactionModel> get recentTransactions => _recentTransactions;
  bool get isLoading => _isLoading;
  int get revision => _revision;

  int? get filterAccountId => _filterAccountId;
  String get timeFilter => _timeFilter;
  String get searchQuery => _searchQuery;
  DateTimeRange? get customDateRange => _customDateRange;

  void setBackupAlertProvider(BackupAlertProvider backupAlertProvider) {
    _backupAlertProvider = backupAlertProvider;
  }

  // HÀM CHUẨN HÓA: Loại bỏ dấu tiếng Việt để tìm kiếm linh hoạt
  String _normalizeString(String text) {
    const withDia =
        'áàảãạâấầẩẫậăắằẳẵặđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ';
    const withoutDia =
        'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy';
    String result = text.toLowerCase();
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
  }

  /// Nhóm giao dịch theo ngày (CÓ KẾT HỢP LỌC TÌM KIẾM KHÔNG DẤU)
  Map<String, List<TransactionModel>> get groupedByDate {
    final map = <String, List<TransactionModel>>{};
    final query = _normalizeString(_searchQuery.trim());

    for (final txn in _transactions) {
      // 1. Lọc theo Thanh tìm kiếm (Tìm trong Ghi chú HOẶC Tên hạng mục)
      if (query.isNotEmpty) {
        final note = _normalizeString(txn.note ?? '');
        final catName = _normalizeString(
          txn.categoryName ?? _getTypeLabel(txn.type),
        );

        // Nếu cả ghi chú và hạng mục đều không chứa từ khóa -> Bỏ qua giao dịch này
        if (!note.contains(query) && !catName.contains(query)) {
          continue;
        }
      }

      // 2. Phân nhóm theo ngày
      final label = _relativeDateLabel(txn.date);
      map.putIfAbsent(label, () => []).add(txn);
    }
    return map;
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'expense':
        return 'Chi tiêu';
      case 'income':
        return 'Thu nhập';
      case 'transfer':
        return 'Chuyển khoản';
      default:
        return type;
    }
  }

  // ĐÃ NÂNG CẤP: Hiển thị ngày tháng chính xác cho các giao dịch cũ
  String _relativeDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) {
      return 'HÔM NAY';
    }
    if (diff == 1) {
      return 'HÔM QUA';
    }

    // Nếu cũ hơn hôm qua, trả về định dạng DD/MM/YYYY
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> loadTransactions(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? startStr;
      String? endStr;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Xác định khoảng thời gian truy vấn DB dựa trên _timeFilter
      switch (_timeFilter) {
        case 'today':
          startStr = today.toIso8601String().split('T').first;
          endStr = today.toIso8601String().split('T').first;
          break;
        case 'this_month':
          startStr = DateTime(
            now.year,
            now.month,
            1,
          ).toIso8601String().split('T').first;
          endStr = DateTime(
            now.year,
            now.month + 1,
            0,
          ).toIso8601String().split('T').first;
          break;
        case 'last_month':
          startStr = DateTime(
            now.year,
            now.month - 1,
            1,
          ).toIso8601String().split('T').first;
          endStr = DateTime(
            now.year,
            now.month,
            0,
          ).toIso8601String().split('T').first;
          break;
        case 'custom':
          if (_customDateRange != null) {
            startStr = _customDateRange!.start
                .toIso8601String()
                .split('T')
                .first;
            endStr = _customDateRange!.end.toIso8601String().split('T').first;
          }
          break;
        case 'all':
        default:
          startStr = '2000-01-01';
          endStr = '2100-12-31';
          break;
      }

      _transactions = await _txnDao.getByUser(
        userId,
        startDate: startStr,
        endDate: endStr,
        type: _filterType,
        categoryId: _filterCategoryId,
        accountId: _filterAccountId,
        searchQuery: null,
      );
    } catch (_) {
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- BỔ SUNG: Hàm tải riêng giao dịch gần nhất ---
  Future<void> loadRecentTransactions(int userId) async {
    try {
      _recentTransactions = await _txnDao.getRecent(userId, count: 5);
      notifyListeners();
    } catch (_) {
      _recentTransactions = [];
    }
  }

  // ─── CRUD Functions ──────────────────────────────────────────

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
    final txnId = await addTransactionAndReturnId(
      userId: userId,
      accountId: accountId,
      toAccountId: toAccountId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      note: note,
      date: date,
      time: time,
      loanId: loanId,
    );
    return txnId != null;
  }

  Future<int?> addTransactionAndReturnId({
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

      final txnId = await _txnDao.insertWithBalance(txn);
      await _backupAlertProvider?.markChanged(userId, source: 'transaction');
      _revision++;
      await loadTransactions(userId);
      await loadRecentTransactions(
        userId,
      ); // <--- VÁ LỖI: Cập nhật danh sách gần đây tức thì
      return txnId;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateTransaction({
    required int txnId,
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
    required DateTime createdAt,
  }) async {
    try {
      final oldTxn = await _txnDao.findById(txnId);
      if (oldTxn == null ||
          oldTxn.isLoanLinked ||
          loanId != null ||
          type == 'loan' ||
          type == 'lend') {
        return false;
      }

      final now = DateTime.now();
      final txn = TransactionModel(
        id: txnId,
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
        createdAt: createdAt,
        updatedAt: now,
      );

      await _txnDao.updateWithBalance(txn);
      await _backupAlertProvider?.markChanged(userId, source: 'transaction');
      _revision++;
      await loadTransactions(userId);
      await loadRecentTransactions(
        userId,
      ); // <--- VÁ LỖI: Cập nhật danh sách gần đây tức thì
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteTransaction(int txnId, int userId) async {
    try {
      final txn = await _txnDao.findById(txnId);
      if (txn == null || txn.isLoanLinked) {
        return false;
      }

      await _txnDao.deleteWithBalance(txnId);
      await _backupAlertProvider?.markChanged(userId, source: 'transaction');
      _revision++;
      await loadTransactions(userId);
      await loadRecentTransactions(
        userId,
      ); // <--- VÁ LỖI: Cập nhật danh sách gần đây tức thì
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<TransactionModel>> getRecent(int userId, {int count = 5}) async {
    return _txnDao.getRecent(userId, count: count);
  }

  // ─── Filter Setters ─────────────────────────────────────────

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

  void setTimeFilter(String filter, {DateTimeRange? customRange}) {
    _timeFilter = filter;
    _customDateRange = customRange;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _filterType = null;
    _filterCategoryId = null;
    _filterAccountId = null;
    _searchQuery = '';
    _timeFilter = 'all';
    _customDateRange = null;
    notifyListeners();
  }
}
