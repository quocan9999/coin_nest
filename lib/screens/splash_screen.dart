// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'onboarding_screen_1.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const OnboardingScreen1(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.account_balance_wallet,
              size: 70,
              color: Color(0xFF0A7EA4),
            ),
            SizedBox(height: 20),
            Text(
              'CoinNest',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A7EA4),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'THE FINANCIAL ARCHITECT',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}