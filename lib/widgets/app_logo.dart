// lib/widgets/app_logo.dart

import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Icon(
          Icons.account_balance_wallet,
          size: 60,
          color: Color(0xFF0A7EA4),
        ),
        SizedBox(height: 10),
        Text(
          "CoinNest",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A7EA4),
          ),
        ),
      ],
    );
  }
}