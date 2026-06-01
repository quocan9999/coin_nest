import 'notification_service.dart';

class AppNotificationCoordinator {
  AppNotificationCoordinator({NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService();

  static const String _title = 'Quản lý chi tiêu CoinNest';
  static const String _body =
      'Hãy để CoinNest giúp bạn quản lý chi tiêu tốt hơn nhé';

  final NotificationService _notificationService;

  Future<bool> syncAutomaticNotifications() async {
    final granted = await _notificationService.requestPermission();
    if (!granted) return false;

    await Future.wait([
      _notificationService.scheduleDailyEngagementNotification(
        id: NotificationService.morningEngagementReminderId,
        title: _title,
        body: _body,
        hour: 8,
        minute: 0,
        payload: 'morning_engagement',
      ),
      _notificationService.scheduleDailyEngagementNotification(
        id: NotificationService.eveningEngagementReminderId,
        title: _title,
        body: _body,
        hour: 18,
        minute: 0,
        payload: 'evening_engagement',
      ),
    ]);

    return true;
  }
}
