import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'providers/settings_provider.dart';

/// Root widget — sets up theme, routes, and initial screen.
class CoinNestApp extends StatelessWidget {
  const CoinNestApp({super.key});

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
          darkTheme: ThemeData.dark(),

          // ================= MODE =================
          themeMode: settings.themeMode,

          home: const SplashScreen(),
        );
      },
    );
  }
}