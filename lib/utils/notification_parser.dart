import 'package:flutter/foundation.dart' show debugPrint;

import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction_model.dart';
import 'constants.dart';

class NotificationParser {
  NotificationParser._();

  static final RegExp _signedAmountPattern = RegExp(
    r'([+-])\s*([\d.,]+)\s*(?:VND|đ|₫)',
    caseSensitive: false,
  );
  static final RegExp _gdAmountPattern = RegExp(
    r'\bGD\s*:\s*([+-])\s*([\d.,]+)\s*(?:VND|đ|₫)',
    caseSensitive: false,
  );
  static final RegExp _postingAmountPattern = RegExp(
    r'\bPS\s*:\s*([+-])\s*([\d.,]+)\s*(?:VND|đ|₫)',
    caseSensitive: false,
  );
  static final RegExp _momoAmountPattern = RegExp(
    r'Số\s*tiền\s*([\d.,]+)\s*(?:VND|đ|₫)',
    caseSensitive: false,
  );

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
      final parsedAmount = _extractAmount(text);
      if (parsedAmount == null || parsedAmount.amount <= 0) return null;

      final type = parsedAmount.sign == '+'
          ? AppConstants.typeIncome
          : parsedAmount.sign == '-'
          ? AppConstants.typeExpense
          : _inferTypeFromText(text);
      if (type == null) return null;

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
      final occurredAt = _extractDateTime(text) ?? receivedAt ?? DateTime.now();
      final note = _extractNote(text);

      return TransactionModel(
        userId: userId,
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        amount: parsedAmount.amount,
        note: note.isEmpty ? 'Giao dịch tự động' : note,
        date: occurredAt,
        time: _formatTime(occurredAt),
        createdAt: receivedAt ?? DateTime.now(),
        updatedAt: receivedAt ?? DateTime.now(),
      );
    } catch (error, stackTrace) {
      debugPrint('Cannot parse bank notification: $error\n$stackTrace');
      return null;
    }
  }

  static _ParsedAmount? _extractAmount(String text) {
    for (final pattern in [
      _gdAmountPattern,
      _postingAmountPattern,
      _signedAmountPattern,
    ]) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      return _ParsedAmount(
        sign: match.group(1),
        amount: _parseAmount(match.group(2) ?? ''),
      );
    }

    final momoMatch = _momoAmountPattern.firstMatch(text);
    if (momoMatch == null) return null;

    return _ParsedAmount(amount: _parseAmount(momoMatch.group(1) ?? ''));
  }

  static String? _inferTypeFromText(String text) {
    final normalized = _removeVietnameseMarks(text).toLowerCase();
    if (normalized.contains('nhan tien') ||
        normalized.contains('duoc chuyen') ||
        normalized.contains('hoan tien') ||
        normalized.contains('cashin')) {
      return AppConstants.typeIncome;
    }

    if (normalized.contains('tru tien') ||
        normalized.contains('thanh toan') ||
        normalized.contains('chuyen tien') ||
        normalized.contains('rut tien') ||
        normalized.contains('cashout')) {
      return AppConstants.typeExpense;
    }

    return null;
  }

  static String _extractNote(String text) {
    final notePatterns = [
      RegExp(r'\bND\s*:\s*([^\n|]+)', caseSensitive: false),
      RegExp(r'kèm\s*lời\s*nhắn\s*:\s*"([^"]+)"', caseSensitive: false),
      RegExp(r'\bRef\s+(.+)', caseSensitive: false),
    ];

    for (final pattern in notePatterns) {
      final match = pattern.firstMatch(text);
      final note = match?.group(1)?.trim();
      if (note != null && note.isNotEmpty) {
        if (pattern.pattern.contains(r'\bRef')) {
          return _extractUsefulRefNote(note);
        }
        return note;
      }
    }

    return _extractFallbackNote(text);
  }

  static String _extractUsefulRefNote(String refText) {
    final refParts = refText
        .split(RegExp(r'[.\n|]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    for (final part in refParts) {
      final normalized = _removeVietnameseMarks(part).toLowerCase();
      if (normalized.contains('chuyen tien') ||
          normalized.contains('thanh toan') ||
          normalized.contains('cashin') ||
          normalized.contains('cashout')) {
        return part;
      }
    }

    return refText.trim();
  }

  static String _extractFallbackNote(String text) {
    final lines = text
        .split(RegExp(r'[\n|]'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where((line) => !_isMetadataLine(line))
        .toList();

    if (lines.isEmpty) return '';

    final firstUsefulLine = lines.firstWhere(
      (line) => !_signedAmountPattern.hasMatch(line),
      orElse: () => lines.first,
    );
    return firstUsefulLine;
  }

  static bool _isMetadataLine(String line) {
    final normalized = _removeVietnameseMarks(line).toLowerCase();
    return normalized.startsWith('tai khoan:') ||
        normalized.startsWith('tk:') ||
        normalized.startsWith('tk ') ||
        normalized.startsWith('so du:') ||
        normalized.startsWith('sd:') ||
        normalized.startsWith('sd kha dung:') ||
        normalized.startsWith('so gd:') ||
        normalized.startsWith('ticker text') ||
        normalized.startsWith('thong bao');
  }

  static DateTime? _extractDateTime(String text) {
    final vcbMatch = RegExp(
      r'lúc\s*(\d{2})-(\d{2})-(\d{4})\s+(\d{2}):(\d{2})(?::(\d{2}))?',
      caseSensitive: false,
    ).firstMatch(text);
    if (vcbMatch != null) {
      return _buildDateTime(
        day: vcbMatch.group(1),
        month: vcbMatch.group(2),
        year: vcbMatch.group(3),
        hour: vcbMatch.group(4),
        minute: vcbMatch.group(5),
        second: vcbMatch.group(6),
      );
    }

    final slashMatch = RegExp(
      r'(\d{2})/(\d{2})/(\d{2,4})[; ]+(\d{2}):(\d{2})(?::(\d{2}))?',
    ).firstMatch(text);
    if (slashMatch != null) {
      return _buildDateTime(
        day: slashMatch.group(1),
        month: slashMatch.group(2),
        year: slashMatch.group(3),
        hour: slashMatch.group(4),
        minute: slashMatch.group(5),
        second: slashMatch.group(6),
      );
    }

    return null;
  }

  static DateTime? _buildDateTime({
    required String? day,
    required String? month,
    required String? year,
    required String? hour,
    required String? minute,
    String? second,
  }) {
    final parsedDay = int.tryParse(day ?? '');
    final parsedMonth = int.tryParse(month ?? '');
    final parsedYear = int.tryParse(year ?? '');
    final parsedHour = int.tryParse(hour ?? '');
    final parsedMinute = int.tryParse(minute ?? '');
    final parsedSecond = int.tryParse(second ?? '0') ?? 0;

    if (parsedDay == null ||
        parsedMonth == null ||
        parsedYear == null ||
        parsedHour == null ||
        parsedMinute == null) {
      return null;
    }

    final fullYear = parsedYear < 100 ? 2000 + parsedYear : parsedYear;
    return DateTime(
      fullYear,
      parsedMonth,
      parsedDay,
      parsedHour,
      parsedMinute,
      parsedSecond,
    );
  }

  static double _parseAmount(String rawAmount) {
    final digits = rawAmount.replaceAll(RegExp(r'[^0-9]'), '');
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

  static String _removeVietnameseMarks(String input) {
    const replacements = {
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
      'À': 'A',
      'Á': 'A',
      'Ạ': 'A',
      'Ả': 'A',
      'Ã': 'A',
      'Â': 'A',
      'Ầ': 'A',
      'Ấ': 'A',
      'Ậ': 'A',
      'Ẩ': 'A',
      'Ẫ': 'A',
      'Ă': 'A',
      'Ằ': 'A',
      'Ắ': 'A',
      'Ặ': 'A',
      'Ẳ': 'A',
      'Ẵ': 'A',
      'È': 'E',
      'É': 'E',
      'Ẹ': 'E',
      'Ẻ': 'E',
      'Ẽ': 'E',
      'Ê': 'E',
      'Ề': 'E',
      'Ế': 'E',
      'Ệ': 'E',
      'Ể': 'E',
      'Ễ': 'E',
      'Ì': 'I',
      'Í': 'I',
      'Ị': 'I',
      'Ỉ': 'I',
      'Ĩ': 'I',
      'Ò': 'O',
      'Ó': 'O',
      'Ọ': 'O',
      'Ỏ': 'O',
      'Õ': 'O',
      'Ô': 'O',
      'Ồ': 'O',
      'Ố': 'O',
      'Ộ': 'O',
      'Ổ': 'O',
      'Ỗ': 'O',
      'Ơ': 'O',
      'Ờ': 'O',
      'Ớ': 'O',
      'Ợ': 'O',
      'Ở': 'O',
      'Ỡ': 'O',
      'Ù': 'U',
      'Ú': 'U',
      'Ụ': 'U',
      'Ủ': 'U',
      'Ũ': 'U',
      'Ư': 'U',
      'Ừ': 'U',
      'Ứ': 'U',
      'Ự': 'U',
      'Ử': 'U',
      'Ữ': 'U',
      'Ỳ': 'Y',
      'Ý': 'Y',
      'Ỵ': 'Y',
      'Ỷ': 'Y',
      'Ỹ': 'Y',
      'Đ': 'D',
    };

    final buffer = StringBuffer();
    for (final codeUnit in input.runes) {
      final char = String.fromCharCode(codeUnit);
      buffer.write(replacements[char] ?? char);
    }
    return buffer.toString();
  }
}

class _ParsedAmount {
  const _ParsedAmount({required this.amount, this.sign});

  final double amount;
  final String? sign;
}
