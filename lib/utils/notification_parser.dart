import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/account.dart';
import '../models/category.dart';

class NotificationParser {
  static TransactionModel? parseNotification({
    required String notificationText,
    required List<Account> accounts,
    required List<Category> expenseCategories,
    required List<Category> incomeCategories,
    required int? savedExpenseAccountId, 
    required int? savedIncomeAccountId,
    required int userId,
  }) {
    try {
      // Ràng buộc cấu trúc tin nhắn MBBank
      if (!notificationText.contains('|') || !notificationText.contains('ND:')) {
        return null;
      }

      List<String> parts = notificationText.split('|');
      String dgPart = '';
      String ndPart = '';

      for (var part in parts) {
        if (part.trim().startsWith('DG:')) dgPart = part.trim();
        if (part.trim().startsWith('ND:')) ndPart = part.trim();
      }

      debugPrint("🔍 Bóc tách tin nhắn - DG Part: \"$dgPart\", ND Part: \"$ndPart\"");

      if (dgPart.isEmpty || ndPart.isEmpty) {
        debugPrint("⚠️ Thiếu phần DG hoặc ND trong tin nhắn.");
        return null;
      }

      // Xác định loại giao dịch
      String type = 'expense';
      if (dgPart.contains('+')) {
        type = 'income';
      } else if (dgPart.contains('-')) {
        type = 'expense';
      }
      debugPrint("🔍 Loại giao dịch xác định: $type");

      // Xác định tài khoản
      int? targetAccountId = (type == 'expense') ? savedExpenseAccountId : savedIncomeAccountId;
      if (targetAccountId == null || !accounts.any((acc) => acc.id == targetAccountId)) {
        if (accounts.isNotEmpty) {
          debugPrint("⚠️ Tài khoản mặc định cho $type chưa được cấu hình hoặc không hợp lệ. Tự động chọn tài khoản đầu tiên: ${accounts.first.name} (ID: ${accounts.first.id})");
          targetAccountId = accounts.first.id;
        } else {
          debugPrint("❌ Không tìm thấy tài khoản nào khả dụng cho User.");
          return null;
        }
      }
      debugPrint("🔍 Sử dụng tài khoản ID: $targetAccountId");

      // Bóc tách số tiền (loại bỏ mọi ký tự không phải số, hỗ trợ case-insensitive 'VND')
      String amountPart = dgPart.toUpperCase().split('VND')[0];
      String rawAmount = amountPart.replaceAll(RegExp(r'[^0-9]'), '');
      double amount = double.tryParse(rawAmount) ?? 0.0;
      debugPrint("🔍 Số tiền bóc tách: $amount từ chuỗi gốc \"$amountPart\"");
      if (amount <= 0) {
        debugPrint("⚠️ Số tiền bóc tách không hợp lệ (<= 0).");
        return null;
      }

      // Bóc tách ghi chú
      String note = ndPart.replaceFirst('ND:', '').trim();

      // Gán hạng mục mặc định
      int? defaultCategoryId;
      if (type == 'expense' && expenseCategories.isNotEmpty) {
        defaultCategoryId = expenseCategories.first.id;
      } else if (type == 'income' && incomeCategories.isNotEmpty) {
        defaultCategoryId = incomeCategories.first.id;
      }
      debugPrint("🔍 Hạng mục mặc định gán: ID $defaultCategoryId");

      return TransactionModel(
        userId: userId,
        accountId: targetAccountId!,
        categoryId: defaultCategoryId,
        type: type,
        amount: amount,
        note: note.isEmpty ? 'Giao dịch tự động' : note,
        date: DateTime.now(), 
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint("❌ Lỗi bóc tách thông báo: $e");
      return null;
    }
  }
}