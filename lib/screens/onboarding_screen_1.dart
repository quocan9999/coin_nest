// lib/screens/onboarding_screen_1.dart

import 'package:flutter/material.dart';
import 'onboarding_screen_2.dart';
import 'login_screen.dart';

class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 60),

            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Bỏ qua",
                  style: TextStyle(
                    color: Color(0xFF0A7EA4),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const Spacer(),

            const Icon(
              Icons.account_balance_wallet,
              size: 90,
              color: Color(0xFF0A7EA4),
            ),

            const SizedBox(height: 30),

            const Text(
              "Quản lý tài chính dễ dàng",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Theo dõi thu chi, quản lý tài khoản và đặt mục tiêu tiết kiệm ngay trên điện thoại.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OnboardingScreen2(),
                    ),
                  );
                },
                child: const Text("Tiếp tục"),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}