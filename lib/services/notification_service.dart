import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../utils/constants.dart';
import '../utils/formatters.dart';

typedef NotificationPayloadHandler = FutureOr<void> Function(String payload);

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int dailyReminderSlotStartId = 1000;
  static const int dailyReminderSlotEndId = 1099;
  static const int dailyMorningReminderId = 1001;
  static const int dailyAfternoonReminderId = 1002;
  static const int loanReminderOffsetMin =
      AppConstants.minLoanReminderDayOffset;
  static const int loanReminderOffsetMax =
      AppConstants.maxLoanReminderDayOffset;
  static const String _channelId = 'coinnest_channel';
  static const String _channelName = 'CoinNest';
  static const String _timeZoneName = 'Asia/Ho_Chi_Minh';
  static const String _dailyReminderPayload = '{"type":"daily_reminder"}';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'vi_VN');

  bool _isInitialized = false;
  NotificationPayloadHandler? _onNotificationTap;
  String? _pendingPayload;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(_timeZoneName));

      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          unawaited(_handleNotificationPayload(response.payload));
        },
      );

      await _createAndroidChannel();
      await _requestAndroidPermission();

      final launchDetails = await _notifications
          .getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        await _handleNotificationPayload(
          launchDetails?.notificationResponse?.payload,
        );
      }

      _isInitialized = true;
    } catch (error, stackTrace) {
      debugPrint('NotificationService.init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void setNotificationTapHandler(NotificationPayloadHandler handler) {
    _onNotificationTap = handler;

    final payload = _pendingPayload;
    if (payload == null) return;

    _pendingPayload = null;
    unawaited(_handleNotificationPayload(payload));
  }

  Future<void> scheduleDailyReminder({
    required bool enabled,
    int morningHour = 8,
    int morningMinute = 0,
    int afternoonHour = 17,
    int afternoonMinute = 0,
  }) async {
    return scheduleDailyReminderSlots(enabled, <TimeOfDay>[
      TimeOfDay(hour: morningHour, minute: morningMinute),
      TimeOfDay(hour: afternoonHour, minute: afternoonMinute),
    ]);
  }

  Future<void> scheduleDailyReminderSlots(
    bool enabled,
    List<TimeOfDay> slots,
  ) async {
    try {
      await _ensureInitialized();
      await _cancelDailyReminderSlots();

      if (!enabled || slots.isEmpty) {
        return;
      }

      final sortedSlots = List<TimeOfDay>.from(slots)
        ..sort(_compareReminderSlots);
      for (var index = 0; index < sortedSlots.length; index += 1) {
        final slot = sortedSlots[index];
        await _scheduleDailyReminder(
          id: dailyReminderSlotStartId + index,
          hour: slot.hour,
          minute: slot.minute,
          title: ' CoinNest — Nhắc ghi chép',
          body: _dailyReminderBody(slot.hour),
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'NotificationService.scheduleDailyReminderSlots failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> scheduleLoanReminder({
    required int loanId,
    required String personName,
    required double remainingAmount,
    required DateTime dueDate,
    required bool isBorrowed,
    required List<int> daysOffsets,
  }) async {
    try {
      await _ensureInitialized();
      await cancelLoanReminders(loanId);

      final daysLeft = _calendarDaysUntil(dueDate);
      final now = tz.TZDateTime.now(tz.local);
      final normalizedOffsets = _normalizeLoanReminderOffsets(daysOffsets);

      for (final offset in normalizedOffsets) {
        if (daysLeft < offset) continue;

        final scheduledDate = _atLocalTime(
          dueDate.subtract(Duration(days: offset)),
          9,
        );
        if (!scheduledDate.isAfter(now)) continue;

        await _scheduleLoanReminder(
          loanId: loanId,
          offset: offset,
          personName: personName,
          remainingAmount: remainingAmount,
          dueDate: dueDate,
          isBorrowed: isBorrowed,
          scheduledDate: scheduledDate,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('NotificationService.scheduleLoanReminder failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> cancelLoanReminders(int loanId) async {
    try {
      await _ensureInitialized();

      for (
        var offset = loanReminderOffsetMin;
        offset <= loanReminderOffsetMax;
        offset += 1
      ) {
        await _notifications.cancel(_loanNotificationId(loanId, offset));
      }
    } catch (error, stackTrace) {
      debugPrint('NotificationService.cancelLoanReminders failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> cancelAllLoanReminders() async {
    try {
      await _ensureInitialized();

      final pendingNotifications = await _notifications
          .pendingNotificationRequests();
      for (final notification in pendingNotifications) {
        if (_isLoanNotificationId(notification.id)) {
          await _notifications.cancel(notification.id);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('NotificationService.cancelAllLoanReminders failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> cancelAll() async {
    try {
      await _ensureInitialized();
      await _notifications.cancelAll();
    } catch (error, stackTrace) {
      debugPrint('NotificationService.cancelAll failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.max,
    );

    final androidNotifications = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidNotifications?.createNotificationChannel(channel);
  }

  Future<void> _requestAndroidPermission() async {
    final androidNotifications = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidNotifications?.requestNotificationsPermission();
  }

  Future<void> _cancelDailyReminderSlots() async {
    for (
      var id = dailyReminderSlotStartId;
      id <= dailyReminderSlotEndId;
      id += 1
    ) {
      await _notifications.cancel(id);
    }
  }

  Future<void> _scheduleDailyReminder({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextDailyTime(hour, minute),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: _dailyReminderPayload,
    );
  }

  Future<void> _scheduleLoanReminder({
    required int loanId,
    required int offset,
    required String personName,
    required double remainingAmount,
    required DateTime dueDate,
    required bool isBorrowed,
    required tz.TZDateTime scheduledDate,
  }) async {
    final formattedAmount = Formatters.currencyVnd(remainingAmount);
    final formattedDueDate = _formatDate(dueDate);
    final title = _loanTitle(
      offset: offset,
      personName: personName,
      isBorrowed: isBorrowed,
    );
    final body = _loanBody(
      offset: offset,
      personName: personName,
      amount: formattedAmount,
      dueDate: formattedDueDate,
      isBorrowed: isBorrowed,
    );

    await _notifications.zonedSchedule(
      _loanNotificationId(loanId, offset),
      title,
      body,
      scheduledDate,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      payload: '{"type":"loan_due","loanId":$loanId}',
    );
  }

  Future<void> _handleNotificationPayload(String? payload) async {
    if (payload == null || payload.isEmpty) return;

    final handler = _onNotificationTap;
    if (handler == null) {
      _pendingPayload = payload;
      return;
    }

    try {
      await Future<void>.sync(() => handler(payload));
    } catch (error, stackTrace) {
      debugPrint('NotificationService payload handler failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  tz.TZDateTime _nextDailyTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  tz.TZDateTime _atLocalTime(DateTime date, int hour) {
    return tz.TZDateTime(tz.local, date.year, date.month, date.day, hour);
  }

  int _calendarDaysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  static int _loanNotificationId(int loanId, int offset) {
    return loanId * 100 + offset;
  }

  static bool _isLoanNotificationId(int id) {
    if (_isDailyReminderSlotId(id)) {
      return false;
    }

    if (id == dailyMorningReminderId || id == dailyAfternoonReminderId) {
      return false;
    }

    return id >= 100;
  }

  static bool _isDailyReminderSlotId(int id) {
    return id >= dailyReminderSlotStartId && id <= dailyReminderSlotEndId;
  }

  static int _compareReminderSlots(TimeOfDay a, TimeOfDay b) {
    final aMinutes = a.hour * TimeOfDay.minutesPerHour + a.minute;
    final bMinutes = b.hour * TimeOfDay.minutesPerHour + b.minute;
    return aMinutes.compareTo(bMinutes);
  }

  String _dailyReminderBody(int hour) {
    if (hour < 12) {
      return 'Buổi sáng tốt lành! Đừng quên ghi lại các khoản chi tiêu hôm nay nhé.';
    }

    if (hour < 18) {
      return 'Buổi chiều rồi! Ghi lại chi tiêu hôm nay để theo dõi tài chính tốt hơn.';
    }

    return 'Cuối ngày rồi! Đừng quên ghi lại chi tiêu hôm nay nhé.';
  }

  String _loanTitle({
    required int offset,
    required String personName,
    required bool isBorrowed,
  }) {
    if (isBorrowed) {
      return offset == 0
          ? ' Đến hạn trả nợ hôm nay — $personName'
          : '⏰ Sắp đến hạn trả nợ — $personName';
    }

    return offset == 0
        ? ' Đến hạn đòi nợ hôm nay — $personName'
        : ' Nhắc đòi nợ — $personName';
  }

  String _loanBody({
    required int offset,
    required String personName,
    required String amount,
    required String dueDate,
    required bool isBorrowed,
  }) {
    if (isBorrowed) {
      return offset == 0
          ? 'Hôm nay là hạn chót trả $amount cho $personName. Vui lòng thanh toán!'
          : 'Còn $offset ngày nữa đến hạn trả $amount cho $personName ($dueDate)';
    }

    return offset == 0
        ? 'Hôm nay là hạn thu $amount từ $personName.'
        : 'Còn $offset ngày nữa đến hạn thu $amount từ $personName ($dueDate)';
  }

  String _formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  List<int> _normalizeLoanReminderOffsets(List<int> offsets) {
    final normalized = offsets
        .where(
          (offset) =>
              offset >= loanReminderOffsetMin &&
              offset <= loanReminderOffsetMax,
        )
        .toSet()
        .toList();
    normalized.sort((a, b) => b.compareTo(a));
    return normalized;
  }

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.max,
      priority: Priority.high,
    ),
  );
}
