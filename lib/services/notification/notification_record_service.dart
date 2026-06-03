import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/account_dao.dart';
import '../../database/category_dao.dart';
import '../../database/transaction_dao.dart';
import '../../providers/backup_alert_provider.dart';
import '../../utils/constants.dart';
import '../../utils/notification_parser.dart';

const String _notificationRecordPortName = 'CoinNestNotificationRecordPort';

@pragma('vm:entry-point')
void onNotificationRecordCallback(NotificationEvent event) {
  final sendPort = IsolateNameServer.lookupPortByName(
    _notificationRecordPortName,
  );
  if (sendPort != null) {
    sendPort.send(event);
    return;
  }

  unawaited(NotificationRecordService.handleBackgroundNotification(event));
}

class NotificationRecordService {
  NotificationRecordService._();

  static const int _signatureHistoryLimit = 50;

  static ReceivePort? _receivePort;
  static StreamSubscription<dynamic>? _receiveSubscription;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<bool> hasNotificationPermission() async {
    if (!isSupported) return false;
    return await NotificationsListener.hasPermission ?? false;
  }

  static Future<bool> syncFromPreferences({
    bool requestPermission = false,
  }) async {
    if (!isSupported) return false;

    final prefs = await SharedPreferences.getInstance();
    final isEnabled =
        prefs.getBool(AppConstants.prefAutoNotificationRecord) ?? false;
    final userId = prefs.getInt(AppConstants.prefLoggedInUserId);

    if (!isEnabled || userId == null || userId == 0) {
      stopListener();
      return false;
    }

    return startListener(requestPermission: requestPermission);
  }

  static Future<bool> startListener({bool requestPermission = false}) async {
    if (!isSupported) return false;

    try {
      var hasPermission = await NotificationsListener.hasPermission ?? false;
      if (!hasPermission) {
        if (requestPermission) {
          await NotificationsListener.openPermissionSettings();
        }
        hasPermission = await NotificationsListener.hasPermission ?? false;
      }
      if (!hasPermission) return false;

      await _registerReceivePort();
      await NotificationsListener.initialize(
        callbackHandle: onNotificationRecordCallback,
      );

      final isRunning = await NotificationsListener.isRunning ?? false;
      if (!isRunning) {
        return await NotificationsListener.startService() ?? false;
      }

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'Cannot start notification record listener: $error\n$stackTrace',
      );
      return false;
    }
  }

  static void stopListener() {
    IsolateNameServer.removePortNameMapping(_notificationRecordPortName);
    unawaited(_receiveSubscription?.cancel());
    _receiveSubscription = null;
    _receivePort?.close();
    _receivePort = null;
  }

  static Future<void> handleBackgroundNotification(
    NotificationEvent event,
  ) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();
    await _recordNotification(event);
  }

  static Future<void> _registerReceivePort() async {
    if (_receivePort != null) return;

    final receivePort = ReceivePort();
    IsolateNameServer.removePortNameMapping(_notificationRecordPortName);
    IsolateNameServer.registerPortWithName(
      receivePort.sendPort,
      _notificationRecordPortName,
    );

    _receivePort = receivePort;
    _receiveSubscription = receivePort.listen((message) {
      if (message is NotificationEvent) {
        unawaited(_recordNotification(message));
      }
    });
  }

  static Future<void> _recordNotification(NotificationEvent event) async {
    final notificationText = _extractNotificationText(event);
    if (notificationText.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final isEnabled =
        prefs.getBool(AppConstants.prefAutoNotificationRecord) ?? false;
    if (!isEnabled) return;

    final userId = prefs.getInt(AppConstants.prefLoggedInUserId);
    if (userId == null || userId == 0) return;

    final signature = _buildSignature(event);
    if (_hasSeenSignature(prefs, signature)) return;

    final accountDao = AccountDao();
    final categoryDao = CategoryDao();
    final transactionDao = TransactionDao();

    final accounts = await accountDao.getAllByUser(userId);
    final categories = await categoryDao.getAllByUser(userId);
    final draftTransaction = NotificationParser.parseNotification(
      notificationText: notificationText,
      accounts: accounts,
      expenseCategories: categories
          .where((category) => category.type == AppConstants.typeExpense)
          .toList(),
      incomeCategories: categories
          .where((category) => category.type == AppConstants.typeIncome)
          .toList(),
      savedExpenseAccountId: prefs.getInt(
        AppConstants.prefAutoExpenseAccountId,
      ),
      savedIncomeAccountId: prefs.getInt(AppConstants.prefAutoIncomeAccountId),
      userId: userId,
    );
    if (draftTransaction == null) return;

    final exists = await transactionDao.existsSimilarAutoRecord(
      draftTransaction,
    );
    if (exists) {
      await _rememberSignature(prefs, signature);
      return;
    }

    await transactionDao.insertWithBalance(draftTransaction);
    await BackupAlertProvider.markUserChanged(userId, source: 'transaction');
    await _rememberSignature(prefs, signature);
  }

  static String _extractNotificationText(NotificationEvent event) {
    final title = event.title?.trim() ?? '';
    final text = event.text?.trim() ?? '';

    if (_looksLikeBankMessage(text)) return text;
    if (_looksLikeBankMessage(title)) return title;

    return [title, text].where((part) => part.isNotEmpty).join(' | ');
  }

  static bool _looksLikeBankMessage(String text) {
    return text.contains('GD:') && text.contains('ND:');
  }

  static String _buildSignature(NotificationEvent event) {
    final raw = [
      event.packageName ?? '',
      event.title ?? '',
      event.text ?? '',
    ].join('|');
    return sha256.convert(utf8.encode(raw)).toString();
  }

  static bool _hasSeenSignature(SharedPreferences prefs, String signature) {
    final history =
        prefs.getStringList(
          AppConstants.prefAutoNotificationSignatureHistory,
        ) ??
        const <String>[];
    return history.contains(signature);
  }

  static Future<void> _rememberSignature(
    SharedPreferences prefs,
    String signature,
  ) async {
    final history =
        prefs.getStringList(
          AppConstants.prefAutoNotificationSignatureHistory,
        ) ??
        const <String>[];
    final updated = <String>[
      signature,
      ...history.where((item) => item != signature),
    ].take(_signatureHistoryLimit).toList();
    await prefs.setStringList(
      AppConstants.prefAutoNotificationSignatureHistory,
      updated,
    );
  }
}
