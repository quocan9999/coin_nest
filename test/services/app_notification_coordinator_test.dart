import 'package:coin_nest/services/notification/app_notification_coordinator.dart';
import 'package:coin_nest/services/notification/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schedule thông báo tự động lúc 8 giờ và 18 giờ hằng ngày', () async {
    final service = _FakeNotificationService();
    final coordinator = AppNotificationCoordinator(
      notificationService: service,
    );

    final synced = await coordinator.syncAutomaticNotifications();

    expect(synced, isTrue);
    expect(service.requestPermissionCount, 1);
    expect(service.scheduled, [
      _ScheduledNotification(
        id: NotificationService.morningEngagementReminderId,
        title: 'Quản lý chi tiêu CoinNest',
        body: 'Hãy để CoinNest giúp bạn quản lý chi tiêu tốt hơn nhé',
        hour: 8,
        minute: 0,
        payload: 'morning_engagement',
      ),
      _ScheduledNotification(
        id: NotificationService.eveningEngagementReminderId,
        title: 'Quản lý chi tiêu CoinNest',
        body: 'Hãy để CoinNest giúp bạn quản lý chi tiêu tốt hơn nhé',
        hour: 18,
        minute: 0,
        payload: 'evening_engagement',
      ),
    ]);
  });

  test('không schedule thông báo tự động khi bị từ chối quyền', () async {
    final service = _FakeNotificationService(permissionGranted: false);
    final coordinator = AppNotificationCoordinator(
      notificationService: service,
    );

    final synced = await coordinator.syncAutomaticNotifications();

    expect(synced, isFalse);
    expect(service.requestPermissionCount, 1);
    expect(service.scheduled, isEmpty);
  });
}

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService({this.permissionGranted = true});

  final bool permissionGranted;
  final scheduled = <_ScheduledNotification>[];
  int requestPermissionCount = 0;

  @override
  Future<bool> requestPermission() async {
    requestPermissionCount++;
    return permissionGranted;
  }

  @override
  Future<void> scheduleDailyEngagementNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    scheduled.add(
      _ScheduledNotification(
        id: id,
        title: title,
        body: body,
        hour: hour,
        minute: minute,
        payload: payload,
      ),
    );
  }
}

class _ScheduledNotification {
  const _ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final String? payload;

  @override
  bool operator ==(Object other) {
    return other is _ScheduledNotification &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.hour == hour &&
        other.minute == minute &&
        other.payload == payload;
  }

  @override
  int get hashCode => Object.hash(id, title, body, hour, minute, payload);
}
