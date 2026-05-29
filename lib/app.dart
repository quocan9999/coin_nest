import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

/// Root widget — sets up theme, routes, and initial screen.
class CoinNestApp extends StatelessWidget {
  const CoinNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'CoinNest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: const SplashScreen(),
    );
  }
}
