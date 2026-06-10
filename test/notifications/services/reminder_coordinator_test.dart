import 'package:coin_nest/models/loan.dart';
import 'package:coin_nest/services/notification/notification_service.dart';
import 'package:coin_nest/services/notification/reminder_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schedule nhắc ghi chép hằng ngày khi được bật', () async {
    final service = _FakeNotificationService();
    final coordinator = ReminderCoordinator(notificationService: service);

    final synced = await coordinator.syncReminders(
      dailyReminderEnabled: true,
      debtReminderEnabled: false,
      reminderTime: '20:15',
      loans: const [],
    );

    expect(synced, isTrue);
    expect(service.requestPermissionCount, 1);
    expect(service.scheduledIds, [NotificationService.dailyRecordReminderId]);
    expect(service.cancelledIds, [NotificationService.debtReminderId]);
  });

  test('schedule nhắc vay nợ khi còn khoản active chưa tất toán', () async {
    final service = _FakeNotificationService();
    final coordinator = ReminderCoordinator(notificationService: service);

    await coordinator.syncReminders(
      dailyReminderEnabled: false,
      debtReminderEnabled: true,
      reminderTime: '07:00',
      loans: [_loan(remainingAmount: 500)],
    );

    expect(service.scheduledIds, [NotificationService.debtReminderId]);
    expect(service.cancelledIds, [NotificationService.dailyRecordReminderId]);
  });

  test('không schedule nhắc vay nợ khi không còn khoản active', () async {
    final service = _FakeNotificationService();
    final coordinator = ReminderCoordinator(notificationService: service);

    await coordinator.syncReminders(
      dailyReminderEnabled: false,
      debtReminderEnabled: true,
      reminderTime: '07:00',
      loans: [_loan(remainingAmount: 0, status: 'paid')],
    );

    expect(service.requestPermissionCount, 0);
    expect(service.scheduledIds, isEmpty);
    expect(service.cancelledIds, [
      NotificationService.dailyRecordReminderId,
      NotificationService.debtReminderId,
    ]);
  });

  test('từ chối quyền thì hủy toàn bộ reminder', () async {
    final service = _FakeNotificationService(permissionGranted: false);
    final coordinator = ReminderCoordinator(notificationService: service);

    final synced = await coordinator.syncReminders(
      dailyReminderEnabled: true,
      debtReminderEnabled: true,
      reminderTime: '20:00',
      loans: [_loan(remainingAmount: 500)],
    );

    expect(synced, isFalse);
    expect(service.cancelAllCount, 1);
    expect(service.scheduledIds, isEmpty);
  });
}

Loan _loan({required double remainingAmount, String status = 'active'}) {
  final now = DateTime(2026, 6);
  return Loan(
    userId: 1,
    type: 'borrow',
    personName: 'Test',
    amount: 1000,
    remainingAmount: remainingAmount,
    startDate: now,
    status: status,
    accountId: 1,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService({this.permissionGranted = true});

  final bool permissionGranted;
  final scheduledIds = <int>[];
  final cancelledIds = <int>[];
  int requestPermissionCount = 0;
  int cancelAllCount = 0;

  @override
  Future<bool> requestPermission() async {
    requestPermissionCount++;
    return permissionGranted;
  }

  @override
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    scheduledIds.add(id);
  }

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelReminderNotifications() async {
    cancelAllCount++;
  }
}
