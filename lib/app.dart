import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'providers/settings_provider.dart';
import 'services/notification/app_notification_coordinator.dart';

/// Root widget — sets up theme, routes, and initial screen.
class CoinNestApp extends StatefulWidget {
  const CoinNestApp({super.key});

  @override
  State<CoinNestApp> createState() => _CoinNestAppState();
}

class _CoinNestAppState extends State<CoinNestApp> {
  final AppNotificationCoordinator _appNotificationCoordinator =
      AppNotificationCoordinator();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_appNotificationCoordinator.syncAutomaticNotifications());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'CoinNest',

          debugShowCheckedModeBanner: false,

          // ================= LIGHT =================
          theme: AppTheme.lightTheme,

          // ================= DARK =================
          darkTheme: AppTheme.darkTheme,

          // ================= MODE =================
          themeMode: settings.themeMode,

          home: const SplashScreen(),
        );
      },
    );
  }
}
