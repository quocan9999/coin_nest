import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/loan_dao.dart';
import '../screens/loans/loan_detail_screen.dart';
import '../screens/transactions/add_transaction_screen.dart';
import '../utils/constants.dart';

class NavigationService {
  NavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool _isNotificationNavigationReady = false;
  static String? _pendingNotificationPayload;

  static Future<void> handleNotificationPayload(String payload) async {
    _pendingNotificationPayload = payload;
    await _flushPendingNotificationPayload();
  }

  static void markNotificationNavigationReady() {
    _isNotificationNavigationReady = true;
    unawaited(_flushPendingNotificationPayload());
  }

  static Future<void> _flushPendingNotificationPayload() async {
    if (!_isNotificationNavigationReady) return;

    final payload = _pendingNotificationPayload;
    if (payload == null) return;

    _pendingNotificationPayload = null;
    await _navigateFromNotificationPayload(payload);
  }

  static Future<void> _navigateFromNotificationPayload(String payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(AppConstants.prefLoggedInUserId);
      if (userId == null) {
        debugPrint('Notification navigation skipped: no logged-in user.');
        return;
      }

      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('Notification navigation skipped: invalid payload.');
        return;
      }

      final type = decoded['type'];
      switch (type) {
        case 'daily_reminder':
          _push(const AddTransactionScreen());
        case 'loan_due':
          await _openLoanDetail(decoded['loanId'], userId);
        default:
          debugPrint('Notification navigation skipped: unknown type $type.');
      }
    } catch (error, stackTrace) {
      debugPrint('NavigationService notification handling failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> _openLoanDetail(Object? rawLoanId, int userId) async {
    final loanId = rawLoanId is int
        ? rawLoanId
        : int.tryParse(rawLoanId?.toString() ?? '');
    if (loanId == null) {
      debugPrint('Notification navigation skipped: invalid loanId.');
      return;
    }

    final loan = await LoanDao().findByIdForUser(loanId, userId);
    if (loan == null) {
      debugPrint('Notification navigation skipped: loan $loanId not found.');
      return;
    }

    _push(LoanDetailScreen(loan: loan));
  }

  static void _push(Widget screen) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _isNotificationNavigationReady = false;
      return;
    }

    navigator.push(MaterialPageRoute(builder: (_) => screen));
  }
}
