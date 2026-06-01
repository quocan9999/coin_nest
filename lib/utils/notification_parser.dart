import 'package:flutter/foundation.dart' show debugPrint;

import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction_model.dart';
import 'constants.dart';

class NotificationParser {
  NotificationParser._();

  static TransactionModel? parseNotification({
    required String notificationText,
    required List<Account> accounts,
    required List<Category> expenseCategories,
    required List<Category> incomeCategories,
    required int? savedExpenseAccountId,
    required int? savedIncomeAccountId,
    required int userId,
    DateTime? receivedAt,
  }) {
    final text = notificationText.trim();
    if (text.isEmpty) return null;

    try {
      final amountPart = _extractTransactionPart(text);
      final note = _extractNote(text);
      if (amountPart == null || note == null) return null;

      final type = amountPart.contains('+')
          ? AppConstants.typeIncome
          : AppConstants.typeExpense;
      final amount = _parseAmount(amountPart);
      if (amount <= 0) return null;

      final accountId = _resolveAccountId(
        type: type,
        accounts: accounts,
        savedExpenseAccountId: savedExpenseAccountId,
        savedIncomeAccountId: savedIncomeAccountId,
      );
      if (accountId == null) return null;

      final categoryId = _resolveCategoryId(
        type: type,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
      );
      final now = receivedAt ?? DateTime.now();

      return TransactionModel(
        userId: userId,
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        note: note.isEmpty ? 'Giao dịch tự động' : note,
        date: now,
        time: _formatTime(now),
        createdAt: now,
        updatedAt: now,
      );
    } catch (error, stackTrace) {
      debugPrint('Cannot parse bank notification: $error\n$stackTrace');
      return null;
    }
  }

  static String? _extractTransactionPart(String text) {
    final parts = text.split('|').map((part) => part.trim());
    for (final part in parts) {
      if (part.startsWith('DG:')) {
        return part;
      }
    }
    return null;
  }

  static String? _extractNote(String text) {
    final parts = text.split('|').map((part) => part.trim());
    for (final part in parts) {
      if (part.startsWith('ND:')) {
        return part.replaceFirst('ND:', '').trim();
      }
    }
    return null;
  }

  static double _parseAmount(String amountPart) {
    final match = RegExp(
      r'[-+]?\s*[\d.,]+',
    ).firstMatch(amountPart.toUpperCase().split('VND').first);
    if (match == null) return 0;

    final digits = match.group(0)?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    return double.tryParse(digits) ?? 0;
  }

  static int? _resolveAccountId({
    required String type,
    required List<Account> accounts,
    required int? savedExpenseAccountId,
    required int? savedIncomeAccountId,
  }) {
    final savedAccountId = type == AppConstants.typeExpense
        ? savedExpenseAccountId
        : savedIncomeAccountId;
    if (savedAccountId != null &&
        accounts.any((account) => account.id == savedAccountId)) {
      return savedAccountId;
    }

    if (accounts.isEmpty) return null;
    return accounts.first.id;
  }

  static int? _resolveCategoryId({
    required String type,
    required List<Category> expenseCategories,
    required List<Category> incomeCategories,
  }) {
    final categories = type == AppConstants.typeExpense
        ? expenseCategories
        : incomeCategories;
    if (categories.isEmpty) return null;
    return categories.first.id;
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
