import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/notification_parser.dart';
// Thay đổi các import DAO này cho đúng với cấu trúc thư mục của bạn
import '../database/account_dao.dart';
import '../database/category_dao.dart';
import '../database/transaction_dao.dart';

const String _portName = "CoinNestNotificationPort";

/// BẮT BUỘC: Hàm callback chạy ngầm phải nằm NGOÀI Class (Top-level function)
/// và có gắn @pragma('vm:entry-point') để tránh bị trình biên dịch loại bỏ khi đóng gói.
@pragma('vm:entry-point')
void onNotificationCallback(NotificationEvent evt) {
  final SendPort? send = IsolateNameServer.lookupPortByName(_portName);
  if (send != null) {
    send.send(evt);
  } else {
    // App bị đóng hoàn toàn, tự xử lý ghi DB trực tiếp ở luồng ngầm
    NotificationService.handleNotificationDirectly(evt);
  }
}

class NotificationService {
  static ReceivePort? port;

  static Future<void> initListener() async {
    debugPrint("🚀 Đang khởi tạo NotificationService (v1.3.4)...");
    try {
      bool hasPermission = await NotificationsListener.hasPermission ?? false;
      if (!hasPermission) {
        debugPrint("⚠️ Chưa có quyền đọc thông báo, yêu cầu người dùng cấp quyền.");
        await NotificationsListener.openPermissionSettings();
        return;
      }

      // Tạo cổng nhận tin nhắn từ Isolate chạy ngầm gửi về UI Isolate
      port = ReceivePort();
      IsolateNameServer.removePortNameMapping(_portName);
      IsolateNameServer.registerPortWithName(port!.sendPort, _portName);

      // Lắng nghe dữ liệu đổ về luồng chính
      port!.listen((message) {
        if (message is NotificationEvent) {
          _handleNotification(message);
        }
      });

      // Truyền hàm callback top-level vào đây
      await NotificationsListener.initialize(callbackHandle: onNotificationCallback);

      // Khởi chạy service nếu chưa chạy
      final isRunning = await NotificationsListener.isRunning ?? false;
      debugPrint("ℹ️ Trạng thái Service: isRunning = $isRunning");
      if (!isRunning) {
        final started = await NotificationsListener.startService();
        debugPrint("🚀 Đã gọi startService(). Kết quả = $started");
      }

      debugPrint("✅ Đã khởi động Notification Listener thành công!");
    } catch (e) {
      debugPrint("❌ Lỗi khởi tạo Listener: $e");
    }
  }

  // Hàm xử lý logic lưu Database trên luồng chính
  static Future<void> _handleNotification(NotificationEvent evt) async {
    final notificationText = evt.text ?? evt.title ?? '';
    if (notificationText.isEmpty) {
      debugPrint("⚠️ Nhận thông báo nhưng nội dung trống.");
      return;
    }
    
    debugPrint("📥 Nhận thông báo mới từ: ${evt.packageName}");
    debugPrint("💬 Nội dung thông báo: \"$notificationText\"");
    
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('auto_notification_enabled') ?? false;
    debugPrint("⚙️ Trạng thái ghi chép tự động (auto_notification_enabled): $isEnabled");
    if (!isEnabled) {
      debugPrint("ℹ️ Chức năng tự động ghi chép đang tắt. Bỏ qua thông báo.");
      return;
    }

    final expenseId = prefs.getInt('auto_expense_account_id');
    final incomeId = prefs.getInt('auto_income_account_id');
    // Thay đổi key 'current_user_id' thành 'logged_in_user_id' để đồng bộ với AuthProvider
    final int currentUserId = prefs.getInt('logged_in_user_id') ?? 1;
    
    debugPrint("👤 User ID hiện tại: $currentUserId");
    debugPrint("💳 Tài khoản chi mặc định: $expenseId, Tài khoản thu mặc định: $incomeId");

    try {
      final accountDao = AccountDao();
      final categoryDao = CategoryDao();
      final transactionDao = TransactionDao();

      final accounts = await accountDao.getAllByUser(currentUserId);
      final categories = await categoryDao.getAllByUser(currentUserId);
      
      debugPrint("📚 Đã tải ${accounts.length} tài khoản và ${categories.length} hạng mục của User $currentUserId.");
      
      final expenseCategories = categories.where((c) => c.type == 'expense').toList();
      final incomeCategories = categories.where((c) => c.type == 'income').toList();

      final draftTransaction = NotificationParser.parseNotification(
        notificationText: notificationText,
        accounts: accounts,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
        savedExpenseAccountId: expenseId,
        savedIncomeAccountId: incomeId,
        userId: currentUserId,
      );

      if (draftTransaction != null) {
        final insertedId = await transactionDao.insertWithBalance(draftTransaction); 
        debugPrint("🎉 Đã ghi chép tự động thành công giao dịch ID $insertedId với số tiền: ${draftTransaction.amount}");
      } else {
        debugPrint("⚠️ Không thể tạo giao dịch nháp (NotificationParser trả về null).");
      }
    } catch (e) {
      debugPrint("❌ Lỗi khi bóc tách và lưu thông báo vào DB: $e");
    }
  }

  static void stopListener() {
    IsolateNameServer.removePortNameMapping(_portName);
    port?.close();
  }

  // Hàm xử lý trực tiếp khi app bị đóng (chạy trong Isolate ngầm)
  static Future<void> handleNotificationDirectly(NotificationEvent evt) async {
    final notificationText = evt.text ?? evt.title ?? '';
    if (notificationText.isEmpty) return;

    try {
      WidgetsFlutterBinding.ensureInitialized();
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('auto_notification_enabled') ?? false;
      if (!isEnabled) return;

      final expenseId = prefs.getInt('auto_expense_account_id');
      final incomeId = prefs.getInt('auto_income_account_id');
      final int currentUserId = prefs.getInt('logged_in_user_id') ?? 1;

      final accountDao = AccountDao();
      final categoryDao = CategoryDao();
      final transactionDao = TransactionDao();

      final accounts = await accountDao.getAllByUser(currentUserId);
      final categories = await categoryDao.getAllByUser(currentUserId);
      
      final expenseCategories = categories.where((c) => c.type == 'expense').toList();
      final incomeCategories = categories.where((c) => c.type == 'income').toList();

      final draftTransaction = NotificationParser.parseNotification(
        notificationText: notificationText,
        accounts: accounts,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
        savedExpenseAccountId: expenseId,
        savedIncomeAccountId: incomeId,
        userId: currentUserId,
      );

      if (draftTransaction != null) {
        final insertedId = await transactionDao.insertWithBalance(draftTransaction);
        debugPrint("🎉 [Background] Tự động tạo giao dịch ID $insertedId thành công khi app đóng.");
      }
    } catch (e) {
      debugPrint("❌ [Background] Lỗi lưu DB khi app đóng: $e");
    }
  }
}