import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/loan_dao.dart';
import '../database/transaction_dao.dart';
import '../models/loan.dart';
import '../models/loan_payment.dart';
import '../providers/transaction_provider.dart';
import '../services/loan_notification_scheduler.dart';
import '../utils/constants.dart';
import '../utils/security_utils.dart';

class LoanProvider extends ChangeNotifier {
  final _loanDao = LoanDao();
  final _txnDao = TransactionDao();
  final _txnProvider = TransactionProvider();

  List<Loan> _loans = [];
  Map<String, double> _summary = {'borrowed': 0, 'lent': 0};
  bool _isLoading = false;
  String? _errorMessage;

  List<Loan> get loans => _loans;
  Map<String, double> get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Loan> get activeLoans =>
      _loans.where((l) => l.status == 'active').toList();
  List<Loan> get borrowedLoans =>
      _loans.where((l) => l.type == 'borrow').toList();
  List<Loan> get lentLoans => _loans.where((l) => l.type == 'lend').toList();

  Future<void> loadLoans(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _loans = await _loanDao.getAllByUser(userId);
      _summary = await _loanDao.getSummary(userId);
      _errorMessage = null;
    } catch (e) {
      debugPrint('LoanProvider.loadLoans failed: $e');
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
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
    int? loanId;
    int? txnId;

    try {
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

      loanId = await _loanDao.insert(loan);

      final txnType = type == 'borrow' ? 'loan' : 'lend';
      txnId = await _txnProvider.addTransactionAndReturnId(
        userId: userId,
        accountId: accountId,
        type: txnType,
        amount: amount,
        date: startDate,
        loanId: loanId,
      );

      if (txnId == null) {
        throw StateError('Failed to create loan transaction');
      }

      await _loanDao.updateTransactionId(loanId: loanId, transactionId: txnId);
      await _txnDao.updateLoanId(transactionId: txnId, loanId: loanId);

      await Future.wait([
        loadLoans(userId),
        _txnProvider.loadTransactions(userId),
      ]);

      await _rescheduleLoanNotificationsIfEnabled();

      _errorMessage = null;
      return true;
    } catch (e) {
      if (txnId != null) {
        await _txnDao.deleteWithBalance(txnId);
      }
      if (loanId != null) {
        await _loanDao.deleteForUser(loanId, userId);
      }
      debugPrint('LoanProvider.addLoan failed: $e');
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
    int? txnId;

    try {
      final loan = await _loanDao.findByIdForUser(loanId, userId);
      if (loan == null) {
        throw StateError('Loan not found');
      }

      final resolvedAccountId = accountId ?? loan.accountId;
      if (resolvedAccountId == null || resolvedAccountId <= 0) {
        throw ArgumentError('Invalid account for payment');
      }

      final txnType = loan.type == 'borrow' ? 'expense' : 'income';
      final paidAt = paymentDate ?? DateTime.now();

      txnId = await _txnProvider.addTransactionAndReturnId(
        userId: userId,
        accountId: resolvedAccountId,
        type: txnType,
        amount: amount,
        date: paidAt,
        note: note != null ? SecurityUtils.sanitise(note) : null,
        loanId: loanId,
      );

      if (txnId == null) {
        throw StateError('Failed to create payment transaction');
      }

      await _loanDao.recordPayment(
        loanId: loanId,
        userId: userId,
        amount: amount,
        paymentDate: paidAt,
        note: note != null ? SecurityUtils.sanitise(note) : null,
        transactionId: txnId,
      );

      await Future.wait([
        loadLoans(userId),
        _txnProvider.loadTransactions(userId),
      ]);

      await _rescheduleLoanNotificationsIfEnabled();

      _errorMessage = null;
      return true;
    } catch (e) {
      if (txnId != null) {
        await _txnDao.deleteWithBalance(txnId);
      }
      debugPrint('LoanProvider.recordPayment failed: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<LoanPayment>> getPaymentHistory(int loanId, int userId) {
    return _loanDao.getPaymentHistory(loanId, userId);
  }

  Future<bool> deleteLoan(int id, int userId) async {
    try {
      await _loanDao.deleteForUser(id, userId);
      await loadLoans(userId);
      await _rescheduleLoanNotificationsIfEnabled();
      _errorMessage = null;
      return true;
    } catch (e) {
      debugPrint('LoanProvider.deleteLoan failed: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _rescheduleLoanNotificationsIfEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled =
          prefs.getBool(AppConstants.prefLoanReminderEnabled) ?? true;

      if (enabled) {
        final daysOffsets = _readLoanReminderDays(prefs);
        await LoanNotificationScheduler.rescheduleAll(_loans, daysOffsets);
      }
    } catch (error, stackTrace) {
      debugPrint(
        'LoanProvider._rescheduleLoanNotificationsIfEnabled failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  List<int> _readLoanReminderDays(SharedPreferences prefs) {
    try {
      final rawDays = prefs.getString(AppConstants.prefLoanReminderDays);
      if (rawDays == null) {
        return List<int>.from(AppConstants.defaultLoanReminderDays);
      }

      final decoded = jsonDecode(rawDays);
      if (decoded is! List) {
        return List<int>.from(AppConstants.defaultLoanReminderDays);
      }

      final days = decoded
          .whereType<num>()
          .map((value) => value.toInt())
          .where(
            (value) =>
                value >= AppConstants.minLoanReminderDayOffset &&
                value <= AppConstants.maxLoanReminderDayOffset,
          )
          .toSet()
          .toList();
      days.sort((a, b) => b.compareTo(a));
      return days;
    } catch (error, stackTrace) {
      debugPrint('LoanProvider._readLoanReminderDays failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return List<int>.from(AppConstants.defaultLoanReminderDays);
    }
  }
}
