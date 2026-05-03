// lib/screens/onboarding_screen_2.dart

import 'package:flutter/material.dart';
import 'onboarding_screen_3.dart';
import 'login_screen.dart';

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

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
              Icons.pie_chart,
              size: 90,
              color: Color(0xFF0A7EA4),
            ),

            const SizedBox(height: 30),

            const Text(
              "Báo cáo chi tiết",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Biểu đồ trực quan giúp bạn hiểu rõ thói quen chi tiêu và tối ưu hóa ngân sách.",
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
                      builder: (context) => const OnboardingScreen3(),
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