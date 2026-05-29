import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/account_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/category_provider.dart';
import 'providers/loan_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/report_provider.dart';
import 'providers/settings_provider.dart';
import 'services/auth/firebase_auth_service.dart';

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
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProxyProvider<TransactionProvider, LoanProvider>(
          create: (_) => LoanProvider(),
          update: (_, transactionProvider, loanProvider) =>
              (loanProvider ?? LoanProvider())
                ..setTransactionProvider(transactionProvider),
        ),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..loadSettings(),
        ),
      ],
      child: const CoinNestApp(),
    ),
  );
}
