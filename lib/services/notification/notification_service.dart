import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? notifications})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  static const int dailyRecordReminderId = 1001;
  static const int debtReminderId = 1002;
  static const int morningEngagementReminderId = 2001;
  static const int eveningEngagementReminderId = 2002;
  static const String reminderChannelId = 'coinnest_reminders';
  static const String reminderChannelName = 'Nhắc nhở CoinNest';
  static const String reminderChannelDescription =
      'Nhắc ghi chép tài chính và theo dõi vay/cho vay hằng ngày';

  static const String engagementChannelId = 'coinnest_engagement';
  static const String engagementChannelName = 'Gợi ý CoinNest';
  static const String engagementChannelDescription =
      'Gợi ý quản lý chi tiêu từ CoinNest';

  static const Map<String, String> _timezoneAliases = {
    'Asia/Saigon': 'Asia/Ho_Chi_Minh',
  };

  final FlutterLocalNotificationsPlugin _notifications;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );
    _isInitialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (!_supportsScheduling) return false;

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      final notificationsGranted =
          await androidPlugin.requestNotificationsPermission() ?? true;
      if (!notificationsGranted) return false;

      final canScheduleExact =
          await androidPlugin.canScheduleExactNotifications() ?? true;
      if (canScheduleExact) return true;

      return await androidPlugin.requestExactAlarmsPermission() ?? false;
    }

    final iosGranted = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    if (iosGranted != null) return iosGranted;

    final macosGranted = await _notifications
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return macosGranted ?? true;
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await _scheduleDailyNotification(
      id: id,
      title: title,
      body: body,
      hour: hour,
      minute: minute,
      androidChannelId: reminderChannelId,
      androidChannelName: reminderChannelName,
      androidChannelDescription: reminderChannelDescription,
      payload: payload,
    );
  }

  Future<void> scheduleDailyEngagementNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    await _scheduleDailyNotification(
      id: id,
      title: title,
      body: body,
      hour: hour,
      minute: minute,
      androidChannelId: engagementChannelId,
      androidChannelName: engagementChannelName,
      androidChannelDescription: engagementChannelDescription,
      payload: payload,
    );
  }

  Future<void> cancel(int id) async {
    await initialize();
    if (kIsWeb) return;
    await _notifications.cancel(id: id);
  }

  Future<void> cancelReminderNotifications() async {
    await Future.wait([cancel(dailyRecordReminderId), cancel(debtReminderId)]);
  }

  Future<void> _configureLocalTimezone() async {
    if (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows) {
      return;
    }

    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      final timezoneIdentifier = _normalizeTimezoneIdentifier(
        timezone.identifier,
      );
      tz.setLocalLocation(tz.getLocation(timezoneIdentifier));
    } on MissingPluginException catch (error, stackTrace) {
      debugPrint('Không thể lấy timezone cục bộ: $error\n$stackTrace');
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Không thể cấu hình timezone cục bộ: $error\n$stackTrace');
    } catch (error, stackTrace) {
      debugPrint('Timezone cục bộ không hợp lệ: $error\n$stackTrace');
    }
  }

  String _normalizeTimezoneIdentifier(String identifier) {
    return _timezoneAliases[identifier] ?? identifier;
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String androidChannelId,
    required String androidChannelName,
    required String androidChannelDescription,
    String? payload,
  }) async {
    await initialize();
    if (!_supportsScheduling) return;

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextTime(hour: hour, minute: minute),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          androidChannelName,
          channelDescription: androidChannelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  tz.TZDateTime _nextTime({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  bool get _supportsScheduling =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
}
