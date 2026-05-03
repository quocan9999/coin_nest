// lib/app.dart

import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

class CoinNestApp extends StatelessWidget {
  const CoinNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CoinNest',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Arial',
      ),
      home: const SplashScreen(),
    );
  }
}