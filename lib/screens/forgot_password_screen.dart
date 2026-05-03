// Thêm vào forgot_password_screen.dart
// Ràng buộc:
// - Nhập email đúng Gmail
// - Nhấn gửi mã xác nhận
// - Sinh mã OTP giả lập
// - Người dùng phải nhập đúng mã mới được sang reset password

import 'dart:math';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController otpController =
      TextEditingController();

  String generatedOTP = "";
  bool showOTPField = false;

  bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@gmail\.com$',
    ).hasMatch(email.trim());
  }

  String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  void sendCode() {
    if (_formKey.currentState!.validate()) {
      generatedOTP = generateOTP();

      setState(() {
        showOTPField = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Mã xác nhận: $generatedOTP",
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void verifyOTP() {
    if (otpController.text.trim() == generatedOTP) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Xác thực thành công"),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              email: emailController.text.trim(),
            ),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mã xác nhận không đúng"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 10),

                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                      ),
                    ),
                    const Text(
                      "CoinNest",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A7EA4),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                const Icon(
                  Icons.lock_reset,
                  size: 60,
                  color: Color(0xFF29A9E1),
                ),

                const SizedBox(height: 28),

                const Text(
                  "Quên mật khẩu?",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  "Nhập email của bạn để nhận hướng dẫn\nkhôi phục mật khẩu.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 34),

                TextFormField(
                  controller: emailController,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Vui lòng nhập email";
                    }

                    if (!isValidEmail(value.trim())) {
                      return "Email phải đúng định dạng Gmail";
                    }

                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "username@gmail.com",
                    filled: true,
                    fillColor: const Color(0xFFF3F3F3),
                    suffixIcon: const Icon(
                      Icons.mail_outline,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (!showOTPField)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: sendCode,
                      child: const Text(
                        "Gửi mã xác nhận",
                      ),
                    ),
                  ),

                if (showOTPField) ...[
                  TextFormField(
                    controller: otpController,
                    decoration: InputDecoration(
                      hintText: "Nhập mã xác nhận",
                      filled: true,
                      fillColor:
                          const Color(0xFFF3F3F3),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: verifyOTP,
                      child: const Text(
                        "Xác thực mã",
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "‹ Quay lại Đăng nhập",
                    style: TextStyle(
                      color: Color(0xFF0A7EA4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}