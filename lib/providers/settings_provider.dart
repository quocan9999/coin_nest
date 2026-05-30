import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/loan_dao.dart';
import '../services/loan_notification_scheduler.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

/// Manages app-level settings (theme, currency, notifications).
class SettingsProvider extends ChangeNotifier {
  static const List<TimeOfDay> _defaultReminderTimeSlots = <TimeOfDay>[
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 17, minute: 0),
  ];
  static const List<int> _defaultLoanReminderDays =
      AppConstants.defaultLoanReminderDays;

  bool _showBalance = true;
  bool _dailyReminder = false;
  bool _dailyReminderEnabled = false;
  List<TimeOfDay> _reminderTimeSlots = List<TimeOfDay>.from(
    _defaultReminderTimeSlots,
  );
  int _reminderMorningHour = 8;
  int _reminderMorningMinute = 0;
  int _reminderAfternoonHour = 17;
  int _reminderAfternoonMinute = 0;
  bool _loanReminderEnabled = true;
  List<int> _loanReminderDays = List<int>.from(_defaultLoanReminderDays);
  String _currency = 'VND';

  bool get showBalance => _showBalance;
  bool get dailyReminder => _dailyReminder;
  bool get dailyReminderEnabled => _dailyReminderEnabled;

  List<TimeOfDay> get reminderTimeSlots =>
      List<TimeOfDay>.unmodifiable(_reminderTimeSlots);

  @Deprecated('Use reminderTimeSlots instead.')
  int get reminderMorningHour => _reminderMorningHour;

  @Deprecated('Use reminderTimeSlots instead.')
  int get reminderMorningMinute => _reminderMorningMinute;

  @Deprecated('Use reminderTimeSlots instead.')
  int get reminderAfternoonHour => _reminderAfternoonHour;

  @Deprecated('Use reminderTimeSlots instead.')
  int get reminderAfternoonMinute => _reminderAfternoonMinute;

  bool get loanReminderEnabled => _loanReminderEnabled;

  List<int> get loanReminderDays => List<int>.unmodifiable(_loanReminderDays);

  String get currency => _currency;

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showBalance = prefs.getBool(AppConstants.prefShowBalance) ?? true;
      _dailyReminder = prefs.getBool(AppConstants.prefDailyReminder) ?? false;
      _dailyReminderEnabled =
          prefs.getBool(AppConstants.prefDailyReminderEnabled) ??
          _dailyReminder;
      _dailyReminder = _dailyReminderEnabled;
      _reminderTimeSlots = _parseReminderTimeSlots(
        prefs.getString(AppConstants.prefReminderTimeSlots),
      );
      _syncLegacyReminderFieldsFromSlots();
      _loanReminderEnabled =
          prefs.getBool(AppConstants.prefLoanReminderEnabled) ?? true;
      _loanReminderDays = _parseLoanReminderDays(
        prefs.getString(AppConstants.prefLoanReminderDays),
      );
      _currency =
          prefs.getString(AppConstants.prefCurrency) ??
          AppConstants.defaultCurrency;
    } catch (error, stackTrace) {
      debugPrint('SettingsProvider.loadSettings failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    notifyListeners();
  }

  Future<void> setShowBalance(bool value) async {
    try {
      _showBalance = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefShowBalance, value);
    } catch (error, stackTrace) {
      debugPrint('SettingsProvider.setShowBalance failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      notifyListeners();
    }
  }

  Future<void> setDailyReminder(
    bool enabled, {
    int morningHour = 8,
    int morningMinute = 0,
    int afternoonHour = 17,
    int afternoonMinute = 0,
  }) async {
    try {
      _dailyReminder = enabled;
      _dailyReminderEnabled = enabled;
      _syncLegacyReminderFieldsFromSlots();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefDailyReminder, enabled);
      await prefs.setBool(AppConstants.prefDailyReminderEnabled, enabled);
      await _saveReminderTimeSlots(prefs);

      await NotificationService.instance.scheduleDailyReminderSlots(
        enabled,
        _reminderTimeSlots,
      );
    } catch (error, stackTrace) {
      debugPrint('SettingsProvider.setDailyReminder failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      notifyListeners();
    }
  }

  Future<void> addReminderSlot(TimeOfDay time) async {
    try {
      if (_containsReminderSlot(time)) return;

      _reminderTimeSlots = <TimeOfDay>[..._reminderTimeSlots, time];
      _sortReminderTimeSlots();
      _syncLegacyReminderFieldsFromSlots();

      final prefs = await SharedPreferences.getInstance();
      await _saveReminderTimeSlots(prefs);

      if (_dailyReminderEnabled) {
        await NotificationService.instance.scheduleDailyReminderSlots(
          true,
          _reminderTimeSlots,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('SettingsProvider.addReminderSlot failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      notifyListeners();
    }
  }

  Future<void> removeReminderSlot(TimeOfDay time) async {
    try {
      _reminderTimeSlots = _reminderTimeSlots
          .where((slot) => slot.hour != time.hour || slot.minute != time.minute)
          .toList();
      _sortReminderTimeSlots();
      _syncLegacyReminderFieldsFromSlots();

      final prefs = await SharedPreferences.getInstance();
      await _saveReminderTimeSlots(prefs);

      await NotificationService.instance.scheduleDailyReminderSlots(
        _dailyReminderEnabled,
        _reminderTimeSlots,
      );
    } catch (error, stackTrace) {
      debugPrint('SettingsProvider.removeReminderSlot failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      notifyListeners();
    }
  }

  Future<void> setLoanReminder(bool enabled) async {
    try {
      _loanReminderEnabled = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefLoanReminderEnabled, enabled);

      if (!enabled) {
        await NotificationService.instance.cancelAllLoanReminders();
      } else {
        await _rescheduleLoansForCurrentUser();
      }
    } catch (error, stackTrace) {
      debugPrint('SettingsProvider.setLoanReminder failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      notifyListeners();
    }
  }

  Future<void> addLoanReminderDay(int days) async {
    try {
      _validateLoanReminderDay(days);
      if (_loanReminderDays.contains(days)) return;

      _loanReminderDays = <int>[..._loanReminderDays, days];
      _sortLoanReminderDays();

      final prefs = await SharedPreferences.getInstance();
      await _saveLoanReminderDays(prefs);
      await _rescheduleLoansForCurrentUser();
    } catch (error, stackTrace) {
      debugPrint('SettingsProvider.addLoanReminderDay failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      notifyListeners();
    }
  }

  Future<void> removeLoanReminderDay(int days) async {
    try {
      _loanReminderDays = _loanReminderDays
          .where((item) => item != days)
          .toList();
      _sortLoanReminderDays();

      final prefs = await SharedPreferences.getInstance();
      await _saveLoanReminderDays(prefs);
      await _rescheduleLoansForCurrentUser();
    } catch (error, stackTrace) {
      debugPrint('SettingsProvider.removeLoanReminderDay failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      notifyListeners();
    }
  }

  Future<void> setCurrency(String value) async {
    try {
      _currency = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefCurrency, value);
    } catch (error, stackTrace) {
      debugPrint('SettingsProvider.setCurrency failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      notifyListeners();
    }
  }

  List<TimeOfDay> _parseReminderTimeSlots(String? rawSlots) {
    if (rawSlots == null) {
      return List<TimeOfDay>.from(_defaultReminderTimeSlots);
    }

    try {
      final decoded = jsonDecode(rawSlots);
      if (decoded is! List) {
        return List<TimeOfDay>.from(_defaultReminderTimeSlots);
      }

      final slots = decoded
          .whereType<String>()
          .map(_parseReminderTimeSlot)
          .whereType<TimeOfDay>()
          .toList();
      return _normalizeReminderTimeSlots(slots);
    } catch (error, stackTrace) {
      debugPrint('SettingsProvider._parseReminderTimeSlots failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return List<TimeOfDay>.from(_defaultReminderTimeSlots);
    }
  }

  List<int> _parseLoanReminderDays(String? rawDays) {
    if (rawDays == null) {
      return List<int>.from(_defaultLoanReminderDays);
    }

    try {
      final decoded = jsonDecode(rawDays);
      if (decoded is! List) {
        return List<int>.from(_defaultLoanReminderDays);
      }

      final days = decoded
          .whereType<num>()
          .map((value) => value.toInt())
          .where(_isValidLoanReminderDay)
          .toList();
      return _normalizeLoanReminderDays(days);
    } catch (error, stackTrace) {
      debugPrint('SettingsProvider._parseLoanReminderDays failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return List<int>.from(_defaultLoanReminderDays);
    }
  }

  TimeOfDay? _parseReminderTimeSlot(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _saveReminderTimeSlots(SharedPreferences prefs) {
    final slots = _reminderTimeSlots.map(_formatReminderTimeSlot).toList();
    return prefs.setString(
      AppConstants.prefReminderTimeSlots,
      jsonEncode(slots),
    );
  }

  Future<void> _saveLoanReminderDays(SharedPreferences prefs) {
    return prefs.setString(
      AppConstants.prefLoanReminderDays,
      jsonEncode(_loanReminderDays),
    );
  }

  String _formatReminderTimeSlot(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<TimeOfDay> _normalizeReminderTimeSlots(List<TimeOfDay> slots) {
    final uniqueSlots = <TimeOfDay>[];
    for (final slot in slots) {
      final exists = uniqueSlots.any(
        (item) => item.hour == slot.hour && item.minute == slot.minute,
      );
      if (!exists) {
        uniqueSlots.add(slot);
      }
    }

    uniqueSlots.sort(_compareReminderTimeSlots);
    return uniqueSlots;
  }

  List<int> _normalizeLoanReminderDays(List<int> days) {
    final uniqueDays = days.toSet().toList();
    uniqueDays.sort((a, b) => b.compareTo(a));
    return uniqueDays;
  }

  void _sortReminderTimeSlots() {
    _reminderTimeSlots = _normalizeReminderTimeSlots(_reminderTimeSlots);
  }

  void _sortLoanReminderDays() {
    _loanReminderDays = _normalizeLoanReminderDays(_loanReminderDays);
  }

  bool _containsReminderSlot(TimeOfDay time) {
    return _reminderTimeSlots.any(
      (slot) => slot.hour == time.hour && slot.minute == time.minute,
    );
  }

  int _compareReminderTimeSlots(TimeOfDay a, TimeOfDay b) {
    final aMinutes = a.hour * TimeOfDay.minutesPerHour + a.minute;
    final bMinutes = b.hour * TimeOfDay.minutesPerHour + b.minute;
    return aMinutes.compareTo(bMinutes);
  }

  bool _isValidLoanReminderDay(int days) {
    return days >= AppConstants.minLoanReminderDayOffset &&
        days <= AppConstants.maxLoanReminderDayOffset;
  }

  void _validateLoanReminderDay(int days) {
    if (!_isValidLoanReminderDay(days)) {
      throw ArgumentError(
        'Loan reminder day must be between '
        '${AppConstants.minLoanReminderDayOffset} and '
        '${AppConstants.maxLoanReminderDayOffset}',
      );
    }
  }

  Future<void> _rescheduleLoansForCurrentUser() async {
    if (!_loanReminderEnabled || _loanReminderDays.isEmpty) {
      await NotificationService.instance.cancelAllLoanReminders();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(AppConstants.prefLoggedInUserId);
    if (userId == null) return;

    final loans = await LoanDao().getAllByUser(userId);
    await LoanNotificationScheduler.rescheduleAll(loans, _loanReminderDays);
  }

  void _syncLegacyReminderFieldsFromSlots() {
    final slots = _reminderTimeSlots;
    final morning = slots.isNotEmpty
        ? slots.first
        : _defaultReminderTimeSlots[0];
    final afternoon = slots.length > 1
        ? slots[1]
        : _defaultReminderTimeSlots[1];

    _reminderMorningHour = morning.hour;
    _reminderMorningMinute = morning.minute;
    _reminderAfternoonHour = afternoon.hour;
    _reminderAfternoonMinute = afternoon.minute;
  }
}
