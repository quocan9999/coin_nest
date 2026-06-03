import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/ai_spending_insight_provider.dart';
import 'providers/backup_alert_provider.dart';
import 'providers/backup_provider.dart';
import 'providers/account_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/category_provider.dart';
import 'providers/financial_assistant_provider.dart';
import 'providers/loan_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/report_provider.dart';
import 'providers/settings_provider.dart';
import 'services/auth/firebase_auth_service.dart';
import 'services/notification/notification_record_service.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

//SQLite realtime viewer
import 'package:flutter/foundation.dart';
import 'package:saropa_drift_advisor/saropa_drift_advisor.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Khởi tạo Google Sign-In
  await GoogleSignIn.instance.initialize();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Init Vietnamese locale for dates
  await initializeDateFormatting('vi_VN', null);

  await NotificationRecordService.syncFromPreferences();

  final authService = FirebaseAuthService();

  // SQLite realtime viewer (chỉ chạy trong debug)
  debugPrint('--- Kiểm tra SQLite Viewer ---');
  debugPrint('kDebugMode: $kDebugMode');

  if (kDebugMode) {
    try {
      debugPrint('Đang chuẩn bị Database...');
      final db = await DatabaseHelper.instance.database;

      debugPrint('Đang khởi động DriftDebugServer...');
      await DriftDebugServer.start(query: (sql) => db.rawQuery(sql));
      debugPrint(
        '✅ SQLite Realtime Viewer đã khởi động tại: http://localhost:8642',
      );
    } catch (e, stack) {
      debugPrint('❌ Lỗi khởi động SQLite Viewer: $e');
      debugPrint(stack.toString());
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService),
        ),
        ChangeNotifierProvider(create: (_) => BackupAlertProvider()),
        ChangeNotifierProxyProvider<BackupAlertProvider, BackupProvider>(
          create: (_) => BackupProvider(),
          update: (_, backupAlertProvider, backupProvider) =>
              (backupProvider ?? BackupProvider())
                ..setBackupAlertProvider(backupAlertProvider),
        ),
        ChangeNotifierProxyProvider<BackupAlertProvider, AccountProvider>(
          create: (_) => AccountProvider(),
          update: (_, backupAlertProvider, accountProvider) =>
              (accountProvider ?? AccountProvider())
                ..setBackupAlertProvider(backupAlertProvider),
        ),
        ChangeNotifierProxyProvider<BackupAlertProvider, TransactionProvider>(
          create: (_) => TransactionProvider(),
          update: (_, backupAlertProvider, transactionProvider) =>
              (transactionProvider ?? TransactionProvider())
                ..setBackupAlertProvider(backupAlertProvider),
        ),
        ChangeNotifierProxyProvider<BackupAlertProvider, CategoryProvider>(
          create: (_) => CategoryProvider(),
          update: (_, backupAlertProvider, categoryProvider) =>
              (categoryProvider ?? CategoryProvider())
                ..setBackupAlertProvider(backupAlertProvider),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..loadSettings(),
        ),
        ChangeNotifierProxyProvider3<
          TransactionProvider,
          SettingsProvider,
          BackupAlertProvider,
          LoanProvider
        >(
          create: (_) => LoanProvider(),
          update:
              (
                _,
                transactionProvider,
                settingsProvider,
                backupAlertProvider,
                loanProvider,
              ) => (loanProvider ?? LoanProvider())
                ..setTransactionProvider(transactionProvider)
                ..setSettingsProvider(settingsProvider)
                ..setBackupAlertProvider(backupAlertProvider),
        ),
        ChangeNotifierProxyProvider<BackupAlertProvider, BudgetProvider>(
          create: (_) => BudgetProvider(),
          update: (_, backupAlertProvider, budgetProvider) =>
              (budgetProvider ?? BudgetProvider())
                ..setBackupAlertProvider(backupAlertProvider),
        ),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => AiSpendingInsightProvider()),
        ChangeNotifierProvider(create: (_) => FinancialAssistantProvider()),
      ],
      child: const CoinNestApp(),
    ),
  );
}
