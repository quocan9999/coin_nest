import 'package:flutter/foundation.dart';
import '../database/category_dao.dart';
import '../database/loan_dao.dart';
import '../models/loan.dart';
import '../models/loan_payment.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import 'backup_alert_provider.dart';
import '../services/notification/reminder_coordinator.dart';
import '../utils/security_utils.dart';

class LoanProvider extends ChangeNotifier {
  final _loanDao = LoanDao();
  final _categoryDao = CategoryDao();
  final _reminderCoordinator = ReminderCoordinator();
  TransactionProvider? _transactionProvider;
  SettingsProvider? _settingsProvider;
  BackupAlertProvider? _backupAlertProvider;

  List<Loan> _loans = [];
  Map<String, double> _summary = {'borrowed': 0, 'lent': 0};
  bool _isLoading = false;
  String? _errorMessage;

  List<Loan> get loans => _loans;
  Map<String, double> get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Loan> get activeLoans =>
      _loans.where((loan) => loan.status == 'active').toList();
  List<Loan> get borrowedLoans =>
      _loans.where((loan) => loan.type == 'borrow').toList();
  List<Loan> get lentLoans =>
      _loans.where((loan) => loan.type == 'lend').toList();

  void setTransactionProvider(TransactionProvider transactionProvider) {
    _transactionProvider = transactionProvider;
  }

  void setSettingsProvider(SettingsProvider settingsProvider) {
    _settingsProvider = settingsProvider;
  }

  void setBackupAlertProvider(BackupAlertProvider backupAlertProvider) {
    _backupAlertProvider = backupAlertProvider;
  }

  Future<void> loadLoans(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _loans = await _loanDao.getAllByUser(userId);
      _summary = await _loanDao.getSummary(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
    await _syncDebtReminder();
  }

  Future<bool> addLoan({
    required int userId,
    required String type,
    required String personName,
    required double amount,
    double interestRate = 0,
    String? note,
    required DateTime startDate,
    DateTime? dueDate,
    int? accountId,
  }) async {
    try {
      _validateLoanInput(
        userId: userId,
        type: type,
        amount: amount,
        accountId: accountId,
        startDate: startDate,
        dueDate: dueDate,
      );

      final now = DateTime.now();
      final loan = Loan(
        userId: userId,
        type: type,
        personName: SecurityUtils.sanitise(personName),
        amount: amount,
        remainingAmount: amount,
        interestRate: interestRate,
        note: note != null ? SecurityUtils.sanitise(note) : null,
        startDate: startDate,
        dueDate: dueDate,
        accountId: accountId,
        createdAt: now,
        updatedAt: now,
      );

      await _loanDao.insertWithInitialTransaction(
        loan: loan,
        categoryId: await _defaultCategoryIdForInitialTransaction(
          userId: userId,
          loanType: type,
        ),
      );

      await _backupAlertProvider?.markChanged(userId, source: 'loan');
      await _reloadRelatedData(userId);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLoan({
    required int loanId,
    required int userId,
    required String type,
    required String personName,
    required double amount,
    double interestRate = 0,
    String? note,
    required DateTime startDate,
    DateTime? dueDate,
    required int accountId,
  }) async {
    try {
      _validateLoanInput(
        userId: userId,
        type: type,
        amount: amount,
        accountId: accountId,
        startDate: startDate,
        dueDate: dueDate,
      );

      final now = DateTime.now();
      final loan = Loan(
        id: loanId,
        userId: userId,
        type: type,
        personName: SecurityUtils.sanitise(personName),
        amount: amount,
        remainingAmount: amount,
        interestRate: interestRate,
        note: note != null ? SecurityUtils.sanitise(note) : null,
        startDate: startDate,
        dueDate: dueDate,
        accountId: accountId,
        createdAt: now,
        updatedAt: now,
      );

      await _loanDao.updateLoanWithTransactions(
        loan: loan,
        userId: userId,
        initialCategoryId: await _defaultCategoryIdForInitialTransaction(
          userId: userId,
          loanType: type,
        ),
        paymentCategoryId: await _defaultCategoryIdForPaymentTransaction(
          userId: userId,
          loanType: type,
        ),
      );

      await _backupAlertProvider?.markChanged(userId, source: 'loan');
      await _reloadRelatedData(userId);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordPayment(
    int loanId,
    double amount,
    int userId, {
    DateTime? paymentDate,
    String? note,
    int? accountId,
  }) async {
    try {
      final loan = await _loanDao.findByIdForUser(loanId, userId);
      if (loan == null) {
        throw StateError('Loan not found');
      }

      final resolvedAccountId = accountId ?? loan.accountId;
      if (resolvedAccountId == null || resolvedAccountId <= 0) {
        throw ArgumentError('Invalid account for payment');
      }

      await _loanDao.recordPaymentWithTransaction(
        loanId: loanId,
        userId: userId,
        amount: amount,
        paymentDate: paymentDate ?? DateTime.now(),
        note: note != null ? SecurityUtils.sanitise(note) : null,
        accountId: resolvedAccountId,
        categoryId: await _defaultCategoryIdForPaymentTransaction(
          userId: userId,
          loanType: loan.type,
        ),
      );

      await _backupAlertProvider?.markChanged(userId, source: 'loan_payment');
      await _reloadRelatedData(userId);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<LoanPayment>> getPaymentHistory(int loanId, int userId) {
    return _loanDao.getPaymentHistory(loanId, userId);
  }

  Future<Loan?> findLoanForTransaction({
    required int userId,
    int? loanId,
    int? transactionId,
  }) async {
    if (loanId != null) {
      return _loanDao.findByIdForUser(loanId, userId);
    }
    if (transactionId != null) {
      return _loanDao.findByTransactionForUser(transactionId, userId);
    }
    return null;
  }

  Future<bool> deleteLoan(int id, int userId) async {
    try {
      await _loanDao.deleteForUserWithRollback(id, userId);
      await _backupAlertProvider?.markChanged(userId, source: 'loan');
      await _reloadRelatedData(userId);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _validateLoanInput({
    required int userId,
    required String type,
    required double amount,
    required int? accountId,
    required DateTime startDate,
    DateTime? dueDate,
  }) {
    if (userId == 0) {
      throw ArgumentError('Invalid userId');
    }
    if (type != 'borrow' && type != 'lend') {
      throw ArgumentError('Invalid loan type');
    }
    if (amount <= 0) {
      throw ArgumentError('Amount must be > 0');
    }
    if (accountId == null || accountId <= 0) {
      throw ArgumentError('accountId required');
    }
    if (dueDate != null && dueDate.isBefore(startDate)) {
      throw ArgumentError('dueDate must be >= startDate');
    }
  }

  Future<void> _reloadRelatedData(int userId) async {
    final transactionProvider = _transactionProvider;
    await Future.wait([
      loadLoans(userId),
      if (transactionProvider != null) ...[
        transactionProvider.loadTransactions(userId),
        transactionProvider.loadRecentTransactions(userId),
      ],
    ]);
  }

  Future<void> _syncDebtReminder() async {
    final settingsProvider = _settingsProvider;
    if (settingsProvider == null) return;

    await _reminderCoordinator.syncReminders(
      dailyReminderEnabled: settingsProvider.dailyReminder,
      debtReminderEnabled: settingsProvider.debtReminder,
      reminderTime: settingsProvider.reminderTime,
      loans: _loans,
    );
  }

  Future<int?> _defaultCategoryIdForInitialTransaction({
    required int userId,
    required String loanType,
  }) {
    return _categoryDao.findDefaultCategoryId(
      userId: userId,
      type: loanType == 'borrow' ? 'income' : 'expense',
      name: loanType == 'borrow' ? 'Vay mượn' : 'Cho mượn',
    );
  }

  Future<int?> _defaultCategoryIdForPaymentTransaction({
    required int userId,
    required String loanType,
  }) {
    return _categoryDao.findDefaultCategoryId(
      userId: userId,
      type: loanType == 'borrow' ? 'expense' : 'income',
      name: loanType == 'borrow' ? 'Trả nợ' : 'Thu nợ',
    );
  }
}
