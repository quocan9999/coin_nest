import 'package:flutter/material.dart';
import 'services/navigation_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

/// Root widget — sets up theme, routes, and initial screen.
class CoinNestApp extends StatelessWidget {
  const CoinNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoinNest',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
