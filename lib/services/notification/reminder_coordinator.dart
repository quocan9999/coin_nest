import '../../models/loan.dart';
import 'notification_service.dart';

class ReminderCoordinator {
  ReminderCoordinator({NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService();

  final NotificationService _notificationService;

  Future<bool> syncReminders({
    required bool dailyReminderEnabled,
    required bool debtReminderEnabled,
    required String reminderTime,
    required Iterable<Loan> loans,
  }) async {
    final parsedTime = _ReminderTime.tryParse(reminderTime);
    if (parsedTime == null) return false;

    final shouldSchedule =
        dailyReminderEnabled ||
        (debtReminderEnabled && _hasActiveDebtReminder(loans));
    final granted = shouldSchedule
        ? await _notificationService.requestPermission()
        : true;
    if (!granted) {
      await _notificationService.cancelReminderNotifications();
      return false;
    }

    if (dailyReminderEnabled) {
      await _notificationService.scheduleDailyReminder(
        id: NotificationService.dailyRecordReminderId,
        title: 'Ghi chép hôm nay',
        body: 'Mở CoinNest để cập nhật thu chi trong ngày.',
        hour: parsedTime.hour,
        minute: parsedTime.minute,
        payload: 'daily_record',
      );
    } else {
      await _notificationService.cancel(
        NotificationService.dailyRecordReminderId,
      );
    }

    if (debtReminderEnabled && _hasActiveDebtReminder(loans)) {
      await _notificationService.scheduleDailyReminder(
        id: NotificationService.debtReminderId,
        title: 'Theo dõi vay và cho vay',
        body: 'Bạn còn khoản vay/cho vay đang hoạt động cần kiểm tra.',
        hour: parsedTime.hour,
        minute: parsedTime.minute,
        payload: 'debt_reminder',
      );
    } else {
      await _notificationService.cancel(NotificationService.debtReminderId);
    }

    return true;
  }

  bool _hasActiveDebtReminder(Iterable<Loan> loans) {
    return loans.any(
      (loan) => loan.status == 'active' && loan.remainingAmount > 0,
    );
  }
}

class _ReminderTime {
  const _ReminderTime({required this.hour, required this.minute});

  final int hour;
  final int minute;

  static _ReminderTime? tryParse(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return _ReminderTime(hour: hour, minute: minute);
  }
}
