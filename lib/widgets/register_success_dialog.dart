import 'package:flutter/material.dart';

// Dialog thông báo đăng ký thành công khi người dùng đăng ký thành công
// Và chuyển hướng user đến màn hình login
Future<bool> showRegisterSuccessDialog(BuildContext context) async {
  final shouldGoToLogin = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Đăng ký thành công'),
      content: const Text(
        'Đã đăng ký tài khoản thành công! Hãy đăng nhập để tiến hành quản lý thu chi!',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Đóng'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Đăng nhập'),
        ),
      ],
    ),
  );

  return shouldGoToLogin == true;
}

Future<bool> showPasswordResetSuccessDialog(BuildContext context) async {
  final shouldGoToLogin = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Đặt lại mật khẩu thành công'),
      content: const Text(
        'Mật khẩu đã được đặt lại thành công! Hãy đăng nhập lại để tiếp tục sử dụng CoinNest.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Đóng'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Đăng nhập'),
        ),
      ],
    ),
  );

  return shouldGoToLogin == true;
}
